import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ravix/app/preferencias.dart';
import 'package:ravix/core/tema/icones.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../helpers/app_de_teste.dart';

void main() {
  group('AparenciaEscolhida', () {
    ProviderContainer comPreferencias(Preferencias preferencias) {
      final container = ProviderContainer(
        overrides: [preferenciasProvider.overrideWithValue(preferencias)],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('sem escolha guardada, segue o sistema', () {
      final container = comPreferencias(PreferenciasEmMemoria());
      expect(container.read(aparenciaEscolhidaProvider), Aparencia.sistema);
      expect(Aparencia.sistema.modo, ThemeMode.system);
    });

    test('lê a escolha guardada', () {
      final container = comPreferencias(
        PreferenciasEmMemoria({chaveAparencia: 'escuro'}),
      );
      expect(container.read(aparenciaEscolhidaProvider), Aparencia.escuro);
    });

    test('valor desconhecido volta para o sistema', () {
      final container = comPreferencias(
        PreferenciasEmMemoria({chaveAparencia: 'roxo'}),
      );
      expect(container.read(aparenciaEscolhidaProvider), Aparencia.sistema);
    });

    test('escolher troca e guarda', () async {
      final preferencias = PreferenciasEmMemoria();
      final container = comPreferencias(preferencias);
      await container
          .read(aparenciaEscolhidaProvider.notifier)
          .escolher(Aparencia.claro);
      expect(container.read(aparenciaEscolhidaProvider), Aparencia.claro);
      expect(preferencias.texto(chaveAparencia), 'claro');
    });
  });

  test('PreferenciasDoAparelho grava e relê pelo shared_preferences', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final primeira = await PreferenciasDoAparelho.abrir();
    expect(primeira.texto(chaveAparencia), isNull);
    await primeira.gravarTexto(chaveAparencia, 'escuro');

    final segunda = await PreferenciasDoAparelho.abrir();
    expect(segunda.texto(chaveAparencia), 'escuro');
  });

  group('tela de Configuração', () {
    ThemeMode modoDoApp(WidgetTester tester) =>
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode!;

    testWidgets('trocar a aparência muda o tema na hora', (tester) async {
      await montarApp(tester);
      expect(modoDoApp(tester), ThemeMode.system);

      await tester.tap(find.byIcon(Icones.settings));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Escuro'));
      await tester.pumpAndSettle();
      expect(modoDoApp(tester), ThemeMode.dark);

      await tester.tap(find.text('Claro'));
      await tester.pumpAndSettle();
      expect(modoDoApp(tester), ThemeMode.light);
      await encerrarApp(tester);
    });

    testWidgets('abre na aparência guardada', (tester) async {
      await montarApp(
        tester,
        extras: [
          preferenciasProvider.overrideWithValue(
            PreferenciasEmMemoria({chaveAparencia: 'claro'}),
          ),
        ],
      );
      expect(modoDoApp(tester), ThemeMode.light);
      await encerrarApp(tester);
    });
  });
}
