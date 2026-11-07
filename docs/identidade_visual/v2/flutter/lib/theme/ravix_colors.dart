import 'package:flutter/material.dart';

/// Paleta da marca Ravix v2. Valores fixos, iguais nos dois temas.
abstract final class RavixColors {
  // Marca
  static const floresta = Color(0xFF163730);
  static const menta = Color(0xFF78CFA5);
  static const menta600 = Color(0xFF3FB282);
  static const petroleo = Color(0xFF22727B);
  static const areia = Color(0xFFC9AD78);
  static const nevoa = Color(0xFFEEF4F0);
  static const tinta = Color(0xFF0C2420);

  // Estados do orçamento
  static const ok = Color(0xFF3FB282); // abaixo de 80%
  static const atencao = Color(0xFFD9A441); // de 80% a 100%
  static const estourado = Color(0xFFD0614E); // acima de 100%

  // Ordem das cores em gráficos de categoria
  static const chart = <Color>[
    Color(0xFF78CFA5),
    Color(0xFF22727B),
    Color(0xFFC9AD78),
    Color(0xFF4FA3A0),
    Color(0xFF163730),
    Color(0xFFA9C9BC),
  ];

  // Tema claro
  static const lightBackground = Color(0xFFF4F7F4);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceAlt = Color(0xFFE9F0EC);
  static const lightText = Color(0xFF11241F);
  static const lightTextMuted = Color(0xFF5B6F69);
  static const lightLine = Color(0xFFD2DFD8);

  // Tema escuro
  static const darkBackground = Color(0xFF0D1C19);
  static const darkSurface = Color(0xFF132823);
  static const darkSurfaceAlt = Color(0xFF1B3530);
  static const darkText = Color(0xFFE7F0EC);
  static const darkTextMuted = Color(0xFF93A9A2);
  static const darkLine = Color(0xFF244038);
  static const darkInfo = Color(0xFF6CC1C8);

  static const lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: floresta,
    onPrimary: nevoa,
    primaryContainer: Color(0xFFD3EDE0),
    onPrimaryContainer: tinta,
    secondary: petroleo,
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFD2E9EB),
    onSecondaryContainer: Color(0xFF0B3237),
    tertiary: areia,
    onTertiary: Color(0xFF2A2213),
    tertiaryContainer: Color(0xFFF1E6D0),
    onTertiaryContainer: Color(0xFF2A2213),
    error: estourado,
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF8DCD6),
    onErrorContainer: Color(0xFF5A1A10),
    surface: lightSurface,
    onSurface: lightText,
    onSurfaceVariant: lightTextMuted,
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF7FAF8),
    surfaceContainer: lightBackground,
    surfaceContainerHigh: lightSurfaceAlt,
    surfaceContainerHighest: Color(0xFFE1EAE5),
    outline: Color(0xFFB5C7BE),
    outlineVariant: lightLine,
    inverseSurface: Color(0xFF1B3530),
    onInverseSurface: darkText,
    inversePrimary: menta,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceTint: Colors.transparent,
  );

  static const darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: menta,
    onPrimary: tinta,
    primaryContainer: floresta,
    onPrimaryContainer: nevoa,
    secondary: darkInfo,
    onSecondary: Color(0xFF06292D),
    secondaryContainer: Color(0xFF184F55),
    onSecondaryContainer: Color(0xFFCDECEE),
    tertiary: areia,
    onTertiary: Color(0xFF2A2213),
    tertiaryContainer: Color(0xFF4A3D24),
    onTertiaryContainer: Color(0xFFF1E6D0),
    error: Color(0xFFE9806E),
    onError: Color(0xFF3A0D06),
    errorContainer: Color(0xFF5A1F15),
    onErrorContainer: Color(0xFFF8DCD6),
    surface: darkSurface,
    onSurface: darkText,
    onSurfaceVariant: darkTextMuted,
    surfaceContainerLowest: Color(0xFF0A1714),
    surfaceContainerLow: Color(0xFF10221E),
    surfaceContainer: darkSurface,
    surfaceContainerHigh: darkSurfaceAlt,
    surfaceContainerHighest: Color(0xFF22403A),
    outline: Color(0xFF3A5A51),
    outlineVariant: darkLine,
    inverseSurface: darkText,
    onInverseSurface: darkSurface,
    inversePrimary: floresta,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceTint: Colors.transparent,
  );
}
