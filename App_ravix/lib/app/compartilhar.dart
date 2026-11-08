import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

/// Abre o compartilhamento do sistema para um arquivo.
abstract interface class Compartilhador {
  /// Oferece [arquivo] ao usuário (Drive, e-mail, Arquivos…).
  Future<void> compartilharArquivo(File arquivo, {required String assunto});
}

/// Compartilhamento do Android, via `share_plus`.
final class CompartilhadorSistema implements Compartilhador {
  /// Cria o compartilhador.
  const new();

  @override
  Future<void> compartilharArquivo(
    File arquivo, {
    required String assunto,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(arquivo.path, mimeType: 'application/vnd.sqlite3')],
        // Sem isso, alguns destinos (Drive) usam o assunto como nome do
        // arquivo e perdem a data e a extensão.
        fileNameOverrides: [p.basename(arquivo.path)],
        subject: assunto,
      ),
    );
  }
}
