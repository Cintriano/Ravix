import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:ravix/app/dependencias.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bloqueio.g.dart';

/// Resultado de um pedido de desbloqueio.
enum ResultadoDesbloqueio {
  /// O usuário se autenticou.
  liberado,

  /// O usuário cancelou ou errou; o app continua bloqueado.
  negado,

  /// O aparelho não tem PIN, padrão nem biometria. Não há o que proteger
  /// com a credencial do aparelho, então o app abre.
  semCredencial,

  /// Falha temporária (bloqueio por tentativas, sensor indisponível etc.).
  falhou,
}

/// Pede a credencial do próprio aparelho (DP-31). O app não guarda PIN.
abstract interface class ServicoBloqueio {
  /// Mostra o pedido de autenticação do sistema.
  Future<ResultadoDesbloqueio> desbloquear();
}

/// [ServicoBloqueio] sobre o `local_auth`: biometria com alternativa pelo PIN
/// ou padrão do Android.
final class ServicoBloqueioLocalAuth implements ServicoBloqueio {
  /// Cria o serviço. [auth] existe para os testes.
  new({LocalAuthentication? auth}) : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<ResultadoDesbloqueio> desbloquear() async {
    try {
      if (!await _auth.isDeviceSupported()) {
        return ResultadoDesbloqueio.semCredencial;
      }
      final ok = await _auth.authenticate(
        localizedReason: 'Desbloqueie para abrir o Ravix',
        persistAcrossBackgrounding: true,
      );
      return ok ? ResultadoDesbloqueio.liberado : ResultadoDesbloqueio.negado;
    } on LocalAuthException catch (e) {
      return switch (e.code) {
        LocalAuthExceptionCode.noCredentialsSet ||
        LocalAuthExceptionCode.noBiometricHardware =>
          ResultadoDesbloqueio.semCredencial,
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled ||
        LocalAuthExceptionCode.timeout ||
        LocalAuthExceptionCode.userRequestedFallback =>
          ResultadoDesbloqueio.negado,
        _ => ResultadoDesbloqueio.falhou,
      };
    }
  }
}

/// Serviço de bloqueio do app.
@Riverpod(keepAlive: true)
ServicoBloqueio servicoBloqueio(Ref ref) => ServicoBloqueioLocalAuth();

/// Estado do bloqueio local (E01-F01-T07).
@immutable
final class EstadoBloqueio {
  /// Cria o estado.
  const new({required this.bloqueado, this.ultimoResultado});

  /// Se o conteúdo está escondido atrás da tela de bloqueio.
  final bool bloqueado;

  /// Resultado da última tentativa, para a mensagem da tela.
  final ResultadoDesbloqueio? ultimoResultado;
}

/// Bloqueio ao abrir o app e ao voltar depois de [tolerancia] em segundo
/// plano.
@Riverpod(keepAlive: true)
final class Bloqueio extends _$Bloqueio {
  /// Tempo em segundo plano que não pede o PIN de novo. Cobre trocas rápidas
  /// de app e o próprio diálogo do sistema, que tira o app de primeiro plano.
  static const tolerancia = Duration(seconds: 30);

  DateTime? _saiuEm;
  bool _pedindo = false;

  @override
  EstadoBloqueio build() => const EstadoBloqueio(bloqueado: true);

  /// Pede a credencial do aparelho. Ignora chamadas repetidas enquanto o
  /// pedido está aberto.
  Future<void> desbloquear() async {
    if (_pedindo || !state.bloqueado) return;
    _pedindo = true;
    try {
      final resultado = await ref.read(servicoBloqueioProvider).desbloquear();
      final liberou =
          resultado == ResultadoDesbloqueio.liberado ||
          resultado == ResultadoDesbloqueio.semCredencial;
      state = EstadoBloqueio(bloqueado: !liberou, ultimoResultado: resultado);
    } finally {
      _pedindo = false;
    }
  }

  /// O app foi para segundo plano.
  void aoSair() {
    if (_pedindo) return;
    _saiuEm = ref.read(relogioProvider).agora();
  }

  /// O app voltou. Bloqueia se ficou fora por [tolerancia] ou mais.
  void aoVoltar() {
    final saiu = _saiuEm;
    _saiuEm = null;
    if (saiu == null || state.bloqueado) return;
    final fora = ref.read(relogioProvider).agora().difference(saiu);
    if (fora >= tolerancia) {
      state = const EstadoBloqueio(bloqueado: true);
    }
  }
}
