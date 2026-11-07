import 'package:flutter/material.dart';

/// Famílias declaradas no pubspec.yaml (veja pubspec_ravix.yaml).
abstract final class RavixFonts {
  /// Logotipo, títulos e valores grandes. Cantos chanfrados como o símbolo.
  static const display = 'ChakraPetch';

  /// Interface, rótulos, listas e botões.
  static const text = 'Archivo';

  /// Derivada da Chakra Petch com dígitos de largura igual.
  /// Use só em valores em dinheiro, para alinhar as colunas.
  static const values = 'RavixValores';
}

abstract final class RavixTypography {
  /// Escala do app em sp. Os nomes seguem os papéis do Material 3.
  static TextTheme textTheme({required Color text, required Color muted}) {
    const d = RavixFonts.display;
    const t = RavixFonts.text;
    return TextTheme(
      displayLarge: TextStyle(fontFamily: d, fontWeight: FontWeight.w700, fontSize: 57, height: 60 / 57, letterSpacing: -1.1, color: text),
      displayMedium: TextStyle(fontFamily: d, fontWeight: FontWeight.w700, fontSize: 45, height: 48 / 45, letterSpacing: -0.9, color: text),
      // Valor destaque (total do mês)
      displaySmall: TextStyle(fontFamily: d, fontWeight: FontWeight.w700, fontSize: 40, height: 44 / 40, letterSpacing: -0.8, color: text),
      headlineLarge: TextStyle(fontFamily: d, fontWeight: FontWeight.w700, fontSize: 32, height: 36 / 32, letterSpacing: -0.6, color: text),
      headlineMedium: TextStyle(fontFamily: d, fontWeight: FontWeight.w700, fontSize: 28, height: 32 / 28, letterSpacing: -0.4, color: text),
      // Título de tela
      headlineSmall: TextStyle(fontFamily: d, fontWeight: FontWeight.w700, fontSize: 24, height: 28 / 24, letterSpacing: -0.24, color: text),
      titleLarge: TextStyle(fontFamily: d, fontWeight: FontWeight.w700, fontSize: 22, height: 28 / 22, letterSpacing: -0.2, color: text),
      // Seção
      titleMedium: TextStyle(fontFamily: d, fontWeight: FontWeight.w600, fontSize: 18, height: 24 / 18, color: text),
      titleSmall: TextStyle(fontFamily: t, fontWeight: FontWeight.w600, fontSize: 14, height: 20 / 14, color: text),
      // Corpo (também é o texto digitado nos campos)
      bodyLarge: TextStyle(fontFamily: t, fontWeight: FontWeight.w400, fontSize: 16, height: 24 / 16, color: text),
      bodyMedium: TextStyle(fontFamily: t, fontWeight: FontWeight.w400, fontSize: 14, height: 20 / 14, color: text),
      // Legenda
      bodySmall: TextStyle(fontFamily: t, fontWeight: FontWeight.w500, fontSize: 12, height: 16 / 12, letterSpacing: 0.12, color: muted),
      // Botões
      labelLarge: TextStyle(fontFamily: t, fontWeight: FontWeight.w600, fontSize: 16, height: 20 / 16, color: text),
      // Rótulo
      labelMedium: TextStyle(fontFamily: t, fontWeight: FontWeight.w500, fontSize: 14, height: 20 / 14, color: text),
      // Sobretítulo (use em maiúsculas)
      labelSmall: TextStyle(fontFamily: t, fontWeight: FontWeight.w600, fontSize: 11, height: 16 / 11, letterSpacing: 1.1, color: muted),
    );
  }
}
