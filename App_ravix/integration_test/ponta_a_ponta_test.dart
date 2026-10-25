// Fluxos completos no aparelho, com banco em memória e autenticação falsa:
// não toca nos dados do app de uso.
//
// flutter test integration_test/ponta_a_ponta_test.dart -d <aparelho>

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ravix/app.dart';
import 'package:ravix/core/tema/icones.dart';
import 'package:ravix/core/valor.dart';
import 'package:ravix/features/shell/bloqueio.dart';

import '../test/helpers/app_de_teste.dart';
import '../test/helpers/banco_de_teste.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> abrirApp(WidgetTester tester, ServicoBloqueio bloqueio) async {
    final banco = bancoEmMemoria();
    addTearDown(banco.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: substituicoes(banco: banco, bloqueio: bloqueio),
        child: const RavixApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Fecha o teclado e rola a lista vertical da tela até [alvo]: no
  /// aparelho, o teclado ocupa metade da tela e a lista só constrói o que
  /// está visível.
  Future<void> rolarAte(WidgetTester tester, Finder alvo) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    if (alvo.evaluate().isNotEmpty) return;
    await tester.scrollUntilVisible(
      alvo,
      200,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first,
    );
  }

  Future<void> tocar(WidgetTester tester, Finder alvo) async {
    await rolarAte(tester, alvo);
    await tester.ensureVisible(alvo);
    await tester.pumpAndSettle();
    await tester.tap(alvo);
    await tester.pumpAndSettle();
  }

  Future<void> escolherNoMenu(
    WidgetTester tester,
    String rotulo,
    String opcao,
  ) async {
    await rolarAte(tester, find.text(rotulo));
    await tocar(
      tester,
      find.ancestor(
        of: find.text(rotulo),
        matching: find.byType(DropdownButtonFormField<int>),
      ),
    );
    await tester.tap(find.text(opcao).last);
    await tester.pumpAndSettle();
  }

  Future<void> preencherGasto(WidgetTester tester) async {
    await tester.enterText(
      find.widgetWithText(TextField, 'Descrição'),
      'Padaria do Zé',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Valor'), '1250');
    await tocar(tester, find.text('Pix'));
    await escolherNoMenu(tester, 'Categoria', 'Alimentação');
    await escolherNoMenu(tester, 'Subcategoria', 'Padaria');
  }

  testWidgets('gasto: desbloquear, criar, ver, filtrar, editar e excluir', (
    tester,
  ) async {
    await abrirApp(
      tester,
      ServicoBloqueioFalso([
        ResultadoDesbloqueio.negado,
        ResultadoDesbloqueio.liberado,
      ]),
    );

    // Desbloquear.
    expect(find.text('Ravix está bloqueado'), findsOneWidget);
    await tocar(tester, find.text('Desbloquear'));
    expect(find.text('Nenhum gasto em outubro'), findsOneWidget);

    // Criar.
    await tocar(tester, find.text('Novo gasto'));
    await preencherGasto(tester);
    await tocar(tester, find.text('Salvar'));

    // Ver na tabela.
    expect(find.text('Padaria do Zé'), findsOneWidget);
    expect(find.text(formatarCentavos(1250)), findsNWidgets(2));

    // Filtrar.
    await tocar(tester, find.text('Categoria'));
    await tester.tap(find.text('Transporte').last);
    await tester.pumpAndSettle();
    expect(find.text('Nada com esses filtros'), findsOneWidget);
    await tocar(tester, find.text('Limpar filtros'));
    expect(find.text('Padaria do Zé'), findsOneWidget);

    // Editar.
    await tocar(tester, find.text('Padaria do Zé'));
    await tester.enterText(find.widgetWithText(TextField, 'Valor'), '990');
    await tocar(tester, find.text('Salvar'));
    expect(find.text(formatarCentavos(990)), findsNWidgets(2));

    // Excluir.
    await tocar(tester, find.text('Padaria do Zé'));
    await tocar(tester, find.byTooltip('Excluir gasto'));
    await tocar(tester, find.widgetWithText(FilledButton, 'Excluir'));
    expect(find.text('Nenhum gasto em outubro'), findsOneWidget);
    expect(find.text(formatarCentavos(0)), findsOneWidget);
  });

  testWidgets('tag: criar no formulário, usar e arquivar na Configuração', (
    tester,
  ) async {
    await abrirApp(tester, ServicoBloqueioFalso());

    await tocar(tester, find.text('Novo gasto'));
    await preencherGasto(tester);
    await tocar(tester, find.text('Nova tag'));
    await tester.enterText(find.byType(TextField).last, 'Viagem');
    await tocar(tester, find.widgetWithText(FilledButton, 'Criar'));
    await tocar(tester, find.text('Salvar'));
    expect(find.textContaining('Viagem'), findsOneWidget);

    await tocar(tester, find.byIcon(Icones.settings));
    await tocar(tester, find.text('Tags'));
    await tocar(tester, find.byTooltip('Remover Viagem'));
    expect(find.text('Arquivar a tag?'), findsOneWidget);
    await tocar(tester, find.widgetWithText(FilledButton, 'Arquivar'));
    expect(find.text('Nenhuma tag'), findsOneWidget);

    await tocar(tester, find.byTooltip('Voltar'));
    await tocar(tester, find.byTooltip('Voltar'));
    // A tag arquivada continua no gasto antigo.
    expect(find.text('Padaria · 15:00 · Viagem'), findsOneWidget);
  });
}
