import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ravix/app/dependencias.dart';
import 'package:ravix/data/banco.dart';

// Escrito sem @riverpod: o gerador não resolve tipos que vêm do código gerado
// pelo drift (CartaoCredito) no mesmo build.

/// Cartões ativos em ordem alfabética (Configuração e seletores).
final StreamProvider<List<CartaoCredito>> cartoesAtivosProvider =
    StreamProvider.autoDispose(
      (ref) => ref.watch(cartaoRepositoryProvider).observarAtivos(),
    );
