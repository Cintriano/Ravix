import 'package:ravix/core/ambiente.dart';

/// Relógio parado em [momento]; [avancar] move o ponteiro.
final class RelogioFixo implements Relogio {
  new(this.momento);

  DateTime momento;

  void avancar(Duration duracao) => momento = momento.add(duracao);

  @override
  DateTime agora() => momento;
}

/// UUIDs previsíveis: `00000000-0000-4000-8000-000000000001`, `...002`…
final class GeradorUuidSequencial implements GeradorUuid {
  var _contador = 0;

  @override
  String gerar() {
    _contador++;
    return '00000000-0000-4000-8000-${_contador.toString().padLeft(12, '0')}';
  }
}

/// Fuso fixo em [minutos]; pode ser trocado no meio do teste.
final class FusoFixo implements Fuso {
  new(this.minutos);

  int minutos;

  @override
  int minutosAtuais() => minutos;
}
