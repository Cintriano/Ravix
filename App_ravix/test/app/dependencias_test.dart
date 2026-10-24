import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ravix/app/dependencias.dart';
import 'package:ravix/core/ambiente.dart';
import 'package:ravix/data/compra_avista_repository.dart';
import 'package:ravix/features/shell/bloqueio.dart';

import '../helpers/banco_de_teste.dart';

void main() {
  test('sem substituições, usa o sistema', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(relogioProvider), isA<RelogioSistema>());
    expect(container.read(geradorUuidProvider), isA<GeradorUuidV4>());
    expect(container.read(fusoProvider), isA<FusoSistema>());
    expect(
      container.read(servicoBloqueioProvider),
      isA<ServicoBloqueioLocalAuth>(),
    );
  });

  test('repositórios usam o mesmo banco', () async {
    final banco = bancoEmMemoria();
    addTearDown(banco.close);
    final container = ProviderContainer(
      overrides: [bancoProvider.overrideWithValue(banco)],
    );
    addTearDown(container.dispose);

    final compras = container.read(compraAvistaRepositoryProvider);
    final tags = container.read(tagRepositoryProvider);
    final categorias = container.read(categoriaRepositoryProvider);

    final tag = await tags.criar('Viagem');
    final uuid = await compras.criar((
      momento: DateTime(2026, 10, 24),
      descricao: 'Teste',
      valorCentavos: 100,
      tipoPagamento: TipoPagamento.pix,
      idSubcategoria: 101,
      uuidTag: tag.uuidTag,
    ));
    expect((await compras.buscar(uuid))!.uuidTag, tag.uuidTag);
    expect(await categorias.listarCategorias(), hasLength(8));
  });
}
