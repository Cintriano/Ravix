import 'package:flutter_test/flutter_test.dart';
import 'package:ravix/core/datas.dart';

void main() {
  group('paraIsoLocal / deIsoLocal', () {
    test('formata o relógio de parede sem fuso e sem milissegundos', () {
      expect(
        paraIsoLocal(DateTime(2026, 10, 24, 9, 5, 7, 999)),
        '2026-10-24T09:05:07',
      );
      expect(paraIsoLocal(DateTime(2026)), '2026-01-01T00:00:00');
    });

    test('usa os campos como estão, mesmo em DateTime UTC', () {
      expect(
        paraIsoLocal(DateTime.utc(2026, 3, 1, 23, 59, 59)),
        '2026-03-01T23:59:59',
      );
    });

    test('ida e volta', () {
      const texto = '2028-02-29T12:30:00';
      expect(paraIsoLocal(deIsoLocal(texto)), texto);
      expect(deIsoLocal(texto).isUtc, isFalse);
    });

    test('rejeita texto fora do formato', () {
      for (final invalido in [
        '2026-10-24',
        '2026-10-24 09:05:07',
        '2026-10-24T09:05:07Z',
        '2026-10-24T09:05:07.000',
        '2026-10-24T09:05:07-03:00',
        '',
      ]) {
        expect(
          () => deIsoLocal(invalido),
          throwsFormatException,
          reason: invalido,
        );
      }
    });
  });

  group('formatarData / formatarHora', () {
    test('formato brasileiro com zeros à esquerda', () {
      final data = DateTime(2026, 3, 5, 7, 9);
      expect(formatarData(data), '05/03/2026');
      expect(formatarHora(data), '07:09');
      expect(formatarHora(DateTime(2026, 1, 1, 23, 59)), '23:59');
    });
  });

  group('paraIsoUtc', () {
    test('converte para UTC e termina sempre com Z', () {
      expect(
        paraIsoUtc(DateTime.utc(2026, 10, 24, 21, 30, 15, 500)),
        '2026-10-24T21:30:15Z',
      );
      final local = DateTime(2026, 10, 24, 21, 30);
      final texto = paraIsoUtc(local);
      expect(texto, endsWith('Z'));
      expect(
        DateTime.parse(texto),
        local.toUtc().copyWith(millisecond: 0, microsecond: 0),
      );
    });
  });

  group('instanteUtc', () {
    test(
      'UTC−3 (−180): a noite local vira madrugada do dia seguinte em UTC',
      () {
        expect(
          instanteUtc('2026-10-24T21:30:00', -180),
          DateTime.utc(2026, 10, 25, 0, 30),
        );
      },
    );

    test('UTC+9 (+540): a manhã local vira noite do dia anterior em UTC', () {
      expect(
        instanteUtc('2026-01-01T08:00:00', 540),
        DateTime.utc(2025, 12, 31, 23),
      );
    });

    test('fuso zero mantém o horário', () {
      expect(
        instanteUtc('2026-06-15T12:00:00', 0),
        DateTime.utc(2026, 6, 15, 12),
      );
    });
  });

  group('Mes', () {
    test('intervalo semiaberto do mês', () {
      final outubro = Mes(2026, 10);
      expect(outubro.inicioIso, '2026-10-01T00:00:00');
      expect(outubro.fimIso, '2026-11-01T00:00:00');
    });

    test('registro em 31/10 23:59:59 entra em outubro; 01/11 00:00:00 não', () {
      final outubro = Mes(2026, 10);
      bool contem(String iso) =>
          iso.compareTo(outubro.inicioIso) >= 0 &&
          iso.compareTo(outubro.fimIso) < 0;
      expect(contem('2026-10-31T23:59:59'), isTrue);
      expect(contem('2026-10-01T00:00:00'), isTrue);
      expect(contem('2026-11-01T00:00:00'), isFalse);
      expect(contem('2026-09-30T23:59:59'), isFalse);
    });

    test('virada de ano: dezembro → janeiro e volta', () {
      final dezembro = Mes(2026, 12);
      expect(dezembro.proximo, Mes(2027, 1));
      expect(dezembro.fimIso, '2027-01-01T00:00:00');
      expect(Mes(2027, 1).anterior, dezembro);
    });

    test('fevereiro de ano bissexto e de ano comum', () {
      bool contem(Mes m, String iso) =>
          iso.compareTo(m.inicioIso) >= 0 && iso.compareTo(m.fimIso) < 0;
      expect(contem(Mes(2028, 2), '2028-02-29T23:59:59'), isTrue);
      expect(Mes(2028, 2).fimIso, '2028-03-01T00:00:00');
      expect(Mes(2027, 2).fimIso, '2027-03-01T00:00:00');
    });

    test('nome e rótulo em português', () {
      expect(Mes(2026, 3).nome, 'março');
      expect(Mes(2026, 10).rotulo, 'outubro de 2026');
      expect(Mes(2027, 1).rotulo, 'janeiro de 2027');
    });

    test('Mes.de usa o mês da data', () {
      expect(Mes.de(DateTime(2026, 10, 31, 23, 59)), Mes(2026, 10));
    });

    test('rejeita mês fora de 1 a 12', () {
      expect(() => Mes(2026, 0), throwsRangeError);
      expect(() => Mes(2026, 13), throwsRangeError);
    });

    test('igualdade, hash, ordem e texto', () {
      expect(Mes(2026, 10), Mes(2026, 10));
      expect(Mes(2026, 10).hashCode, Mes(2026, 10).hashCode);
      expect(Mes(2026, 10), isNot(Mes(2026, 11)));
      expect(Mes(2026, 12).compareTo(Mes(2027, 1)), lessThan(0));
      expect(Mes(2026, 10).compareTo(Mes(2026, 9)), greaterThan(0));
      expect(Mes(2026, 10).compareTo(Mes(2026, 10)), 0);
      expect(Mes(2026, 3).toString(), '2026-03');
    });
  });
}
