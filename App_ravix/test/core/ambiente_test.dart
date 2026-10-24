import 'package:flutter_test/flutter_test.dart';
import 'package:ravix/core/ambiente.dart';

final _uuidV4 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

void main() {
  test('RelogioSistema devolve a hora local atual', () {
    final antes = DateTime.now();
    final agora = const RelogioSistema().agora();
    expect(agora.isUtc, isFalse);
    expect(agora.isBefore(antes), isFalse);
  });

  test('GeradorUuidV4 gera UUID v4 minúsculo e único', () {
    const gerador = GeradorUuidV4();
    final ids = List.generate(1000, (_) => gerador.gerar());
    expect(ids.every(_uuidV4.hasMatch), isTrue);
    expect(ids.toSet(), hasLength(1000));
  });

  test('FusoSistema devolve o deslocamento atual do aparelho', () {
    expect(
      const FusoSistema().minutosAtuais(),
      DateTime.now().timeZoneOffset.inMinutes,
    );
  });
}
