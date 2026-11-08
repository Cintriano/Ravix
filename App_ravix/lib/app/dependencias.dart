/// Dependências do app, injetadas pelo Riverpod. Os testes trocam qualquer
/// uma delas com `overrides`.
library;

import 'package:path_provider/path_provider.dart';
import 'package:ravix/app/compartilhar.dart';
import 'package:ravix/core/ambiente.dart';
import 'package:ravix/data/analise_repository.dart';
import 'package:ravix/data/backup.dart';
import 'package:ravix/data/banco.dart';
import 'package:ravix/data/cartao_repository.dart';
import 'package:ravix/data/categoria_repository.dart';
import 'package:ravix/data/compra_avista_repository.dart';
import 'package:ravix/data/fatura_repository.dart';
import 'package:ravix/data/faturado_repository.dart';
import 'package:ravix/data/macro_repository.dart';
import 'package:ravix/data/recorrencia_repository.dart';
import 'package:ravix/data/renda_repository.dart';
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

/// Exportação do backup do banco (Configuração).
@Riverpod(keepAlive: true)
BackupRepository backupRepository(Ref ref) => BackupRepository(
  ref.watch(bancoProvider),
  relogio: ref.watch(relogioProvider),
  pastaTemporaria: getTemporaryDirectory,
);

/// Compartilhamento de arquivos do sistema.
@Riverpod(keepAlive: true)
Compartilhador compartilhador(Ref ref) => const CompartilhadorSistema();

/// Repositório de cartões de crédito.
@Riverpod(keepAlive: true)
CartaoRepository cartaoRepository(Ref ref) => CartaoRepository(
  ref.watch(bancoProvider),
  relogio: ref.watch(relogioProvider),
  uuid: ref.watch(geradorUuidProvider),
);

/// Repositório da renda por vigência.
@Riverpod(keepAlive: true)
RendaRepository rendaRepository(Ref ref) => RendaRepository(
  ref.watch(bancoProvider),
  relogio: ref.watch(relogioProvider),
  uuid: ref.watch(geradorUuidProvider),
);

/// Repositório do faturado: compras no cartão, pagamentos e estornos.
@Riverpod(keepAlive: true)
FaturadoRepository faturadoRepository(Ref ref) => FaturadoRepository(
  ref.watch(bancoProvider),
  relogio: ref.watch(relogioProvider),
  uuid: ref.watch(geradorUuidProvider),
  fuso: ref.watch(fusoProvider),
);

/// Repositório das recorrências.
@Riverpod(keepAlive: true)
RecorrenciaRepository recorrenciaRepository(Ref ref) => RecorrenciaRepository(
  ref.watch(bancoProvider),
  relogio: ref.watch(relogioProvider),
  uuid: ref.watch(geradorUuidProvider),
  fuso: ref.watch(fusoProvider),
);

/// Leitura das faturas para a aba faturada.
@Riverpod(keepAlive: true)
FaturaRepository faturaRepository(Ref ref) =>
    FaturaRepository(ref.watch(bancoProvider));

/// Leitura do à vista para a visão macro.
@Riverpod(keepAlive: true)
MacroRepository macroRepository(Ref ref) =>
    MacroRepository(ref.watch(bancoProvider));

/// Recortes por categoria e visão por tag.
@Riverpod(keepAlive: true)
AnaliseRepository analiseRepository(Ref ref) =>
    AnaliseRepository(ref.watch(bancoProvider));
