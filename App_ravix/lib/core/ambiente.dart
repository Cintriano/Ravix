/// Dependências do sistema que os testes substituem por versões falsas:
/// relógio, gerador de UUID e fuso do aparelho.
library;

import 'package:uuid/uuid.dart';

/// Fonte da hora atual.
abstract interface class Relogio {
  /// Momento atual, no horário local do aparelho.
  DateTime agora();
}

/// [Relogio] do sistema.
final class RelogioSistema implements Relogio {
  /// Cria o relógio do sistema.
  const new();

  @override
  DateTime agora() => DateTime.now();
}

/// Gerador das chaves `uuid_*` dos registros do usuário.
abstract interface class GeradorUuid {
  /// Novo UUID v4 em texto, minúsculo e com hífens.
  String gerar();
}

/// [GeradorUuid] com UUID v4 aleatório.
final class GeradorUuidV4 implements GeradorUuid {
  /// Cria o gerador.
  const new();

  static const _uuid = Uuid();

  @override
  String gerar() => _uuid.v4();
}

/// Fuso do aparelho, gravado em `fuso_minutos` (DP-33).
abstract interface class Fuso {
  /// Deslocamento atual em relação ao UTC, em minutos (−180 = UTC−3).
  ///
  /// Vem do sistema, sem rede.
  int minutosAtuais();
}

/// [Fuso] lido do sistema.
final class FusoSistema implements Fuso {
  /// Cria o leitor do fuso do sistema.
  const new();

  @override
  int minutosAtuais() => DateTime.now().timeZoneOffset.inMinutes;
}
