import 'package:flutter_test/flutter_test.dart';
import 'package:ravix/core/texto.dart';

void main() {
  group('normalizarTexto', () {
    test('remove acentos e passa para minúsculas', () {
      expect(normalizarTexto('Açaí'), 'acai');
      expect(normalizarTexto('ÁÉÍÓÚ ÂÊÔ ÃÕ À Ü Ç Ñ'), 'aeiou aeo ao a u c n');
    });

    test('colapsa espaços e apara as pontas', () {
      expect(normalizarTexto('  PADARIA   do Zé '), 'padaria do ze');
      expect(normalizarTexto('Uber\t\nCentro'), 'uber centro');
    });

    test('troca os curingas do LIKE por espaço', () {
      expect(normalizarTexto('50% off'), '50 off');
      expect(normalizarTexto('loja_do_bairro'), 'loja do bairro');
      expect(normalizarTexto('100%_real'), '100 real');
    });

    test('texto vazio ou só com espaços vira vazio', () {
      expect(normalizarTexto(''), '');
      expect(normalizarTexto('   '), '');
      expect(normalizarTexto('%_'), '');
    });

    test('mantém dígitos e pontuação comum', () {
      expect(
        normalizarTexto('Posto Shell 24h - BR-101'),
        'posto shell 24h - br-101',
      );
    });

    test('é idempotente', () {
      const entrada = '  Pão de Açúcar  _ 30% ';
      final uma = normalizarTexto(entrada);
      expect(normalizarTexto(uma), uma);
    });
  });
}
