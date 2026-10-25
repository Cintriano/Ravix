import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';
import 'package:ravix/app.dart';
import 'package:ravix/app/dependencias.dart';
import 'package:ravix/core/tema/tema.dart';
import 'package:ravix/data/banco.dart';
import 'package:ravix/features/shell/bloqueio.dart';

import 'ambiente_falso.dart';
import 'banco_de_teste.dart';

/// Responde com os resultados da fila, na ordem; repete o último. Com
/// [segurar], o próximo pedido só termina quando [soltar] for chamado.
final class ServicoBloqueioFalso implements ServicoBloqueio {
  new([Iterable<ResultadoDesbloqueio> resultados = const []])
    : _fila = Queue.of(resultados);

  final Queue<ResultadoDesbloqueio> _fila;
  ResultadoDesbloqueio _ultimo = ResultadoDesbloqueio.liberado;
  Completer<void>? _trava;

  int pedidos = 0;

  void responderCom(ResultadoDesbloqueio resultado) => _fila.add(resultado);

  void segurar() => _trava = Completer<void>();

  void soltar() => _trava?.complete();

  @override
  Future<ResultadoDesbloqueio> desbloquear() async {
    pedidos++;
    await _trava?.future;
    _trava = null;
    if (_fila.isNotEmpty) _ultimo = _fila.removeFirst();
    return _ultimo;
  }
}

/// Momento padrão dos testes: 24/10/2026, 15h.
final agoraDosTestes = DateTime(2026, 10, 24, 15);

/// Substituições padrão: relógio fixo, banco em memória e bloqueio falso.
List<Override> substituicoes({
  RelogioFixo? relogio,
  ServicoBloqueio? bloqueio,
  BancoRavix? banco,
  List<Override> extras = const [],
}) => [
  ...extras,
  relogioProvider.overrideWithValue(relogio ?? RelogioFixo(agoraDosTestes)),
  geradorUuidProvider.overrideWithValue(GeradorUuidSequencial()),
  fusoProvider.overrideWithValue(FusoFixo(-180)),
  if (banco != null)
    bancoProvider.overrideWithValue(banco)
  else
    bancoProvider.overrideWith((ref) {
      final banco = bancoEmMemoria();
      ref.onDispose(banco.close);
      return banco;
    }),
  servicoBloqueioProvider.overrideWithValue(bloqueio ?? ServicoBloqueioFalso()),
];

/// Monta o app inteiro e espera o desbloqueio inicial.
Future<void> montarApp(
  WidgetTester tester, {
  RelogioFixo? relogio,
  ServicoBloqueio? bloqueio,
  BancoRavix? banco,
  List<Override> extras = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: substituicoes(
        relogio: relogio,
        bloqueio: bloqueio,
        banco: banco,
        extras: extras,
      ),
      child: const RavixApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Desmonta o app e deixa correr o timer com que o drift fecha as consultas
/// observadas. Chame no fim dos testes que mostram dados do banco.
Future<void> encerrarApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

/// `testWidgets` para testes que montam o app inteiro: chama [encerrarApp]
/// no fim, porque a aba À vista observa o banco desde a abertura.
@isTest
void testarApp(
  String descricao,
  Future<void> Function(WidgetTester tester) corpo,
) => testWidgets(descricao, (tester) async {
  await corpo(tester);
  await encerrarApp(tester);
});

/// Envolve [filho] no tema do Ravix, para testar um widget isolado.
Widget comTema(Widget filho, {Brightness brilho = Brightness.dark}) =>
    MaterialApp(
      theme: temaRavix(brilho),
      home: Scaffold(body: filho),
    );
