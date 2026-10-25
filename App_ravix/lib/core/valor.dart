/// Valores monetários em centavos (`int`), nunca em ponto flutuante.
library;

import 'package:intl/intl.dart';

final _formatoNumero = NumberFormat('#,##0.00', 'pt_BR');

final _formatoReal = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: r'R$',
  decimalDigits: 2,
);

// "1234", "1234,5", "1.234,56". Sem sinal: valor negativo é inválido.
final _valorComMilhar = RegExp(r'^\d{1,3}(\.\d{3})+(,\d{1,2})?$');
final _valorSimples = RegExp(r'^\d+(,\d{1,2})?$');
// O intl separa "R$" do número com U+00A0.
const _espacoNaoSeparavel = '\u00a0';
final _prefixoReal = RegExp(r'^R\$\s*');

/// Converte o texto digitado em centavos.
///
/// Aceita `"12"`, `"12,5"`, `"1234,56"`, `"1.234,56"` e `"R$ 1.234,56"`.
/// Devolve `null` para texto vazio, negativo, com letras, com mais de duas
/// casas decimais ou com separador de milhar fora de lugar. Zero é aceito
/// aqui; a regra "maior que zero" é do formulário (E01-F03-T03).
int? centavosDeTexto(String texto) {
  final limpo = texto
      .trim()
      .replaceFirst(_prefixoReal, '')
      .replaceAll(_espacoNaoSeparavel, '')
      .trim();
  if (!_valorComMilhar.hasMatch(limpo) && !_valorSimples.hasMatch(limpo)) {
    return null;
  }
  final partes = limpo.replaceAll('.', '').split(',');
  final reais = int.parse(partes[0]);
  final centavos = partes.length == 2
      ? int.parse(partes[1].padRight(2, '0'))
      : 0;
  return reais * 100 + centavos;
}

/// Converte só os dígitos digitados em centavos, para a máscara monetária
/// que preenche da direita para a esquerda: `"123456"` vira 123456
/// (R$ 1.234,56). Qualquer caractere que não seja dígito é ignorado.
int centavosDeDigitos(String digitado) {
  final digitos = digitado.replaceAll(RegExp(r'\D'), '');
  return digitos.isEmpty ? 0 : int.parse(digitos);
}

/// Formata [centavos] sem o símbolo: 123456 vira `"1.234,56"`. É o texto
/// do campo de valor, que mostra `R$` como prefixo.
String formatarCentavosSemSimbolo(int centavos) =>
    _formatoNumero.format(centavos / 100);

/// Formata [centavos] como moeda brasileira: 123456 vira `"R$ 1.234,56"`.
///
/// O espaço depois de `R$` é o não separável (U+00A0) usado pelo `intl`.
String formatarCentavos(int centavos) => _formatoReal.format(centavos / 100);
