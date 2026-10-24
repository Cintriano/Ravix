import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ravix/app/dependencias.dart';
import 'package:ravix/core/datas.dart';
import 'package:ravix/features/shell/mes_selecionado.dart';

import '../../helpers/ambiente_falso.dart';

void main() {
  late RelogioFixo relogio;
  late ProviderContainer container;

  setUp(() {
    relogio = RelogioFixo(DateTime(2026, 12, 31, 23, 59));
    container = ProviderContainer(
      overrides: [relogioProvider.overrideWithValue(relogio)],
    );
  });
  tearDown(() => container.dispose());

  Mes mes() => container.read(mesSelecionadoProvider);
  MesSelecionado controle() => container.read(mesSelecionadoProvider.notifier);

  test('começa no mês atual do relógio', () {
    expect(mes(), Mes(2026, 12));
  });

  test('avança e volta, inclusive na virada de ano', () {
    controle().avancar();
    expect(mes(), Mes(2027, 1));
    controle().avancar();
    expect(mes(), Mes(2027, 2));
    controle()
      ..voltar()
      ..voltar()
      ..voltar();
    expect(mes(), Mes(2026, 11));
  });

  test('aceita meses passados e futuros distantes', () {
    for (var i = 0; i < 24; i++) {
      controle().voltar();
    }
    expect(mes(), Mes(2024, 12));
    for (var i = 0; i < 48; i++) {
      controle().avancar();
    }
    expect(mes(), Mes(2028, 12));
  });

  test('irParaHoje volta para o mês do relógio', () {
    controle()
      ..avancar()
      ..avancar();
    relogio.momento = DateTime(2027, 3, 10);
    controle().irParaHoje();
    expect(mes(), Mes(2027, 3));
  });
}
