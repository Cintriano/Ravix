/// Dependências do app, injetadas pelo Riverpod. Os testes trocam qualquer
/// uma delas com `overrides`.
library;

import 'package:ravix/core/ambiente.dart';
import 'package:ravix/data/banco.dart';
import 'package:ravix/data/categoria_repository.dart';
import 'package:ravix/data/compra_avista_repository.dart';
import 'package:ravix/data/tag_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dependencias.g.dart';

/// Relógio do app.
@Riverpod(keepAlive: true)
Relogio relogio(Ref ref) => const RelogioSistema();

/// Gerador de UUID do app.
@Riverpod(keepAlive: true)
GeradorUuid geradorUuid(Ref ref) => const GeradorUuidV4();

/// Fuso do aparelho.
@Riverpod(keepAlive: true)
Fuso fuso(Ref ref) => const FusoSistema();

/// Banco local, aberto uma vez e fechado junto com o app.
@Riverpod(keepAlive: true)
BancoRavix banco(Ref ref) {
  final banco = abrirBancoRavix();
  ref.onDispose(banco.close);
  return banco;
}

/// Repositório de gastos à vista.
@Riverpod(keepAlive: true)
CompraAvistaRepository compraAvistaRepository(Ref ref) =>
    CompraAvistaRepository(
      ref.watch(bancoProvider),
      relogio: ref.watch(relogioProvider),
      uuid: ref.watch(geradorUuidProvider),
      fuso: ref.watch(fusoProvider),
    );

/// Repositório de tags.
@Riverpod(keepAlive: true)
TagRepository tagRepository(Ref ref) => TagRepository(
  ref.watch(bancoProvider),
  relogio: ref.watch(relogioProvider),
  uuid: ref.watch(geradorUuidProvider),
);

/// Repositório de categorias e subcategorias.
@Riverpod(keepAlive: true)
CategoriaRepository categoriaRepository(Ref ref) =>
    CategoriaRepository(ref.watch(bancoProvider));
