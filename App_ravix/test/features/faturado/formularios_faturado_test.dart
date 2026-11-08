import 'package:drift/drift.dart' show QueryRow;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ravix/app.dart';
import 'package:ravix/app/dependencias.dart';
import 'package:ravix/data/banco.dart';

import '../../helpers/app_de_teste.dart';

void main() {
  ProviderContainer containerDo(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(RavixApp)));

  Finder campo(String rotulo) => find.widgetWithText(TextField, rotulo);

  /// Monta o app com o cartão Itaú (fecha 29, vence 5) e abre o novo
  /// registro já no tipo [tipo].
  Future<void> abrir(WidgetTester tester, String tipo) async {
    await montarApp(tester);
    final container = containerDo(tester);
    await tester.runAsync(
      () => container.read(cartaoRepositoryProvider).criar((
        nome: 'Itaú',
        limiteCentavos: 590000,
        diaFechamento: 29,
        diaVencimento: 5,
        finalCartao: '9827',
        cnpjEmissor: null,
      )),
    );
    await tester.tap(find.text('Novo gasto'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Trocar o tipo de registro'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(tipo).last);
    await tester.pumpAndSettle();
  }

  BancoRavix bancoDo(WidgetTester tester) =>
      containerDo(tester).read(bancoProvider);

  Future<void> escolher<T>(
    WidgetTester tester,
    String rotulo,
    String opcao,
  ) async {
    final menu = find.ancestor(
      of: find.text(rotulo),
      matching: find.byType(DropdownButtonFormField<T>),
    );
    await tester.ensureVisible(menu);
    await tester.tap(menu);
    await tester.pumpAndSettle();
    await tester.tap(find.text(opcao).last);
    await tester.pumpAndSettle();
  }

  Future<void> tocar(WidgetTester tester, String texto) async {
    await tester.ensureVisible(find.text(texto));
    await tester.pumpAndSettle();
    await tester.tap(find.text(texto));
    await tester.pumpAndSettle();
  }

  Future<List<QueryRow>> linhas(
    WidgetTester tester,
    BancoRavix banco,
    String sql,
  ) async => (await tester.runAsync(() => banco.customSelect(sql).get()))!;

  testarApp('compra parcelada no cartão grava as parcelas', (tester) async {
    await abrir(tester, 'Compra no cartão');
    final banco = bancoDo(tester);
    expect(find.text('Nova compra no cartão'), findsOneWidget);

    await tester.enterText(campo('Valor total'), '120000');
    await tester.enterText(campo('Descrição'), 'Passagem');
    await tester.pumpAndSettle();
    await escolher<String>(tester, 'Cartão', 'Itaú •••• 9827');
    // 24/10, antes do fechamento (29): fatura que vence em novembro.
    expect(find.text('Novembro de 2026'), findsOneWidget);
    await tester.enterText(campo('Parcelas'), '6');
    await tester.pumpAndSettle();
    expect(find.text('6x de R\$\u00a0200,00'), findsOneWidget);
    await escolher<int>(tester, 'Categoria', 'Lazer');
    await escolher<int>(tester, 'Subcategoria', 'Viagens e Turismo');
    await tocar(tester, 'Salvar compra');

    final compra = (await linhas(
      tester,
      banco,
      'SELECT valor_total, quant_parcela, mes_vencimento '
      'FROM tbl_compra_faturada',
    )).single;
    expect(compra.data, {
      'valor_total': 120000,
      'quant_parcela': 6,
      'mes_vencimento': 11,
    });
    final parcelas = await linhas(
      tester,
      banco,
      'SELECT mes_vencimento FROM tbl_parcela ORDER BY numero_parcela',
    );
    expect(parcelas.map((p) => p.read<int>('mes_vencimento')), [
      11,
      12,
      1,
      2,
      3,
      4,
    ]);
  });

  testarApp('compra sem cartão nem categoria mostra os erros', (tester) async {
    await abrir(tester, 'Compra no cartão');
    await tocar(tester, 'Salvar compra');
    expect(find.text('Informe um valor maior que zero.'), findsOneWidget);
    expect(find.text('Escolha o cartão.'), findsOneWidget);
    expect(find.text('Escolha a subcategoria.'), findsOneWidget);
  });

  testarApp('trocar o mês da fatura à mão', (tester) async {
    await abrir(tester, 'Compra no cartão');
    await escolher<String>(tester, 'Cartão', 'Itaú •••• 9827');
    await tester.ensureVisible(find.byTooltip('Fatura: próximo mês'));
    await tester.tap(find.byTooltip('Fatura: próximo mês'));
    await tester.pumpAndSettle();
    expect(find.text('Dezembro de 2026'), findsOneWidget);
    expect(find.text('Escolhida por você.'), findsOneWidget);
  });

  testarApp('pagamento de fatura sugere a fatura que vence', (tester) async {
    await abrir(tester, 'Pagamento de fatura');
    final banco = bancoDo(tester);
    await tester.enterText(campo('Valor pago'), '106383');
    await tester.pumpAndSettle();
    await tocar(tester, 'Boleto');
    await escolher<String>(tester, 'Cartão', 'Itaú •••• 9827');
    expect(find.text('Novembro de 2026'), findsOneWidget);
    await tocar(tester, 'Salvar pagamento');

    final pagamento = (await linhas(
      tester,
      banco,
      'SELECT valor_pagamento, tipo_pagamento, mes_vencimento '
      'FROM tbl_pagamento_fatura',
    )).single;
    expect(pagamento.data, {
      'valor_pagamento': 106383,
      'tipo_pagamento': 'boleto',
      'mes_vencimento': 11,
    });
  });

  testarApp('estorno grava a fatura e a categoria', (tester) async {
    await abrir(tester, 'Estorno');
    final banco = bancoDo(tester);
    await tester.enterText(campo('Valor estornado'), '5000');
    await tester.enterText(campo('Descrição'), 'Devolução');
    await tester.pumpAndSettle();
    await escolher<String>(tester, 'Cartão', 'Itaú •••• 9827');
    await escolher<int>(tester, 'Categoria', 'Compras e Bens');
    await escolher<int>(tester, 'Subcategoria', 'Vestuário');
    await tocar(tester, 'Salvar estorno');

    final estorno = (await linhas(
      tester,
      banco,
      'SELECT valor_estorno, id_subcategoria, mes_vencimento FROM tbl_estorno',
    )).single;
    expect(estorno.data, {
      'valor_estorno': 5000,
      'id_subcategoria': 504,
      'mes_vencimento': 11,
    });
  });

  testarApp('sem cartões, o campo oferece o cadastro', (tester) async {
    await montarApp(tester);
    await tester.tap(find.text('Novo gasto'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Trocar o tipo de registro'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Compra no cartão').last);
    await tester.pumpAndSettle();
    expect(find.text('Nenhum cartão cadastrado'), findsOneWidget);
    await tocar(tester, 'Cadastrar');
    expect(find.text('Novo cartão'), findsOneWidget);
  });
}
