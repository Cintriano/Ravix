import 'package:go_router/go_router.dart';
import 'package:ravix/features/cartoes/tela_cartao.dart';
import 'package:ravix/features/cartoes/tela_cartoes.dart';
import 'package:ravix/features/compra_avista/aba_avista.dart';
import 'package:ravix/features/compra_avista/tela_registro.dart';
import 'package:ravix/features/configuracao/tela_configuracao.dart';
import 'package:ravix/features/renda/tela_renda.dart';
import 'package:ravix/features/shell/shell_ravix.dart';
import 'package:ravix/features/tags/tela_tags.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'rotas.g.dart';

/// Rotas do app. O shell tem um ramo por aba (a ordem é a de `abasDoShell`);
/// formulário e Configuração abrem por cima dele.
@Riverpod(keepAlive: true)
GoRouter rotas(Ref ref) {
  final rotas = GoRouter(
    initialLocation: '/avista',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navegacao) =>
            ShellRavix(navegacao: navegacao),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/avista',
                builder: (context, state) => const AbaAvista(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/registro/novo',
        builder: (context, state) => const TelaRegistro(),
      ),
      GoRoute(
        path: '/registro/:uuid',
        builder: (context, state) =>
            TelaRegistro(uuid: state.pathParameters['uuid']),
      ),
      GoRoute(
        path: '/configuracao',
        builder: (context, state) => const TelaConfiguracao(),
        routes: [
          GoRoute(path: 'tags', builder: (context, state) => const TelaTags()),
          GoRoute(
            path: 'renda',
            builder: (context, state) => const TelaRenda(),
          ),
          GoRoute(
            path: 'cartoes',
            builder: (context, state) => const TelaCartoes(),
            routes: [
              // 'novo' antes de ':uuid', para não ser lido como UUID.
              GoRoute(
                path: 'novo',
                builder: (context, state) => const TelaCartao(),
              ),
              GoRoute(
                path: ':uuid',
                builder: (context, state) =>
                    TelaCartao(uuid: state.pathParameters['uuid']),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(rotas.dispose);
  return rotas;
}
