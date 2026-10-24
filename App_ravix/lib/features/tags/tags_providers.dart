import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ravix/app/dependencias.dart';
import 'package:ravix/data/banco.dart';

// Escrito sem @riverpod: o gerador não resolve tipos que vêm do código gerado
// pelo drift (Tag) no mesmo build.

/// Tags ativas em ordem alfabética (aba Tags e seletores do formulário).
final StreamProvider<List<Tag>> tagsAtivasProvider = StreamProvider.autoDispose(
  (ref) => ref.watch(tagRepositoryProvider).observarAtivas(),
);
