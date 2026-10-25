import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ravix/app.dart';
import 'package:ravix/app/dependencias.dart';
import 'package:ravix/app/rotas.dart';
import 'package:ravix/core/datas.dart';
import 'package:ravix/data/banco.dart';
import 'package:ravix/data/compra_avista_repository.dart';
import 'package:ravix/features/compra_avista/formulario_compra.dart';
import 'package:ravix/features/compra_avista/formulario_providers.dart';

import '../../helpers/app_de_teste.dart';
import '../../helpers/banco_de_teste.dart';

/// Sugestão falsa que anota cada consulta.
final class SugestaoEspia {
  new([this.resposta]);

  final int? resposta;
  final consultas = <String>[];

  Future<int?> call(String texto) async {
    consultas.add(texto);
    return resposta;
  }
}

void main() {
  final outubro = Mes(2026, 10);

  ProviderContainer containerDo(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(RavixApp)));

  Future<ProviderContainer> abrirFormulario(
    WidgetTester tester, {
    SugestaoEspia? sugestao,
  }) async {
    await montarApp(
      tester,
      extras: [
        if (sugestao != null)
          sugestaoDeSubcategoriaProvider.overrideWithValue(sugestao.call),
      ],
    );
    await tester.tap(find.text('Novo gasto'));
    await tester.pumpAndSettle();
    return containerDo(tester);
  }

  Finder campo(String rotulo) => find.widgetWithText(TextField, rotulo);

  Future<void> escolherNoMenu(
    WidgetTester tester,
    String rotulo,
    String opcao,
  ) async {
    final menu = find.ancestor(
      of: find.text(rotulo),
      matching: find.byType(DropdownButtonFormField<int>),
    );
    await tester.ensureVisible(menu);
    await tester.tap(menu);
    await tester.pumpAndSettle();
    await tester.tap(find.text(opcao).last);
    await tester.pumpAndSettle();
  }

  Future<void> preencher(
    WidgetTester tester, {
    String? descricao = 'Padaria do Zé',
    String? valor = '1250',
    String? pagamento = 'Pix',
    bool categoria = true,
  }) async {
    if (descricao != null) {
      await tester.enterText(campo('Descrição'), descricao);
    }
    if (valor != null) await tester.enterText(campo('Valor'), valor);
    if (pagamento != null) {
      await tester.ensureVisible(find.text(pagamento));
      await tester.tap(find.text(pagamento));
    }
    // Digitar rola a lista até o campo; durante a rolagem, toques são
    // ignorados.
    await tester.pumpAndSettle();
    if (categoria) {
      await escolherNoMenu(tester, 'Categoria', 'Alimentação');
      await escolherNoMenu(tester, 'Subcategoria', 'Padaria');
    }
  }

  Future<void> salvar(WidgetTester tester) async {
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
  }

  Future<List<CompraDoMes>> gastosDe(WidgetTester tester, Mes mes) async =>
      (await tester.runAsync(
        () =>
            containerDo(tester)
                .read(compraAvistaRepositoryProvider)
                .observarMes(mes)
                .first,
      ))!;

  group('validação', () {
    testWidgets('salvar vazio mostra todos os avisos e não grava', (
      tester,
    ) async {
      await abrirFormulario(tester);
      await salvar(tester);

      expect(find.text('Informe a descrição.'), findsOneWidget);
      expect(find.text('Informe um valor maior que zero.'), findsOneWidget);
      expect(find.text('Escolha a forma de pagamento.'), findsOneWidget);
      expect(find.text('Escolha a categoria.'), findsOneWidget);
      expect(find.text('Escolha a subcategoria.'), findsOneWidget);
      expect(await gastosDe(tester, outubro), isEmpty);
      await encerrarApp(tester);
    });

    testWidgets('cada campo vazio bloqueia o salvar', (tester) async {
      for (final (faltando, aviso) in [
        ('descricao', 'Informe a descrição.'),
        ('valor', 'Informe um valor maior que zero.'),
        ('pagamento', 'Escolha a forma de pagamento.'),
        ('categoria', 'Escolha a categoria.'),
      ]) {
        await abrirFormulario(tester);
        await preencher(
          tester,
          descricao: faltando == 'descricao' ? null : 'Padaria',
          valor: faltando == 'valor' ? null : '1250',
          pagamento: faltando == 'pagamento' ? null : 'Pix',
          categoria: faltando != 'categoria',
        );
        await salvar(tester);
        expect(find.text(aviso), findsOneWidget, reason: faltando);
        expect(find.text('Salvar'), findsOneWidget, reason: faltando);
        expect(await gastosDe(tester, outubro), isEmpty, reason: faltando);
        await encerrarApp(tester);
      }
    });

    testWidgets('o aviso some ao corrigir o campo', (tester) async {
      await abrirFormulario(tester);
      await salvar(tester);
      await tester.enterText(campo('Descrição'), 'Padaria');
      await tester.pump();
      expect(find.text('Informe a descrição.'), findsNothing);
      expect(find.text('Informe um valor maior que zero.'), findsOneWidget);
      await encerrarApp(tester);
    });

    testWidgets('o valor rejeita letras e usa a máscara', (tester) async {
      await abrirFormulario(tester);
      await tester.enterText(campo('Valor'), 'abc');
      await tester.pump();
      expect(tester.widget<TextField>(campo('Valor')).controller!.text, '');

      await tester.enterText(campo('Valor'), '1250');
      await tester.pump();
      expect(find.text('12,50'), findsOneWidget);
      await encerrarApp(tester);
    });
  });

  group('salvar', () {
    testWidgets('grava os campos calculados e volta ao shell', (tester) async {
      await abrirFormulario(tester);
      expect(find.text('24/10/2026'), findsOneWidget);
      expect(find.text('15:00'), findsOneWidget);
      await preencher(tester, descricao: '  Açaí do Parque ');
      await salvar(tester);

      expect(find.text('Gasto salvo.'), findsOneWidget);
      expect(find.text('Outubro de 2026'), findsOneWidget);

      final gasto = (await gastosDe(tester, outubro)).single.c;
      expect(gasto.descricao, 'Açaí do Parque');
      expect(gasto.descricaoNormalizada, 'acai do parque');
      expect(gasto.valorCompraAvista, 1250);
      expect(gasto.tipoPagamento, 'pix');
      expect(gasto.idSubcategoria, 101);
      expect(gasto.timestampCompraAvista, '2026-10-24T15:00:00');
      expect(gasto.fusoMinutos, -180);
      expect(gasto.criadoEm, endsWith('Z'));
      expect(gasto.uuidTag, isNull);
      await encerrarApp(tester);
    });

    testWidgets('aceita data futura escolhida no calendário', (tester) async {
      await abrirFormulario(tester);
      await preencher(tester);
      await tester.ensureVisible(find.text('24/10/2026'));
      await tester.tap(find.text('24/10/2026'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('30'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('30/10/2026'), findsOneWidget);

      await salvar(tester);
      final gasto = (await gastosDe(tester, outubro)).single.c;
      expect(gasto.timestampCompraAvista, '2026-10-30T15:00:00');
      await encerrarApp(tester);
    });

    testWidgets('troca a hora pelo relógio', (tester) async {
      await abrirFormulario(tester);
      await tester.ensureVisible(find.text('15:00'));
      await tester.tap(find.text('15:00'));
      await tester.pumpAndSettle();
      expect(find.text('Hora do gasto'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.text('15:00'), findsOneWidget);
      await encerrarApp(tester);
    });

    testWidgets('tag criada no formulário já fica selecionada', (tester) async {
      await abrirFormulario(tester);
      await preencher(tester);
      await tester.ensureVisible(find.text('Nova tag'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nova tag'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Viagem');
      await tester.tap(find.widgetWithText(FilledButton, 'Criar'));
      await tester.pumpAndSettle();

      expect(find.text('Viagem'), findsOneWidget);
      await salvar(tester);
      final linha = (await gastosDe(tester, outubro)).single;
      expect(linha.tag, 'Viagem');
      await encerrarApp(tester);
    });
  });

  group('sugestão pela descrição', () {
    testWidgets('espera 3 caracteres e 300 ms antes de consultar', (
      tester,
    ) async {
      final espia = SugestaoEspia(302);
      await abrirFormulario(tester, sugestao: espia);

      await tester.enterText(campo('Descrição'), 'ub');
      await tester.pump(const Duration(seconds: 1));
      expect(espia.consultas, isEmpty);

      await tester.enterText(campo('Descrição'), 'ube');
      await tester.pump(esperaDaSugestao - const Duration(milliseconds: 1));
      expect(espia.consultas, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      expect(espia.consultas, ['ube']);
      await tester.pumpAndSettle();

      expect(find.text('Transporte'), findsOneWidget);
      expect(find.text('Mobilidade Urbana'), findsOneWidget);
      expect(find.text('Sugerida pelo histórico'), findsOneWidget);
      await encerrarApp(tester);
    });

    testWidgets('cada tecla reinicia a espera', (tester) async {
      final espia = SugestaoEspia(302);
      await abrirFormulario(tester, sugestao: espia);

      await tester.enterText(campo('Descrição'), 'uber');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.enterText(campo('Descrição'), 'uber c');
      await tester.pump(const Duration(milliseconds: 200));
      expect(espia.consultas, isEmpty);
      await tester.pump(const Duration(milliseconds: 100));
      expect(espia.consultas, ['uber c']);
      await encerrarApp(tester);
    });

    testWidgets('sem histórico não preenche nada', (tester) async {
      final espia = SugestaoEspia();
      await abrirFormulario(tester, sugestao: espia);
      await tester.enterText(campo('Descrição'), 'novidade');
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      expect(espia.consultas, ['novidade']);
      expect(find.text('Sugerida pelo histórico'), findsNothing);
      await encerrarApp(tester);
    });

    testWidgets('não sobrescreve a escolha manual', (tester) async {
      final espia = SugestaoEspia(302);
      await abrirFormulario(tester, sugestao: espia);
      await escolherNoMenu(tester, 'Categoria', 'Alimentação');

      await tester.enterText(campo('Descrição'), 'uber');
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      expect(espia.consultas, isEmpty);
      expect(find.text('Alimentação'), findsOneWidget);
      expect(find.text('Transporte'), findsNothing);
      await encerrarApp(tester);
    });

    testWidgets('usa o histórico real do banco', (tester) async {
      await abrirFormulario(tester);
      await tester.runAsync(
        () =>
            containerDo(tester)
                .read(compraAvistaRepositoryProvider)
                .criar(gasto(descricao: 'Uber Centro', idSubcategoria: 302)),
      );
      await tester.enterText(campo('Descrição'), 'uber');
      await tester.pump(esperaDaSugestao);
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(find.text('Mobilidade Urbana'), findsOneWidget);
      await encerrarApp(tester);
    });
  });

  group('editar e excluir', () {
    Future<String> criarEAbrir(
      WidgetTester tester, {
      String? uuidTag,
      bool arquivarTag = false,
    }) async {
      await montarApp(tester);
      final container = containerDo(tester);
      final uuid = (await tester.runAsync(() async {
        var tag = uuidTag;
        if (tag == 'nova') {
          tag = (await container.read(tagRepositoryProvider).criar('Viagem'))
              .uuidTag;
        }
        final id = await container
            .read(compraAvistaRepositoryProvider)
            .criar(gasto(uuidTag: tag));
        if (arquivarTag) {
          await container.read(tagRepositoryProvider).remover(tag!);
        }
        return id;
      }))!;
      unawaited(container.read(rotasProvider).push('/registro/$uuid'));
      await tester.pumpAndSettle();
      return uuid;
    }

    testWidgets('carrega os valores salvos e atualiza', (tester) async {
      final uuid = await criarEAbrir(tester);

      expect(find.text('Editar gasto'), findsOneWidget);
      expect(find.text('Padaria do Zé'), findsOneWidget);
      expect(find.text('12,50'), findsOneWidget);
      expect(find.text('15/10/2026'), findsOneWidget);
      expect(find.text('08:30'), findsOneWidget);
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Pix'))
            .selected,
        isTrue,
      );
      expect(find.text('Alimentação'), findsOneWidget);
      expect(find.text('Padaria'), findsOneWidget);

      await tester.enterText(campo('Valor'), '999');
      await salvar(tester);
      expect(find.text('Gasto atualizado.'), findsOneWidget);

      final salvo = await tester.runAsync(
        () =>
            containerDo(tester)
                .read(compraAvistaRepositoryProvider)
                .buscar(uuid),
      );
      expect(salvo!.valorCompraAvista, 999);
      expect(salvo.descricao, 'Padaria do Zé');
      await encerrarApp(tester);
    });

    testWidgets('excluir só depois de confirmar', (tester) async {
      final uuid = await criarEAbrir(tester);
      final repositorio = containerDo(tester)
          .read(compraAvistaRepositoryProvider);

      await tester.tap(find.byTooltip('Excluir gasto'));
      await tester.pumpAndSettle();
      expect(find.text('Excluir este gasto?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(await tester.runAsync(() => repositorio.buscar(uuid)), isNotNull);

      await tester.tap(find.byTooltip('Excluir gasto'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
      await tester.pumpAndSettle();
      expect(find.text('Gasto excluído.'), findsOneWidget);
      expect(find.text('Outubro de 2026'), findsOneWidget);
      expect(await tester.runAsync(() => repositorio.buscar(uuid)), isNull);
      await encerrarApp(tester);
    });

    testWidgets('mostra a tag arquivada de um gasto antigo', (tester) async {
      await criarEAbrir(tester, uuidTag: 'nova', arquivarTag: true);
      await tester.pumpAndSettle();
      expect(find.text('Viagem (arquivada)'), findsOneWidget);
      await encerrarApp(tester);
    });

    testWidgets('gasto inexistente mostra o erro', (tester) async {
      await montarApp(tester);
      unawaited(containerDo(tester).read(rotasProvider).push('/registro/x'));
      await tester.pumpAndSettle();
      expect(find.text('Gasto não encontrado'), findsOneWidget);
      await encerrarApp(tester);
    });
  });

  test('rótulos das formas de pagamento', () {
    expect(TipoPagamento.values.map((t) => t.rotulo), [
      'Pix',
      'Débito',
      'Dinheiro',
      'Voucher',
    ]);
  });

  test('rotas do formulário existem', () {
    final container = ProviderContainer(overrides: substituicoes());
    addTearDown(container.dispose);
    final rotas = container.read(rotasProvider);
    expect(
      rotas.configuration.findMatch(Uri.parse('/registro/abc')).pathParameters,
      {'uuid': 'abc'},
    );
  });
}
