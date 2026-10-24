import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ravix/core/tema/capra_tokens.dart';
import 'package:ravix/core/tema/tema.dart';

import '../../../tool/gerar_tokens.dart' as gerador;

void main() {
  group('tokens', () {
    final json = File(gerador.caminhoJson).readAsStringSync();

    test('capra_tokens.dart está em dia com o JSON', () {
      expect(
        capraTokensImpressao,
        gerador.impressaoDigital(json),
        reason: 'Rode: dart run tool/gerar_tokens.dart',
      );
    });

    test('valores conferem com o JSON', () {
      final tokens =
          ((jsonDecode(json) as Map<String, dynamic>)['color']
                  as Map<String, dynamic>)['tokens']
              as List<dynamic>;
      final cores = {
        for (final t in tokens.cast<Map<String, dynamic>>())
          t['name'] as String: t['value'],
      };
      String valor(String nome, String tema) =>
          (cores[nome] as Map<String, dynamic>)[tema] as String;
      String hex(Color c) =>
          '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
      expect(hex(CapraTokens.escuro.background), valor('background', 'dark'));
      expect(hex(CapraTokens.claro.background), valor('background', 'light'));
      expect(
        hex(CapraTokens.escuro.accentFinance),
        valor('accentFinance', 'dark'),
      );
      // Referência {accentAutomation} resolvida.
      expect(CapraTokens.escuro.success, CapraTokens.escuro.accentAutomation);
      expect(CapraTokens.radiusMd, 12);
      expect(CapraTokens.motionScreen, const Duration(milliseconds: 300));
      expect(CapraTokens.easeEnter, const Cubic(0.2, 0, 0, 1));
    });
  });

  for (final (brilho, paleta) in [
    (Brightness.dark, CapraTokens.escuro),
    (Brightness.light, CapraTokens.claro),
  ]) {
    group('tema ${brilho.name}', () {
      final tema = temaRavix(brilho);
      final cores = tema.colorScheme;

      test('mapeia os tokens para o ColorScheme do guia', () {
        expect(cores.brightness, brilho);
        expect(cores.surface, paleta.background);
        expect(tema.scaffoldBackgroundColor, paleta.background);
        expect(cores.surfaceContainer, paleta.surface);
        expect(cores.surfaceContainerHigh, paleta.surfaceElevated);
        expect(cores.secondaryContainer, paleta.surfaceElevated);
        expect(cores.outlineVariant, paleta.border);
        expect(cores.outline, paleta.borderStrong);
        expect(cores.onSurface, paleta.textPrimary);
        expect(cores.onSurfaceVariant, paleta.textSecondary);
        expect(cores.primary, paleta.accentFinance);
        expect(cores.onPrimary, paleta.onAccent);
        expect(cores.error, paleta.danger);
        expect(cores.onError, paleta.onAccent);
        expect(cores.surfaceTint, Colors.transparent);
      });

      test('expõe a paleta e o acento de Finanças', () {
        final extensao = tema.extension<TemaRavix>()!;
        expect(extensao.paleta, same(paleta));
        expect(extensao.acento, paleta.accentFinance);
      });

      test('escala tipográfica mobile em Inter', () {
        final t = tema.textTheme;
        expect(t.bodyLarge!.fontFamily, familiaTexto);
        expect(t.bodyLarge!.fontSize, 16);
        expect(t.bodyLarge!.height! * 16, closeTo(24, 0.01));
        expect(t.labelLarge!.fontWeight, FontWeight.w500);
        expect(t.titleLarge!.fontSize, 20);
        expect(t.headlineMedium!.fontFamily, familiaTitulo);
        expect(t.headlineMedium!.fontSize, 28);
        expect(t.displaySmall!.fontSize, 34);
        expect(t.displaySmall!.fontFeatures, numerosTabulares);
        expect(t.bodySmall!.color, paleta.textSecondary);
      });

      test('barras do sistema transparentes', () {
        final barras = tema.appBarTheme.systemOverlayStyle!;
        expect(barras.statusBarColor, Colors.transparent);
        expect(
          barras.statusBarIconBrightness,
          brilho == Brightness.dark ? Brightness.light : Brightness.dark,
        );
      });
    });
  }

  test('TemaRavix: copyWith e lerp', () {
    const escuro = TemaRavix(CapraTokens.escuro);
    const claro = TemaRavix(CapraTokens.claro);
    expect(
      escuro.copyWith(paleta: CapraTokens.claro).paleta,
      CapraTokens.claro,
    );
    expect(escuro.copyWith().paleta, CapraTokens.escuro);
    expect(escuro.lerp(claro, 0.2), same(escuro));
    expect(escuro.lerp(claro, 0.8), same(claro));
    expect(escuro.lerp(null, 0.8), same(escuro));
  });

  testWidgets('context.temaRavix lê a extensão', (tester) async {
    late TemaRavix lido;
    await tester.pumpWidget(
      MaterialApp(
        theme: temaRavix(Brightness.light),
        home: Builder(
          builder: (context) {
            lido = context.temaRavix;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(lido.paleta, same(CapraTokens.claro));
  });
}
