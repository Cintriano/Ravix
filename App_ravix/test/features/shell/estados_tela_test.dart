import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ravix/features/shell/estados_tela.dart';

import '../../helpers/app_de_teste.dart';

void main() {
  Widget conteudo(AsyncValue<List<int>> valor, {VoidCallback? aoTentar}) =>
      comTema(
        ConteudoAssincrono<List<int>>(
          valor: valor,
          estaVazio: (lista) => lista.isEmpty,
          vazio: const EstadoVazio(titulo: 'Vazio', mensagem: 'Nada aqui.'),
          aoTentarDeNovo: aoTentar,
          conteudo: (lista) => Text('${lista.length} itens'),
        ),
      );

  testWidgets('carregando mostra o indicador orbital', (tester) async {
    await tester.pumpWidget(conteudo(const AsyncLoading()));
    expect(find.byType(EstadoCarregando), findsOneWidget);
    expect(find.bySemanticsLabel('Carregando…'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(EstadoCarregando), findsOneWidget);
  });

  testWidgets('com dados mostra o conteúdo', (tester) async {
    await tester.pumpWidget(conteudo(const AsyncData([1, 2, 3])));
    expect(find.text('3 itens'), findsOneWidget);
    expect(find.byType(EstadoVazio), findsNothing);
  });

  testWidgets('sem dados mostra o estado vazio', (tester) async {
    await tester.pumpWidget(conteudo(const AsyncData([])));
    expect(find.text('Vazio'), findsOneWidget);
    expect(find.text('Nada aqui.'), findsOneWidget);
  });

  testWidgets('erro mostra a mensagem e tenta de novo', (tester) async {
    var tentativas = 0;
    await tester.pumpWidget(
      conteudo(
        AsyncError(Exception('falhou'), StackTrace.empty),
        aoTentar: () => tentativas++,
      ),
    );
    expect(find.text('Algo deu errado'), findsOneWidget);
    await tester.tap(find.text('Tentar de novo'));
    expect(tentativas, 1);
  });

  testWidgets('erro sem ação não mostra botão', (tester) async {
    await tester.pumpWidget(
      conteudo(AsyncError(Exception('falhou'), StackTrace.empty)),
    );
    expect(find.text('Tentar de novo'), findsNothing);
  });

  testWidgets('sem critério de vazio, lista vazia é conteúdo', (tester) async {
    await tester.pumpWidget(
      comTema(
        ConteudoAssincrono<List<int>>(
          valor: const AsyncData([]),
          conteudo: (lista) => const Text('conteúdo'),
        ),
      ),
    );
    expect(find.text('conteúdo'), findsOneWidget);
  });

  testWidgets('vazio com ação mostra o botão', (tester) async {
    var acionou = false;
    await tester.pumpWidget(
      comTema(
        EstadoVazio(
          titulo: 'Sem tags',
          mensagem: 'Crie a primeira.',
          rotuloAcao: 'Nova tag',
          aoAgir: () => acionou = true,
        ),
      ),
    );
    await tester.tap(find.text('Nova tag'));
    expect(acionou, isTrue);
  });

  testWidgets('com animações reduzidas o carregamento fica parado', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: comTema(const EstadoCarregando()),
      ),
    );
    // Sem animação em repetição, o pumpAndSettle termina.
    await tester.pumpAndSettle();
    expect(find.byType(EstadoCarregando), findsOneWidget);
  });

  testWidgets('funciona no tema claro', (tester) async {
    await tester.pumpWidget(
      comTema(
        const EstadoErro(mensagem: 'Sem conexão.'),
        brilho: Brightness.light,
      ),
    );
    expect(find.text('Sem conexão.'), findsOneWidget);
  });
}
