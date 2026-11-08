import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ravix/app/dependencias.dart';
import 'package:ravix/app/preferencias.dart';
import 'package:ravix/app/rotas.dart';
import 'package:ravix/core/tema/tema.dart';
import 'package:ravix/features/shell/bloqueio.dart';
import 'package:ravix/features/shell/tela_bloqueio.dart';

/// Raiz do app: identidade v2 na aparência escolhida, português, rotas e
/// bloqueio local.
class RavixApp extends ConsumerStatefulWidget {
  /// Cria a raiz do app.
  const new({super.key});

  @override
  ConsumerState<RavixApp> createState() => _RavixAppState();
}

class _RavixAppState extends ConsumerState<RavixApp> {
  late final AppLifecycleListener _ciclo;

  @override
  void initState() {
    super.initState();
    final bloqueio = ref.read(bloqueioProvider.notifier);
    _ciclo = AppLifecycleListener(
      onHide: bloqueio.aoSair,
      onShow: () {
        bloqueio.aoVoltar();
        unawaited(_lancarRecorrencias());
      },
    );
    unawaited(_lancarRecorrencias());
  }

  /// As cobranças recorrentes do cartão viram lançamento sozinhas no dia
  /// (DP-25). Roda ao abrir e ao voltar para o app; uma falha aqui não pode
  /// impedir o uso, então só tenta de novo na próxima vez.
  Future<void> _lancarRecorrencias() async {
    try {
      await ref.read(recorrenciaRepositoryProvider).materializarFaturadas();
    } on Exception catch (erro) {
      debugPrint('Recorrências do cartão não lançadas: $erro');
    }
  }

  @override
  void dispose() {
    _ciclo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloqueado = ref.watch(bloqueioProvider.select((e) => e.bloqueado));
    return MaterialApp.router(
      title: 'Ravix',
      debugShowCheckedModeBanner: false,
      theme: temaRavix(Brightness.light),
      darkTheme: temaRavix(Brightness.dark),
      themeMode: ref.watch(aparenciaEscolhidaProvider).modo,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: ref.watch(rotasProvider),
      // O conteúdo fica montado (e escondido) atrás do bloqueio, para não
      // perder a navegação ao desbloquear.
      builder: (context, conteudo) => Stack(
        children: [
          Offstage(
            offstage: bloqueado,
            child: TickerMode(enabled: !bloqueado, child: conteudo!),
          ),
          if (bloqueado) const TelaBloqueio(),
        ],
      ),
    );
  }
}
