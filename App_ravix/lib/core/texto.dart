/// Normalização de texto para busca (DP-36).
library;

const _comAcento = 'àáâãäåāăąçćčèéêëēėęìíîïīñńòóôõöøōùúûüūýÿ';
const _semAcento = 'aaaaaaaaaccceeeeeeeiiiiinnooooooouuuuuyy';

final _espacos = RegExp(r'\s+');
final _curingasLike = RegExp('[%_]');

/// Normaliza [texto] para a coluna `descricao_normalizada` e para a busca da
/// sugestão: minúsculas, sem acento, sem `%` e `_` (curingas do `LIKE`) e com
/// espaços colapsados.
///
/// O texto digitado na busca passa pela mesma função, para que as duas
/// pontas comparem a mesma forma.
String normalizarTexto(String texto) {
  final buffer = StringBuffer();
  for (final rune in texto.toLowerCase().runes) {
    final caractere = String.fromCharCode(rune);
    final indice = _comAcento.indexOf(caractere);
    buffer.write(indice >= 0 ? _semAcento[indice] : caractere);
  }
  return buffer
      .toString()
      .replaceAll(_curingasLike, ' ')
      .replaceAll(_espacos, ' ')
      .trim();
}
