import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ravix/core/valor.dart';
import 'package:ravix/data/compra_avista_repository.dart';
import 'package:ravix/data/tag_repository.dart';
import 'package:ravix/features/compra_avista/aba_avista.dart';

import '../../helpers/ambiente_falso.dart';
import '../../helpers/app_de_teste.dart';
import '../../helpers/banco_de_teste.dart';

void main() {
  /// Outubro: 1,00 + 2,00 + 4,00 + 8,00 = 15,00. Setembro: 16,00.
  /// "Viagem" marca o Restaurante da viagem e o Uber; "Mudança" está
  /// arquivada.
  Future<void> abrirComGastos(WidgetTester tester) async {
    final banco = bancoEmMemoria();
    addTearDown(banco.close);
    final relogio = RelogioFixo(agoraDosTestes);
    final uuids = GeradorUuidSequencial();
    await tester.runAsync(() async {
      final tags = TagRepository(banco, relogio: relogio, uuid: uuids);
      final compras = CompraAvistaRepository(
        banco,
        relogio: relogio,
        uuid: uuids,
        fuso: FusoFixo(-180),
      );
      final viagem = (await tags.criar('Viagem')).uuidTag;
      final mudanca = (await tags.criar('Mudança')).uuidTag;
      final dia10 = DateTime(2026, 10, 10, 9);
      await compras.criar(
        gasto(momento: dia10, descricao: 'Padaria', valorCentavos: 100),
      );
      await compras.criar(
        gasto(
          momento: dia10.add(const Duration(hours: 3)),
          descricao: 'Restaurante',
          idSubcategoria: 103,
          valorCentavos: 200,
          tipoPagamento: TipoPagamento.debito,
        ),
      );
      await compras.criar(
        gasto(
          momento: dia10.add(const Duration(hours: 10)),
          descricao: 'Restaurante da viagem',
          idSubcategoria: 103,
          valorCentavos: 400,
          uuidTag: viagem,
        ),
      );
      await compras.criar(
        gasto(
          momento: DateTime(2026, 10, 12, 18),
          descricao: 'Uber',
          idSubcategoria: 302,
          valorCentavos: 800,
          uuidTag: viagem,
        ),
      );
      await compras.criar(
        gasto(
          momento: DateTime(2026, 9, 30, 23, 59),
          descricao: 'Mercado',
          idSubcategoria: 102,
          valorCentavos: 1600,
          uuidTag: mudanca,
        ),
      );
      await tags.remover(mudanca);
    });
    await montarApp(tester, banco: banco);
  }

  Future<void> filtrar(WidgetTester tester, String chip, String opcao) async {
    await tester.tap(find.text(chip));
    await tester.pumpAndSettle();
    // A folha só constrói as opções que cabem na tela de teste.
    final folha = find.byType(BottomSheet);
    final item = find.descendant(of: folha, matching: find.text(opcao));
    await tester.scrollUntilVisible(
      item,
      100,
      scrollable: find
          .descendant(of: folha, matching: find.byType(Scrollable))
          .first,
    );
    await tester.ensureVisible(item);
    await tester.pumpAndSettle();
    await tester.tap(item);
    await tester.pumpAndSettle();
  }

  List<String> descricoesNaTela(WidgetTester tester) => tester
      .widgetList<ListTile>(find.byType(ListTile))
      .map((t) => (t.title! as Text).data!)
      .toList();

  testarApp('mostra o total e os gastos do mês, por dia', (tester) async {
    await abrirComGastos(tester);

    expect(find.text('Total à vista em outubro'), findsOneWidget);
    expect(find.text(formatarCentavos(1500)), findsOneWidget);
    expect(descricoesNaTela(tester), [
      'Uber',
      'Restaurante da viagem',
      'Restaurante',
      'Padaria',
    ]);
    expect(find.text('Segunda, 12 de outubro'), findsOneWidget);
    expect(find.text('Sábado, 10 de outubro'), findsOneWidget);
    expect(find.text('Mobilidade Urbana · 18:00 · Viagem'), findsOneWidget);
    expect(find.text(formatarCentavos(800)), findsOneWidget);
  });

  testarApp('filtros afetam só a tabela, nunca o total', (tester) async {
    await abrirComGastos(tester);

    await filtrar(tester, 'Categoria', 'Alimentação');
    expect(descricoesNaTela(tester), [
      'Restaurante da viagem',
      'Restaurante',
      'Padaria',
    ]);
    expect(find.text(formatarCentavos(1500)), findsOneWidget);

    await filtrar(tester, 'Subcategoria', 'Refeição');
    expect(descricoesNaTela(tester), ['Restaurante da viagem', 'Restaurante']);

    await filtrar(tester, 'Tag', 'Viagem');
    expect(descricoesNaTela(tester), ['Restaurante da viagem']);
    expect(find.text(formatarCentavos(1500)), findsOneWidget);

    await tester.tap(find.text('Limpar'));
    await tester.pumpAndSettle();
    expect(descricoesNaTela(tester), hasLength(4));
  });

  testarApp('filtro de tag isolado', (tester) async {
    await abrirComGastos(tester);
    await filtrar(tester, 'Tag', 'Viagem');
    expect(descricoesNaTela(tester), ['Uber', 'Restaurante da viagem']);
  });

  testarApp('"Todas" tira o filtro e trocar a categoria limpa a '
      'subcategoria', (tester) async {
    await abrirComGastos(tester);
    await filtrar(tester, 'Categoria', 'Alimentação');
    await filtrar(tester, 'Subcategoria', 'Padaria');
    expect(descricoesNaTela(tester), ['Padaria']);

    await filtrar(tester, 'Alimentação', 'Transporte');
    expect(descricoesNaTela(tester), ['Uber']);
    expect(find.text('Subcategoria'), findsOneWidget);

    await filtrar(tester, 'Transporte', 'Todas');
    expect(descricoesNaTela(tester), hasLength(4));
    expect(find.text('Subcategoria'), findsNothing);
  });

  testarApp('filtro sem resultado oferece limpar', (tester) async {
    await abrirComGastos(tester);
    await filtrar(tester, 'Categoria', 'Moradia');

    expect(find.text('Nada com esses filtros'), findsOneWidget);
    await tester.tap(find.text('Limpar filtros'));
    await tester.pumpAndSettle();
    expect(descricoesNaTela(tester), hasLength(4));
  });

  testarApp('a tag arquivada aparece no filtro e alcança gastos antigos', (
    tester,
  ) async {
    await abrirComGastos(tester);
    await tester.tap(find.byTooltip('Mês anterior'));
    await tester.pumpAndSettle();
    await filtrar(tester, 'Tag', 'Mudança (arquivada)');
    expect(descricoesNaTela(tester), ['Mercado']);
  });

  testarApp('trocar o mês atualiza total e tabela', (tester) async {
    await abrirComGastos(tester);

    await tester.tap(find.byTooltip('Mês anterior'));
    await tester.pumpAndSettle();
    expect(find.text('Total à vista em setembro'), findsOneWidget);
    // Um gasto só: o total e a linha mostram o mesmo valor.
    expect(find.text(formatarCentavos(1600)), findsNWidgets(2));
    expect(descricoesNaTela(tester), ['Mercado']);

    await tester.tap(find.byTooltip('Próximo mês'));
    await tester.tap(find.byTooltip('Próximo mês'));
    await tester.pumpAndSettle();
    expect(find.text('Nenhum gasto em novembro'), findsOneWidget);
    expect(find.text(formatarCentavos(0)), findsOneWidget);
  });

  testarApp('tocar num gasto abre a edição', (tester) async {
    await abrirComGastos(tester);
    await tester.tap(find.text('Uber'));
    await tester.pumpAndSettle();
    expect(find.text('Editar gasto'), findsOneWidget);
    expect(find.text('8,00'), findsOneWidget);
  });

  testarApp('salvar no formulário atualiza a aba sozinha', (tester) async {
    await abrirComGastos(tester);
    await tester.tap(find.text('Uber'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Valor'), '1000');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Gasto atualizado.'), findsOneWidget);
    expect(find.text(formatarCentavos(1000)), findsOneWidget);
    expect(find.text(formatarCentavos(1700)), findsOneWidget);
  });

  testarApp('excluir no formulário tira o gasto da aba', (tester) async {
    await abrirComGastos(tester);
    await tester.tap(find.text('Padaria'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Excluir gasto'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();

    expect(descricoesNaTela(tester), hasLength(3));
    expect(find.text(formatarCentavos(1400)), findsOneWidget);
  });

  testarApp('mês sem gastos mostra o estado vazio', (tester) async {
    await montarApp(tester);
    expect(find.text('Nenhum gasto em outubro'), findsOneWidget);
    expect(find.text(formatarCentavos(0)), findsOneWidget);
  });

  test('ícone de cada forma de pagamento é diferente', () {
    expect(
      TipoPagamento.values.map(iconeDoPagamento).toSet(),
      hasLength(TipoPagamento.values.length),
    );
  });
}
