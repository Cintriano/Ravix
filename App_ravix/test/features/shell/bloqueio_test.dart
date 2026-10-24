import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ravix/app/dependencias.dart';
import 'package:ravix/features/shell/bloqueio.dart';

import '../../helpers/ambiente_falso.dart';
import '../../helpers/app_de_teste.dart';

class _AuthFalsa extends Mock implements LocalAuthentication;

void main() {
  group('Bloqueio', () {
    late RelogioFixo relogio;
    late ServicoBloqueioFalso servico;
    late ProviderContainer container;

    setUp(() {
      relogio = RelogioFixo(DateTime(2026, 10, 24, 15));
      servico = ServicoBloqueioFalso();
      container = ProviderContainer(
        overrides: [
          relogioProvider.overrideWithValue(relogio),
          servicoBloqueioProvider.overrideWithValue(servico),
        ],
      );
    });
    tearDown(() => container.dispose());

    EstadoBloqueio estado() => container.read(bloqueioProvider);
    Bloqueio controle() => container.read(bloqueioProvider.notifier);

    test('começa bloqueado', () {
      expect(estado().bloqueado, isTrue);
      expect(estado().ultimoResultado, isNull);
    });

    test('sucesso libera', () async {
      await controle().desbloquear();
      expect(estado().bloqueado, isFalse);
      expect(estado().ultimoResultado, ResultadoDesbloqueio.liberado);
    });

    test('cancelamento ou erro mantém bloqueado', () async {
      servico
        ..responderCom(ResultadoDesbloqueio.negado)
        ..responderCom(ResultadoDesbloqueio.falhou);

      await controle().desbloquear();
      expect(estado().bloqueado, isTrue);
      expect(estado().ultimoResultado, ResultadoDesbloqueio.negado);

      await controle().desbloquear();
      expect(estado().bloqueado, isTrue);
      expect(estado().ultimoResultado, ResultadoDesbloqueio.falhou);
    });

    test('aparelho sem credencial libera', () async {
      servico.responderCom(ResultadoDesbloqueio.semCredencial);
      await controle().desbloquear();
      expect(estado().bloqueado, isFalse);
    });

    test('ignora pedidos repetidos enquanto o diálogo está aberto', () async {
      servico.segurar();
      final primeiro = controle().desbloquear();
      await controle().desbloquear();
      servico.soltar();
      await primeiro;
      expect(servico.pedidos, 1);
      expect(estado().bloqueado, isFalse);
    });

    test('não pede de novo se já está desbloqueado', () async {
      await controle().desbloquear();
      await controle().desbloquear();
      expect(servico.pedidos, 1);
    });

    test('volta rápida do segundo plano não bloqueia', () async {
      await controle().desbloquear();
      controle().aoSair();
      relogio.avancar(Bloqueio.tolerancia - const Duration(seconds: 1));
      controle().aoVoltar();
      expect(estado().bloqueado, isFalse);
    });

    test('ficar fora pela tolerância ou mais bloqueia', () async {
      await controle().desbloquear();
      controle().aoSair();
      relogio.avancar(Bloqueio.tolerancia);
      controle().aoVoltar();
      expect(estado().bloqueado, isTrue);
      expect(estado().ultimoResultado, isNull);
    });

    test('voltar sem ter saído não muda nada', () async {
      await controle().desbloquear();
      relogio.avancar(const Duration(hours: 1));
      controle().aoVoltar();
      expect(estado().bloqueado, isFalse);
    });

    test('sair durante o diálogo do sistema não conta', () async {
      servico.segurar();
      final pedido = controle().desbloquear();
      controle().aoSair();
      relogio.avancar(const Duration(minutes: 5));
      servico.soltar();
      await pedido;
      controle().aoVoltar();
      expect(estado().bloqueado, isFalse);
    });
  });

  group('ServicoBloqueioLocalAuth', () {
    late _AuthFalsa auth;
    late ServicoBloqueioLocalAuth servico;

    setUp(() {
      auth = _AuthFalsa();
      servico = ServicoBloqueioLocalAuth(auth: auth);
      when(() => auth.isDeviceSupported()).thenAnswer((_) async => true);
    });

    void autenticarCom(Future<bool> Function() resposta) => when(
      () => auth.authenticate(
        localizedReason: any(named: 'localizedReason'),
        persistAcrossBackgrounding: any(named: 'persistAcrossBackgrounding'),
      ),
    ).thenAnswer((_) => resposta());

    Future<void> falhaCom(
      LocalAuthExceptionCode codigo,
      ResultadoDesbloqueio esperado,
    ) async {
      autenticarCom(() async => throw LocalAuthException(code: codigo));
      expect(await servico.desbloquear(), esperado, reason: codigo.name);
    }

    test('aparelho sem suporte: sem credencial', () async {
      when(() => auth.isDeviceSupported()).thenAnswer((_) async => false);
      expect(await servico.desbloquear(), ResultadoDesbloqueio.semCredencial);
    });

    test('autenticou: liberado; recusou: negado', () async {
      autenticarCom(() async => true);
      expect(await servico.desbloquear(), ResultadoDesbloqueio.liberado);
      autenticarCom(() async => false);
      expect(await servico.desbloquear(), ResultadoDesbloqueio.negado);
    });

    test('pede com motivo e sobrevive ao segundo plano', () async {
      autenticarCom(() async => true);
      await servico.desbloquear();
      verify(
        () => auth.authenticate(
          localizedReason: 'Desbloqueie para abrir o Ravix',
          persistAcrossBackgrounding: true,
        ),
      ).called(1);
    });

    test('traduz os erros do local_auth', () async {
      await falhaCom(
        LocalAuthExceptionCode.noCredentialsSet,
        ResultadoDesbloqueio.semCredencial,
      );
      await falhaCom(
        LocalAuthExceptionCode.noBiometricHardware,
        ResultadoDesbloqueio.semCredencial,
      );
      for (final codigo in [
        LocalAuthExceptionCode.userCanceled,
        LocalAuthExceptionCode.systemCanceled,
        LocalAuthExceptionCode.timeout,
        LocalAuthExceptionCode.userRequestedFallback,
      ]) {
        await falhaCom(codigo, ResultadoDesbloqueio.negado);
      }
      for (final codigo in [
        LocalAuthExceptionCode.temporaryLockout,
        LocalAuthExceptionCode.biometricLockout,
        LocalAuthExceptionCode.deviceError,
        LocalAuthExceptionCode.unknownError,
      ]) {
        await falhaCom(codigo, ResultadoDesbloqueio.falhou);
      }
    });
  });
}
