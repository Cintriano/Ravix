// Gera lib/core/tema/capra_tokens.dart a partir do capra-tokens.json.
//
// Uso (na pasta App_ravix): dart run tool/gerar_tokens.dart
// O teste test/core/tema/capra_tokens_test.dart falha se o JSON mudar sem
// gerar de novo.
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

/// Caminho do JSON, relativo à pasta App_ravix.
const caminhoJson = '../docs/identidade_visual/capra-tokens.json';

/// Caminho do arquivo gerado, relativo à pasta App_ravix.
const caminhoSaida = 'lib/core/tema/capra_tokens.dart';

void main() {
  final texto = File(caminhoJson).readAsStringSync();
  File(caminhoSaida).writeAsStringSync(gerarCodigo(texto));
  final formatado = Process.runSync('dart', ['format', caminhoSaida]);
  if (formatado.exitCode != 0) {
    stderr.write(formatado.stderr);
    exit(1);
  }
  print('Gerado $caminhoSaida');
}

/// Impressão digital do JSON (FNV-1a de 32 bits sobre o JSON normalizado),
/// gravada no arquivo gerado para o teste conferir a sincronia.
String impressaoDigital(String textoJson) {
  final normalizado = jsonEncode(jsonDecode(textoJson));
  var hash = 0x811c9dc5;
  for (final byte in utf8.encode(normalizado)) {
    hash = ((hash ^ byte) * 0x01000193) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}

String _camelCase(String nome) {
  final partes = nome.split('-');
  final b = StringBuffer(partes.first);
  for (final p in partes.skip(1)) {
    b
      ..write(p[0].toUpperCase())
      ..write(p.substring(1));
  }
  return b.toString();
}

String _primeiraFrase(String? texto) {
  if (texto == null || texto.isEmpty) return '';
  final fim = texto.indexOf('. ');
  return fim < 0 ? texto : texto.substring(0, fim + 1);
}

String _cor(String hex) => 'Color(0xFF${hex.substring(1).toUpperCase()})';

String _px(String valor) {
  final n = double.parse(valor.replaceAll('px', ''));
  return n == n.roundToDouble() ? n.toInt().toString() : n.toString();
}

/// Comentário de documentação quebrado em linhas de até 80 colunas.
String _doc(String recuo, String texto) {
  final prefixo = '$recuo///';
  final linhas = <List<String>>[[]];
  var largura = prefixo.length;
  for (final palavra in texto.trim().split(' ')) {
    if (largura + 1 + palavra.length > 80 && linhas.last.isNotEmpty) {
      linhas.add([]);
      largura = prefixo.length;
    }
    linhas.last.add(palavra);
    largura += 1 + palavra.length;
  }
  return linhas.map((l) => '$prefixo ${l.join(' ')}').join('\n');
}

int _ms(String valor) => int.parse(valor.replaceAll('ms', ''));

/// Código Dart do arquivo gerado.
String gerarCodigo(String textoJson) {
  final json = jsonDecode(textoJson) as Map<String, dynamic>;
  List<Map<String, dynamic>> tokens(String grupo) =>
      ((json[grupo] as Map<String, dynamic>)['tokens'] as List)
          .cast<Map<String, dynamic>>();

  // Cores: resolve referências {outro} para o par dark/light.
  final cores = <String, Map<String, dynamic>>{
    for (final t in [...tokens('color'), ...tokens('data')])
      t['name'] as String: t,
  };
  Map<String, String> resolver(String nome) {
    final valor = cores[nome]!['value'];
    if (valor is String) {
      return resolver(valor.substring(1, valor.length - 1));
    }
    final par = valor as Map<String, dynamic>;
    return {'dark': par['dark'] as String, 'light': par['light'] as String};
  }

  final b = StringBuffer()
    ..writeln('// GERADO por tool/gerar_tokens.dart a partir de')
    ..writeln('// docs/identidade_visual/capra-tokens.json. Não edite.')
    ..writeln()
    ..writeln('/// Tokens da marca CAPRA (manual v1.6).')
    ..writeln('library;')
    ..writeln()
    ..writeln("import 'package:flutter/animation.dart';")
    ..writeln()
    ..writeln('/// Impressão digital do JSON de origem.')
    ..writeln("const capraTokensImpressao = '${impressaoDigital(textoJson)}';")
    ..writeln()
    ..writeln('/// Cores de um tema CAPRA (dark ou light).')
    ..writeln('final class CapraPaleta {')
    ..writeln('  /// Cria a paleta.')
    ..writeln('  const new({');
  for (final nome in cores.keys) {
    b.writeln('    required this.${_camelCase(nome)},');
  }
  b.writeln('  });');
  for (final MapEntry(key: nome, value: t) in cores.entries) {
    final doc = _primeiraFrase(t['usage'] as String?);
    b
      ..writeln()
      ..writeln(_doc('  ', '`$nome`. $doc'))
      ..writeln('  final Color ${_camelCase(nome)};');
  }
  b
    ..writeln('}')
    ..writeln()
    ..writeln('/// Valores dos tokens CAPRA.')
    ..writeln('abstract final class CapraTokens {');
  for (final (tema, campo) in [('dark', 'escuro'), ('light', 'claro')]) {
    b
      ..writeln('  /// Paleta do tema ${tema == 'dark' ? 'dark' : 'claro'}.')
      ..writeln('  static const $campo = CapraPaleta(');
    for (final nome in cores.keys) {
      b.writeln('    ${_camelCase(nome)}: ${_cor(resolver(nome)[tema]!)},');
    }
    b
      ..writeln('  );')
      ..writeln();
  }
  for (final grupo in ['spacing', 'radius', 'icon']) {
    for (final t in tokens(grupo)) {
      final doc = _primeiraFrase(t['usage'] as String?);
      b
        ..writeln(_doc('  ', '`${t['name']}`. $doc'))
        ..writeln(
          '  static const double ${_camelCase(t['name'] as String)} = '
          '${_px(t['value'] as String)};',
        )
        ..writeln();
    }
  }
  for (final t in tokens('motion')) {
    final nome = t['name'] as String;
    final valor = t['value'] as String;
    final doc = _primeiraFrase(t['usage'] as String?);
    b.writeln(_doc('  ', '`$nome`. $doc'));
    if (valor.endsWith('ms')) {
      b.writeln(
        '  static const ${_camelCase(nome)} = '
        'Duration(milliseconds: ${_ms(valor)});',
      );
    } else if (valor.startsWith('cubic-bezier')) {
      final args = valor.substring(13, valor.length - 1);
      b.writeln('  static const ${_camelCase(nome)} = Cubic($args);');
    } else {
      b.writeln('  static const double ${_camelCase(nome)} = ${_px(valor)};');
    }
    b.writeln();
  }
  b.writeln('}');
  return b.toString();
}
