import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ravix/core/tema/marca.dart';
import 'package:ravix/core/tema/tema.dart';
import 'package:ravix/core/tema/tokens.dart';

void main() {
  test('cores da marca conferem com o manual v2', () {
    expect(CoresRavix.floresta, const Color(0xFF163730));
    expect(CoresRavix.menta, const Color(0xFF78CFA5));
    expect(CoresRavix.menta600, const Color(0xFF3FB282));
    expect(CoresRavix.petroleo, const Color(0xFF22727B));
    expect(TokensRavix.claro.background, const Color(0xFFF4F7F4));
    expect(TokensRavix.escuro.background, const Color(0xFF0D1C19));
  });

  for (final (brilho, paleta) in [
    (Brightness.dark, TokensRavix.escuro),
    (Brightness.light, TokensRavix.claro),
  ]) {
    group('tema ${brilho.name}', () {
      final tema = temaRavix(brilho);
      final cores = tema.colorScheme;

      test('mapeia a paleta para o ColorScheme', () {
        expect(cores.brightness, brilho);
        expect(cores.surface, paleta.background);
        expect(tema.scaffoldBackgroundColor, paleta.background);
        expect(cores.surfaceContainer, paleta.surface);
        expect(cores.outlineVariant, paleta.border);
        expect(cores.onSurface, paleta.textPrimary);
        expect(cores.onSurfaceVariant, paleta.textSecondary);
        expect(cores.primary, paleta.primary);
        expect(cores.onPrimary, paleta.onPrimary);
        expect(cores.error, paleta.danger);
        expect(cores.surfaceTint, Colors.transparent);
      });

      test('botão principal: Floresta no claro, Menta no escuro', () {
        expect(
          paleta.primary,
          brilho == Brightness.dark ? CoresRavix.menta : CoresRavix.floresta,
        );
        expect(
          tema.floatingActionButtonTheme.backgroundColor,
          CoresRavix.menta,
        );
      });

      test('componentes chanfrados', () {
        expect(
          tema.floatingActionButtonTheme.shape,
          chanfro(TokensRavix.chanfroG),
        );
        expect(tema.chipTheme.shape, chanfro(TokensRavix.chanfroP));
        expect(tema.inputDecorationTheme.border, isA<RavixBordaDeCampo>());
      });

      test('escala: Chakra Petch nos títulos, Archivo no texto', () {
        final t = tema.textTheme;
        expect(t.bodyLarge!.fontFamily, familiaTexto);
        expect(t.bodyLarge!.fontSize, 16);
        expect(t.bodyLarge!.height! * 16, closeTo(24, 0.01));
        expect(t.headlineSmall!.fontFamily, familiaTitulo);
        expect(t.headlineSmall!.fontSize, 24);
        expect(t.titleMedium!.fontFamily, familiaTitulo);
        expect(t.labelLarge!.fontWeight, FontWeight.w600);
        expect(t.bodySmall!.color, paleta.textSecondary);
      });

      test('valores em Ravix Valores', () {
        final extensao = tema.extension<TemaRavix>()!;
        expect(extensao.paleta, same(paleta));
        expect(extensao.acento, paleta.accent);
        expect(extensao.valorDestaque.fontFamily, familiaValores);
        expect(extensao.valorDestaque.fontSize, 40);
        expect(extensao.valorLista.fontFamily, familiaValores);
        expect(extensao.resumoFundo, CoresRavix.floresta);
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
    const escuro = TemaRavix(TokensRavix.escuro);
    const claro = TemaRavix(TokensRavix.claro);
    expect(
      escuro.copyWith(paleta: TokensRavix.claro).paleta,
      TokensRavix.claro,
    );
    expect(escuro.copyWith().paleta, TokensRavix.escuro);
    expect(escuro.lerp(claro, 0.2), same(escuro));
    expect(escuro.lerp(claro, 0.8), same(claro));
    expect(escuro.lerp(null, 0.8), same(escuro));
  });

  test('RavixBordaDeCampo: chanfro nos quatro cantos', () {
    const borda = RavixBordaDeCampo();
    final caminho = borda.getOuterPath(const Rect.fromLTWH(0, 0, 100, 56));
    expect(caminho.contains(const Offset(1, 1)), isFalse);
    expect(caminho.contains(const Offset(99, 55)), isFalse);
    expect(caminho.contains(const Offset(50, 28)), isTrue);
    expect(borda.copyWith(corte: 4).corte, 4);
    expect(borda, const RavixBordaDeCampo());
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
    expect(lido.paleta, same(TokensRavix.claro));
  });

  testWidgets('marca: abertura termina e respeita reduzir movimento', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: temaRavix(Brightness.light),
        home: const Center(child: MarcaRavix.logo(animar: true)),
      ),
    );
    expect(find.bySemanticsLabel('Ravix'), findsOneWidget);
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      MaterialApp(
        theme: temaRavix(Brightness.dark),
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Center(child: MarcaRavix.simbolo(emLaco: true)),
        ),
      ),
    );
    // Parado: com o laço rodando, o pumpAndSettle não terminaria.
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Ravix'), findsOneWidget);
  });
}
