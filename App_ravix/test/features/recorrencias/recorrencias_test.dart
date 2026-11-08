import 'package:drift/drift.dart' show QueryRow;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ravix/app.dart';
import 'package:ravix/app/dependencias.dart';

import '../../helpers/app_de_teste.dart';

void main() {
  ProviderContainer containerDo(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(RavixApp)));

  Finder campo(String rotulo) => find.widgetWithText(TextField, rotulo);

  Future<void> tocar(WidgetTester tester, String texto) async {
    await tester.ensureVisible(find.text(texto).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(texto).last);
    await tester.pumpAndSettle();
  }

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

  Future<List<QueryRow>> linhas(WidgetTester tester, String sql) async =>
      (await tester.runAsync(
        () => containerDo(tester).read(bancoProvider).customSelect(sql).get(),
      ))!;

  /// Cria pelo formulário um aluguel recorrente de R$ 1.500,00 por Pix,
  /// no dia 24 de cada mês (o dia de hoje nos testes: 24/10/2026).
  Future<void> criarAluguel(WidgetTester tester) async {
    await tester.tap(find.text('Novo gasto'));
    await tester.pumpAndSettle();
    await tester.enterText(campo('Valor'), '150000');
    await tester.enterText(campo('Descrição'), 'Aluguel');
    await tester.pumpAndSettle();
    await tocar(tester, 'Pix');
    await tocar(tester, 'Cobrança recorrente');
    await escolher<int>(tester, 'Categoria', 'Moradia');
    await escolher<int>(tester, 'Subcategoria', 'Aluguel');
    await tocar(tester, 'Salvar gasto');
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  testarApp('gasto recorrente: este mês registrado, o próximo previsto', (
    tester,
  ) async {
    await montarApp(tester);
    await criarAluguel(tester);

    final gasto = (await linhas(
      tester,
      'SELECT ocorrencia, uuid_recorrencia IS NOT NULL AS ligado '
      'FROM tbl_compra_avista',
    )).single;
    expect(gasto.data, {'ocorrencia': '2026-10-24', 'ligado': 1});
    expect(find.text('PREVISTOS'), findsNothing);

    await tester.tap(find.byTooltip('Próximo mês'));
    await tester.pumpAndSettle();
    expect(find.text('PREVISTOS'), findsOneWidget);
    expect(
      find.text(r'Previsto para 24/11/2026 · R$ 1.500,00'),
      findsOneWidget,
    );
  });

  testarApp('registrar a prevista grava o gasto com o valor pago', (
    tester,
  ) async {
    await montarApp(tester);
    await criarAluguel(tester);
    await tester.tap(find.byTooltip('Próximo mês'));
    await tester.pumpAndSettle();

    await tocar(tester, 'Registrar');
    await tester.enterText(campo('Valor pago'), '151000');
    await tester.pumpAndSettle();
    await tocar(tester, 'Boleto');
    await tocar(tester, 'Registrar pagamento');

    expect(find.text('PREVISTOS'), findsNothing);
    final gastos = await linhas(
      tester,
      'SELECT valor_compra_avista, tipo_pagamento, ocorrencia '
      'FROM tbl_compra_avista ORDER BY ocorrencia',
    );
    expect(gastos.last.data, {
      'valor_compra_avista': 151000,
      'tipo_pagamento': 'boleto',
      'ocorrencia': '2026-11-24',
    });
  });

  testarApp('pular a prevista tira ela do mês', (tester) async {
    await montarApp(tester);
    await criarAluguel(tester);
    await tester.tap(find.byTooltip('Próximo mês'));
    await tester.pumpAndSettle();

    await tocar(tester, 'Registrar');
    await tocar(tester, 'Pular este mês');
    expect(find.text('PREVISTOS'), findsNothing);
    expect(
      await linhas(tester, 'SELECT * FROM tbl_recorrencia_excecao'),
      hasLength(1),
    );
  });

  testarApp('compra recorrente no cartão lança a cobrança de hoje', (
    tester,
  ) async {
    await montarApp(tester);
    await tester.runAsync(
      () => containerDo(tester).read(cartaoRepositoryProvider).criar((
        nome: 'Itaú',
        limiteCentavos: 590000,
        diaFechamento: 29,
        diaVencimento: 5,
        finalCartao: null,
        cnpjEmissor: null,
      )),
    );
    await tester.tap(find.text('Novo gasto'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Trocar o tipo de registro'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Compra no cartão').last);
    await tester.pumpAndSettle();

    await tester.enterText(campo('Valor total'), '5590');
    await tester.enterText(campo('Descrição'), 'Netflix');
    await tester.pumpAndSettle();
    await escolher<String>(tester, 'Cartão', 'Itaú');
    await tocar(tester, 'Cobrança recorrente');
    expect(campo('Parcelas'), findsNothing);
    await escolher<int>(tester, 'Categoria', 'Contas a pagar');
    await escolher<int>(tester, 'Subcategoria', 'Serviços online');
    await tocar(tester, 'Salvar compra');

    final compra = (await linhas(
      tester,
      'SELECT valor_total, ocorrencia, mes_vencimento FROM tbl_compra_faturada',
    )).single;
    expect(compra.data, {
      'valor_total': 5590,
      'ocorrencia': '2026-10-24',
      'mes_vencimento': 11,
    });
  });

  Future<void> abrirGasto(WidgetTester tester) async {
    await tester.tap(find.text('Aluguel').first);
    await tester.pumpAndSettle();
    expect(find.text('Editar gasto'), findsOneWidget);
  }

  testarApp('excluir só este pula o mês e mantém as próximas', (tester) async {
    await montarApp(tester);
    await criarAluguel(tester);
    await abrirGasto(tester);
    await tester.tap(find.byTooltip('Excluir gasto'));
    await tester.pumpAndSettle();
    await tocar(tester, 'Excluir só este');

    expect(await linhas(tester, 'SELECT * FROM tbl_compra_avista'), isEmpty);
    expect(find.text('PREVISTOS'), findsNothing);
    await tester.tap(find.byTooltip('Próximo mês'));
    await tester.pumpAndSettle();
    expect(find.text('PREVISTOS'), findsOneWidget);
  });

  testarApp('excluir este e os próximos encerra a recorrência', (tester) async {
    await montarApp(tester);
    await criarAluguel(tester);
    await abrirGasto(tester);
    await tester.tap(find.byTooltip('Excluir gasto'));
    await tester.pumpAndSettle();
    await tocar(tester, 'Excluir este e os próximos');

    expect(await linhas(tester, 'SELECT * FROM tbl_compra_avista'), isEmpty);
    await tester.tap(find.byTooltip('Próximo mês'));
    await tester.pumpAndSettle();
    expect(find.text('PREVISTOS'), findsNothing);
  });

  testarApp('alterar o valor deste e dos próximos', (tester) async {
    await montarApp(tester);
    await criarAluguel(tester);
    await abrirGasto(tester);
    await tester.enterText(campo('Valor'), '160000');
    await tester.pumpAndSettle();
    await tocar(tester, 'Salvar gasto');
    await tocar(tester, 'Alterar este e os próximos');

    await tester.tap(find.byTooltip('Próximo mês'));
    await tester.pumpAndSettle();
    expect(
      find.text(r'Previsto para 24/11/2026 · R$ 1.600,00'),
      findsOneWidget,
    );
  });

  testarApp('alterar só este não muda as próximas', (tester) async {
    await montarApp(tester);
    await criarAluguel(tester);
    await abrirGasto(tester);
    await tester.enterText(campo('Valor'), '160000');
    await tester.pumpAndSettle();
    await tocar(tester, 'Salvar gasto');
    await tocar(tester, 'Alterar só este');

    await tester.tap(find.byTooltip('Próximo mês'));
    await tester.pumpAndSettle();
    expect(
      find.text(r'Previsto para 24/11/2026 · R$ 1.500,00'),
      findsOneWidget,
    );
  });

  testarApp('gerenciar: pausar e retomar', (tester) async {
    await montarApp(tester);
    await criarAluguel(tester);
    await tester.tap(find.byTooltip('Configuração'));
    await tester.pumpAndSettle();
    await tocar(tester, 'Recorrências');
    expect(find.text('ATIVA'), findsOneWidget);
    expect(find.text(r'R$ 1.500,00 · dia 24 · Pix'), findsOneWidget);

    await tester.tap(find.byTooltip('Ações de Aluguel'));
    await tester.pumpAndSettle();
    await tocar(tester, 'Pausar');
    expect(find.text('PAUSADA'), findsOneWidget);

    await tester.tap(find.byTooltip('Ações de Aluguel'));
    await tester.pumpAndSettle();
    await tocar(tester, 'Retomar');
    expect(find.text('ATIVA'), findsOneWidget);
  });

  testarApp('gerenciar: editar daqui pra frente', (tester) async {
    await montarApp(tester);
    await criarAluguel(tester);
    await tester.tap(find.byTooltip('Configuração'));
    await tester.pumpAndSettle();
    await tocar(tester, 'Recorrências');
    await tester.tap(find.byTooltip('Ações de Aluguel'));
    await tester.pumpAndSettle();
    await tocar(tester, 'Editar');
    await tester.enterText(campo('Valor'), '170000');
    await tester.pumpAndSettle();
    await tocar(tester, 'Salvar');

    // A regra antiga fica até ontem; a nova vale a partir de hoje.
    expect(find.text('CANCELADA'), findsNothing);
    expect(find.textContaining(r'R$ 1.700,00 · dia 24 · Pix'), findsOneWidget);
  });
}
