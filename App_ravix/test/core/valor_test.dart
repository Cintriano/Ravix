import 'package:flutter_test/flutter_test.dart';
import 'package:ravix/core/valor.dart';

// O intl separa "R$" do número com espaço não separável.
const _nbsp = ' ';

void main() {
  group('centavosDeTexto', () {
    test('aceita inteiros e até duas casas decimais', () {
      expect(centavosDeTexto('0'), 0);
      expect(centavosDeTexto('0,01'), 1);
      expect(centavosDeTexto('12'), 1200);
      expect(centavosDeTexto('12,5'), 1250);
      expect(centavosDeTexto('12,05'), 1205);
      expect(centavosDeTexto('1234,56'), 123456);
    });

    test(r'aceita separador de milhar e prefixo R$', () {
      expect(centavosDeTexto('1.234,56'), 123456);
      expect(centavosDeTexto('1.000.000'), 100000000);
      expect(centavosDeTexto(r'R$ 1.234,56'), 123456);
      expect(centavosDeTexto('R\$${_nbsp}9,90'), 990);
      expect(centavosDeTexto('  7,00  '), 700);
    });

    test('rejeita entradas inválidas', () {
      for (final invalido in [
        '',
        '   ',
        'abc',
        '12a',
        '-5',
        '-5,00',
        '1,234',
        '12,',
        ',50',
        '1.23,00',
        '1234.56',
        '12.345.6',
        '1 234',
      ]) {
        expect(centavosDeTexto(invalido), isNull, reason: '"$invalido"');
      }
    });
  });

  group('centavosDeDigitos', () {
    test('lê os dígitos como centavos', () {
      expect(centavosDeDigitos(''), 0);
      expect(centavosDeDigitos('1'), 1);
      expect(centavosDeDigitos('123456'), 123456);
    });

    test('ignora o que não é dígito', () {
      expect(centavosDeDigitos(r'R$ 1.234,56'), 123456);
      expect(centavosDeDigitos('a1b2'), 12);
    });
  });

  group('formatarCentavosSemSimbolo', () {
    test(r'formata sem R$', () {
      expect(formatarCentavosSemSimbolo(0), '0,00');
      expect(formatarCentavosSemSimbolo(5), '0,05');
      expect(formatarCentavosSemSimbolo(123456), '1.234,56');
    });
  });

  group('formatarCentavos', () {
    test('formata em reais com vírgula e milhar', () {
      expect(formatarCentavos(0), 'R\$${_nbsp}0,00');
      expect(formatarCentavos(1), 'R\$${_nbsp}0,01');
      expect(formatarCentavos(990), 'R\$${_nbsp}9,90');
      expect(formatarCentavos(123456), 'R\$${_nbsp}1.234,56');
      expect(formatarCentavos(100000000), 'R\$${_nbsp}1.000.000,00');
    });

    test('ida e volta centavos ↔ texto', () {
      for (final centavos in [
        0,
        1,
        10,
        99,
        100,
        101,
        123456,
        99999999,
        100000000,
      ]) {
        expect(centavosDeTexto(formatarCentavos(centavos)), centavos);
      }
    });
  });
}
