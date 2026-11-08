import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ravix/core/datas.dart';
import 'package:ravix/core/valor.dart';
import 'package:ravix/data/cartao_repository.dart';
import 'package:ravix/data/compra_avista_repository.dart';
import 'package:ravix/data/faturado_repository.dart';
import 'package:ravix/data/renda_repository.dart';

import '../../helpers/ambiente_falso.dart';
import '../../helpers/app_de_teste.dart';
import '../../helpers/banco_de_teste.dart';

void main() {
  /// Hoje é 24/10/2026. Outubro: R$ 1.000 no Pix, R$ 300 no voucher e a
  /// 1ª parcela (R$ 200) de uma compra no Itaú, que venceu dia 5.
  /// Com [comRenda], salário R$ 5.000 e voucher R$ 1.000 desde janeiro.
  Future<void> abrir(WidgetTester tester, {bool comRenda = true}) async {
    final banco = bancoEmMemoria();
    addTearDown(banco.close);
    final relogio = RelogioFixo(agoraDosTestes);
    final uuid = GeradorUuidSequencial();
    final fuso = FusoFixo(-180);
    await tester.runAsync(() async {
      if (comRenda) {
        await RendaRepository(banco, relogio: relogio, uuid: uuid).definir(
          salarioCentavos: 500000,
          voucherCentavos: 100000,
          aPartirDe: Mes(2026, 1),
        );
      }
      final compras = CompraAvistaRepository(
        banco,
        relogio: relogio,
        uuid: uuid,
        fuso: fuso,
      );
      await compras.criar(
        gasto(momento: DateTime(2026, 10, 3, 12), valorCentavos: 100000),
      );
      await compras.criar(
        gasto(
          momento: DateTime(2026, 10, 4, 12),
          valorCentavos: 30000,
          tipoPagamento: TipoPagamento.voucher,
        ),
      );
      final itau =
          (await CartaoRepository(banco, relogio: relogio, uuid: uuid).criar((
            nome: 'Itaú',
            limiteCentavos: 590000,
            diaFechamento: 29,
            diaVencimento: 5,
            finalCartao: null,
            cnpjEmissor: null,
          ))).uuidCartaoCredito;
      await FaturadoRepository(
        banco,
        relogio: relogio,
        uuid: uuid,
        fuso: fuso,
      ).criarCompra((
        momento: DateTime(2026, 9, 20, 10),
        descricao: 'Geladeira',
        valorTotalCentavos: 120000,
        parcelas: 6,
        uuidCartao: itau,
        vencimento: Mes(2026, 10),
        idSubcategoria: 502,
        uuidTag: null,
      ));
    });
    await montarApp(tester, banco: banco, aba: null);
  }

  testarApp('abre na Macro com consumo, farol e sobra', (tester) async {
    await abrir(tester);

    expect(find.text('Consumo de outubro até agora'), findsOneWidget);
    expect(find.text(formatarCentavos(150000)), findsOneWidget);
    expect(find.text('25% da renda total'), findsOneWidget);
    // Dia 24 de 31: ritmo de 77%.
    expect(find.text('No ritmo do mês · ritmo 77%'), findsOneWidget);
    expect(find.text('Sobram ${formatarCentavos(450000)}'), findsOneWidget);
    expect(find.text('Voucher'), findsOneWidget);
  });

  testarApp('só salário tira o voucher do consumo e da base', (tester) async {
    await abrir(tester);
    await tester.tap(find.text('Só salário'));
    await tester.pumpAndSettle();

    expect(find.text(formatarCentavos(120000)), findsWidgets);
    expect(find.text('24% do salário'), findsOneWidget);
    expect(find.text('Sobram ${formatarCentavos(380000)}'), findsOneWidget);
    expect(
      find.text('O voucher fica fora do consumo na base só salário.'),
      findsOneWidget,
    );
  });

  testarApp('sem renda, oferece o cadastro', (tester) async {
    await abrir(tester, comRenda: false);
    expect(find.text(formatarCentavos(150000)), findsOneWidget);
    expect(find.textContaining('% da renda'), findsNothing);
    await tester.tap(find.text('Cadastrar renda'));
    await tester.pumpAndSettle();
    expect(find.text('Renda'), findsWidgets);
  });

  testarApp('mês futuro mostra só o comprometido', (tester) async {
    await abrir(tester);
    await tester.tap(find.byTooltip('Próximo mês'));
    await tester.pumpAndSettle();

    expect(find.text('Já comprometido em novembro'), findsOneWidget);
    expect(find.text(formatarCentavos(20000)), findsWidgets);
    expect(find.textContaining('ritmo'), findsNothing);
    expect(find.text('CONSUMO DIA A DIA'), findsNothing);
  });

  testarApp('mês fechado mostra o superávit', (tester) async {
    await abrir(tester);
    await tester.tap(find.byTooltip('Mês anterior'));
    await tester.pumpAndSettle();

    expect(find.text('Consumo de setembro'), findsOneWidget);
    expect(find.text('Dentro da renda'), findsOneWidget);
    expect(
      find.text('Superávit de ${formatarCentavos(600000)}'),
      findsOneWidget,
    );
  });

  testarApp('o botão flutuante da Macro pergunta o tipo', (tester) async {
    await abrir(tester);
    await tester.tap(find.text('Novo registro'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Estorno'));
    await tester.pumpAndSettle();
    expect(find.text('Novo estorno'), findsOneWidget);
  });
}
