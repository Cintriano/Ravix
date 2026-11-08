import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ravix/core/datas.dart';
import 'package:ravix/data/cartao_repository.dart';
import 'package:ravix/data/faturado_repository.dart';

import '../../helpers/ambiente_falso.dart';
import '../../helpers/app_de_teste.dart';
import '../../helpers/banco_de_teste.dart';

void main() {
  Future<void> abrirAba(WidgetTester tester) => irParaAba(tester, 'Faturada');

  /// Cria o Itaú (fecha 29, vence 5) e o Nubank, com uma geladeira em 6x
  /// no Itaú a partir da fatura de outubro e um livro no Nubank, mais o que
  /// [extra] gravar, e monta o app sobre esse banco.
  ///
  /// Grava antes de montar: com as abas observando o banco no relógio falso
  /// do teste, uma transação gravada depois pode não terminar.
  Future<({String itau, String nubank, String geladeira})> semear(
    WidgetTester tester, {
    Future<void> Function(
      FaturadoRepository faturado,
      ({String itau, String nubank, String geladeira}) ids,
    )?
    extra,
  }) async {
    final banco = bancoEmMemoria();
    addTearDown(banco.close);
    final relogio = RelogioFixo(agoraDosTestes);
    final uuid = GeradorUuidSequencial();
    final cartoes = CartaoRepository(banco, relogio: relogio, uuid: uuid);
    final faturado = FaturadoRepository(
      banco,
      relogio: relogio,
      uuid: uuid,
      fuso: FusoFixo(-180),
    );
    final ids = (await tester.runAsync(() async {
      final itau = (await cartoes.criar((
        nome: 'Itaú',
        limiteCentavos: 590000,
        diaFechamento: 29,
        diaVencimento: 5,
        finalCartao: '9827',
        cnpjEmissor: null,
      ))).uuidCartaoCredito;
      final nubank = (await cartoes.criar((
        nome: 'Nubank',
        limiteCentavos: 100000,
        diaFechamento: null,
        diaVencimento: null,
        finalCartao: null,
        cnpjEmissor: null,
      ))).uuidCartaoCredito;
      final geladeira = await faturado.criarCompra((
        momento: DateTime(2026, 9, 20, 10),
        descricao: 'Geladeira',
        valorTotalCentavos: 120000,
        parcelas: 6,
        uuidCartao: itau,
        vencimento: Mes(2026, 10),
        idSubcategoria: 506,
        uuidTag: null,
      ));
      await faturado.criarCompra((
        momento: DateTime(2026, 9, 22, 10),
        descricao: 'Livro',
        valorTotalCentavos: 5000,
        parcelas: 1,
        uuidCartao: nubank,
        vencimento: Mes(2026, 10),
        idSubcategoria: 506,
        uuidTag: null,
      ));
      final ids = (itau: itau, nubank: nubank, geladeira: geladeira);
      await extra?.call(faturado, ids);
      return ids;
    }))!;
    await montarApp(tester, banco: banco);
    return ids;
  }

  testarApp('sem cartões, a aba oferece o cadastro', (tester) async {
    await montarApp(tester);
    await abrirAba(tester);
    expect(find.text('Nenhum cartão cadastrado'), findsOneWidget);
    await tester.tap(find.text('Cadastrar cartão'));
    await tester.pumpAndSettle();
    expect(find.text('Novo cartão'), findsOneWidget);
  });

  testarApp('mostra as faturas, o limite e as parcelas', (tester) async {
    await semear(tester);
    await abrirAba(tester);

    expect(find.text('Faturas de outubro'), findsOneWidget);
    // 200,00 (1ª parcela da geladeira) + 50,00 do livro.
    expect(find.text(r'R$ 250,00'), findsOneWidget);
    expect(find.text('Itaú •••• 9827'), findsOneWidget);
    expect(find.text('Vence em 05/10/2026, sem pagamento'), findsNothing);
    expect(find.text('Vence em 05/10/2026'), findsNothing);
    // Hoje é 24/10: a fatura de outubro do Itaú venceu dia 5.
    expect(find.text('Venceu em 05/10/2026, sem pagamento'), findsOneWidget);
    expect(
      find.text(r'R$ 1.200,00 de R$ 5.900,00 do limite (20%)'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(find.textContaining('1/6'), 200);
    expect(find.textContaining('1/6'), findsOneWidget);
  });

  testarApp('pagamento marca a fatura como paga e libera o limite', (
    tester,
  ) async {
    await semear(
      tester,
      extra: (faturado, s) => faturado.criarPagamento((
        momento: DateTime(2026, 10, 5, 9),
        valorCentavos: 20000,
        forma: FormaPagamentoFatura.pix,
        uuidCartao: s.itau,
        fatura: Mes(2026, 10),
      )),
    );
    await abrirAba(tester);

    expect(find.text('Paga em 05/10/2026'), findsOneWidget);
    expect(
      find.text(r'R$ 1.000,00 de R$ 5.900,00 do limite (17%)'),
      findsOneWidget,
    );
    expect(find.text('PAGAMENTOS'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Pagamento Itaú'), 200);
    await tester.tap(find.text('Pagamento Itaú'));
    await tester.pumpAndSettle();
    expect(find.text('Editar pagamento de fatura'), findsOneWidget);
  });

  testarApp('estorno aparece como crédito e abate a fatura', (tester) async {
    await semear(
      tester,
      extra: (faturado, s) => faturado.criarEstorno((
        momento: DateTime(2026, 9, 30),
        descricao: 'Devolução',
        valorCentavos: 5000,
        uuidCartao: s.nubank,
        fatura: Mes(2026, 10),
        idSubcategoria: 506,
        uuidTag: null,
        uuidCompraOriginal: null,
      )),
    );
    await abrirAba(tester);
    expect(find.text(r'R$ 200,00'), findsWidgets);
    await tester.scrollUntilVisible(find.text('Devolução'), 200);
    expect(find.text(r'− R$ 50,00'), findsOneWidget);
    // Sobe mais um pouco, para o botão flutuante não cobrir a linha.
    await tester.drag(
      find.byType(CustomScrollView).hitTestable().first,
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Devolução'));
    await tester.pumpAndSettle();
    expect(find.text('Editar estorno'), findsOneWidget);
  });

  testarApp('tocar no cartão mostra só os lançamentos dele', (tester) async {
    await semear(tester);
    await abrirAba(tester);
    await tester.scrollUntilVisible(find.text('Livro'), 200);
    expect(find.text('Livro'), findsOneWidget);

    await tester.tap(find.text('Itaú •••• 9827'));
    await tester.pumpAndSettle();
    expect(find.text('Livro'), findsNothing);
    await tester.scrollUntilVisible(find.text('Geladeira'), 200);
    expect(find.text('Geladeira'), findsOneWidget);

    await tester.tap(find.byTooltip('Mostrar todos os cartões').first);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Livro'), 200);
    expect(find.text('Livro'), findsOneWidget);
  });

  testarApp('tocar na parcela abre a edição da compra', (tester) async {
    await semear(tester);
    await abrirAba(tester);
    await tester.scrollUntilVisible(find.text('Geladeira'), 200);
    await tester.tap(find.text('Geladeira'));
    await tester.pumpAndSettle();
    expect(find.text('Editar compra no cartão'), findsOneWidget);
  });

  testarApp('o botão flutuante da aba abre a compra no cartão', (tester) async {
    await montarApp(tester);
    await abrirAba(tester);
    await tester.tap(find.text('Nova compra'));
    await tester.pumpAndSettle();
    expect(find.text('Nova compra no cartão'), findsOneWidget);
  });

  testarApp('tocar num mês da linha do tempo vai para ele', (tester) async {
    await semear(tester);
    await abrirAba(tester);
    await tester.tap(find.bySemanticsLabel(RegExp('^novembro de 2026: ')));
    await tester.pumpAndSettle();
    expect(find.text('Faturas de novembro'), findsOneWidget);
  });
}
