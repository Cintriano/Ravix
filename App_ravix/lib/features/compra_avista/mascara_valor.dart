import 'package:flutter/services.dart';
import 'package:ravix/core/valor.dart';

/// Máscara monetária que preenche da direita para a esquerda: digitar
/// "1", "2", "5", "0" mostra 0,01 → 0,12 → 1,25 → 12,50 (E01-F03-T03).
/// Só dígitos entram; o campo vazio fica vazio.
final class MascaraValor extends TextInputFormatter {
  /// Até R$ 999.999.999,99.
  static const maximoDigitos = 11;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue anterior,
    TextEditingValue novo,
  ) {
    var digitos = novo.text.replaceAll(RegExp(r'\D'), '');
    digitos = digitos.replaceFirst(RegExp('^0+'), '');
    if (digitos.length > maximoDigitos) return anterior;
    if (digitos.isEmpty) return TextEditingValue.empty;
    final texto = formatarCentavosSemSimbolo(int.parse(digitos));
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}
