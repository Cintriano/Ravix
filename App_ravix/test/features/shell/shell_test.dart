import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ravix/core/tema/icones.dart';
import 'package:ravix/features/shell/bloqueio.dart';
import 'package:ravix/features/shell/tela_bloqueio.dart';

import '../../helpers/app_de_teste.dart';

void main() {
  group('shell', () {
    testWidgets('abre na aba À vista do mês atual', (tester) async {
      await montarApp(tester);
      expect(find.text('Outubro de 2026'), findsOneWidget);
      expect(find.text('Nenhum gasto em outubro'), findsOneWidget);
      // Uma aba só na v1: sem barra de navegação inferior.
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('o seletor troca o mês da tela inteira', (tester) async {
      await montarApp(tester);

      await tester.tap(find.byTooltip('Próximo mês'));
      await tester.pumpAndSettle();
      expect(find.text('Novembro de 2026'), findsOneWidget);
      expect(find.text('Nenhum gasto em novembro'), findsOneWidget);

      await tester.tap(find.byTooltip('Próximo mês'));
      await tester.tap(find.byTooltip('Próximo mês'));
      await tester.pumpAndSettle();
      expect(find.text('Janeiro de 2027'), findsOneWidget);

      for (var i = 0; i < 4; i++) {
        await tester.tap(find.byTooltip('Mês anterior'));
      }
      await tester.pumpAndSettle();
      expect(find.text('Setembro de 2026'), findsOneWidget);
    });

    testWidgets('tocar no mês volta para hoje', (tester) async {
      await montarApp(tester);
      await tester.tap(find.byTooltip('Mês anterior'));
      await tester.pumpAndSettle();
      expect(find.text('Setembro de 2026'), findsOneWidget);

      await tester.tap(find.text('Setembro de 2026'));
      await tester.pumpAndSettle();
      expect(find.text('Outubro de 2026'), findsOneWidget);
    });

    testWidgets('o botão flutuante abre o formulário', (tester) async {
      await montarApp(tester);
      await tester.tap(find.text('Novo gasto'));
      await tester.pumpAndSettle();
      expect(find.text('Formulário em construção'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Outubro de 2026'), findsOneWidget);
    });

    testWidgets('a engrenagem leva à Configuração', (tester) async {
      await montarApp(tester);
      await tester.tap(find.byIcon(Icones.settings));
      await tester.pumpAndSettle();
      expect(find.text('Tags'), findsOneWidget);
      expect(find.text('Nenhuma tag'), findsOneWidget);
      await encerrarApp(tester);
    });
  });

  group('bloqueio na tela', () {
    testWidgets('pede o desbloqueio ao abrir e libera', (tester) async {
      final servico = ServicoBloqueioFalso();
      await montarApp(tester, bloqueio: servico);
      expect(servico.pedidos, 1);
      expect(find.byType(TelaBloqueio), findsNothing);
      expect(find.text('Outubro de 2026'), findsOneWidget);
    });

    testWidgets('cancelado: continua bloqueado e explica', (tester) async {
      final servico = ServicoBloqueioFalso([ResultadoDesbloqueio.negado]);
      await montarApp(tester, bloqueio: servico);

      expect(find.byType(TelaBloqueio), findsOneWidget);
      expect(find.text('Ravix está bloqueado'), findsOneWidget);
      expect(
        find.text('Não foi possível confirmar. Tente de novo.'),
        findsOneWidget,
      );
      expect(find.text('Outubro de 2026'), findsNothing);

      servico.responderCom(ResultadoDesbloqueio.liberado);
      await tester.tap(find.text('Desbloquear'));
      await tester.pumpAndSettle();
      expect(find.byType(TelaBloqueio), findsNothing);
      expect(find.text('Outubro de 2026'), findsOneWidget);
    });

    testWidgets('falha temporária mostra a mensagem própria', (tester) async {
      await montarApp(
        tester,
        bloqueio: ServicoBloqueioFalso([ResultadoDesbloqueio.falhou]),
      );
      expect(find.textContaining('não está disponível agora'), findsOneWidget);
    });
  });
}
