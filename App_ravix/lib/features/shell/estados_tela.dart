/// Estados de tela padrão (E01-F02-T04): carregando, vazio e erro.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ravix/core/tema/capra_tokens.dart';
import 'package:ravix/core/tema/icones.dart';
import 'package:ravix/core/tema/tema.dart';

/// Carregamento orbital CAPRA: arco de 2 no acento com um ponto em órbita.
/// Fica parado quando o sistema pede para reduzir animações.
class EstadoCarregando extends StatefulWidget {
  /// Cria o indicador.
  const new({super.key});

  @override
  State<EstadoCarregando> createState() => _EstadoCarregandoState();
}

class _EstadoCarregandoState extends State<EstadoCarregando>
    with SingleTickerProviderStateMixin {
  late final _giro = AnimationController(
    vsync: this,
    duration: CapraTokens.motionLoop,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _giro.stop();
    } else if (!_giro.isAnimating) {
      _giro.repeat();
    }
  }

  @override
  void dispose() {
    _giro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final acento = context.temaRavix.acento;
    return Center(
      child: Semantics(
        label: 'Carregando…',
        child: SizedBox.square(
          dimension: 40,
          child: AnimatedBuilder(
            animation: _giro,
            builder: (context, _) => CustomPaint(
              painter: _OrbitaPainter(acento, _giro.value * 2 * math.pi),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbitaPainter extends CustomPainter {
  new(this.cor, this.angulo);

  final Color cor;
  final double angulo;

  @override
  void paint(Canvas canvas, Size size) {
    final raio = size.shortestSide / 2 - 4;
    final centro = size.center(Offset.zero);
    final traco = Paint()
      ..color = cor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: centro, radius: raio),
      angulo,
      math.pi * 1.4,
      false,
      traco,
    );
    final ponto = angulo + math.pi * 1.7;
    canvas.drawCircle(
      centro + Offset(math.cos(ponto), math.sin(ponto)) * raio,
      3,
      Paint()..color = cor,
    );
  }

  @override
  bool shouldRepaint(_OrbitaPainter old) =>
      old.angulo != angulo || old.cor != cor;
}

/// Estado vazio: fragmento de espiral, título, uma frase e, se houver, uma
/// ação.
class EstadoVazio extends StatelessWidget {
  /// Cria o estado vazio.
  const new({
    required this.titulo,
    required this.mensagem,
    this.rotuloAcao,
    this.aoAgir,
    super.key,
  });

  /// Título em H2.
  final String titulo;

  /// Uma frase explicando o vazio.
  final String mensagem;

  /// Texto do botão de ação; sem ele, não há botão.
  final String? rotuloAcao;

  /// Ação do botão.
  final VoidCallback? aoAgir;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final tema = context.temaRavix;
    return _Centralizado(
      children: [
        ExcludeSemantics(
          child: CustomPaint(
            size: const Size.square(72),
            painter: _EspiralPainter(tema.acento, tema.paleta.borderStrong),
          ),
        ),
        const SizedBox(height: CapraTokens.spaceLg),
        Text(titulo, style: texto.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: CapraTokens.spaceSm),
        Text(
          mensagem,
          style: texto.bodyLarge?.copyWith(color: tema.paleta.textSecondary),
          textAlign: TextAlign.center,
        ),
        if (rotuloAcao != null) ...[
          const SizedBox(height: CapraTokens.spaceLg),
          OutlinedButton(onPressed: aoAgir, child: Text(rotuloAcao!)),
        ],
      ],
    );
  }
}

class _EspiralPainter extends CustomPainter {
  new(this.acento, this.traco);

  final Color acento;
  final Color traco;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    final caminho = Path();
    for (var i = 0; i <= 60; i++) {
      final t = i / 60;
      final angulo = math.pi * (0.6 + 1.5 * t);
      final raio = size.shortestSide * (0.14 + 0.32 * t);
      final p = centro + Offset(math.cos(angulo), math.sin(angulo)) * raio;
      i == 0 ? caminho.moveTo(p.dx, p.dy) : caminho.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      caminho,
      Paint()
        ..color = traco
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
    for (final (t, cor) in [(0.0, traco), (0.5, traco), (1.0, acento)]) {
      final angulo = math.pi * (0.6 + 1.5 * t);
      final raio = size.shortestSide * (0.14 + 0.32 * t);
      canvas.drawCircle(
        centro + Offset(math.cos(angulo), math.sin(angulo)) * raio,
        t == 1 ? 4 : 2.5,
        Paint()..color = cor,
      );
    }
  }

  @override
  bool shouldRepaint(_EspiralPainter old) =>
      old.acento != acento || old.traco != traco;
}

/// Estado de erro: ícone e mensagem em `danger` e a ação de tentar de novo.
class EstadoErro extends StatelessWidget {
  /// Cria o estado de erro.
  const new({
    this.titulo = 'Algo deu errado',
    this.mensagem = 'Não foi possível carregar os dados.',
    this.aoTentarDeNovo,
    super.key,
  });

  /// Título em H2.
  final String titulo;

  /// O que aconteceu e o que fazer.
  final String mensagem;

  /// Ação de tentar de novo; sem ela, não há botão.
  final VoidCallback? aoTentarDeNovo;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final paleta = context.temaRavix.paleta;
    return _Centralizado(
      children: [
        Icon(Icones.circleAlert, size: 40, color: paleta.danger),
        const SizedBox(height: CapraTokens.spaceMd),
        Text(titulo, style: texto.titleLarge, textAlign: TextAlign.center),
        const SizedBox(height: CapraTokens.spaceSm),
        Text(
          mensagem,
          style: texto.bodyLarge?.copyWith(color: paleta.textSecondary),
          textAlign: TextAlign.center,
        ),
        if (aoTentarDeNovo != null) ...[
          const SizedBox(height: CapraTokens.spaceLg),
          OutlinedButton.icon(
            onPressed: aoTentarDeNovo,
            icon: const Icon(Icones.refreshCw, size: CapraTokens.iconSizeMd),
            label: const Text('Tentar de novo'),
          ),
        ],
      ],
    );
  }
}

class _Centralizado extends StatelessWidget {
  const new({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(CapraTokens.spaceXl),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    ),
  );
}

/// Mostra o estado certo de um [AsyncValue]: carregando, erro, vazio ou o
/// conteúdo.
class ConteudoAssincrono<T> extends StatelessWidget {
  /// Cria o seletor de estados.
  const new({
    required this.valor,
    required this.conteudo,
    this.estaVazio,
    this.vazio,
    this.aoTentarDeNovo,
    super.key,
  });

  /// Valor observado.
  final AsyncValue<T> valor;

  /// Conteúdo quando há dados.
  final Widget Function(T dados) conteudo;

  /// Diz se os dados contam como vazio. Sem ele, nunca é vazio.
  final bool Function(T dados)? estaVazio;

  /// Estado vazio a mostrar quando [estaVazio] for verdadeiro.
  final Widget? vazio;

  /// Ação do botão do estado de erro.
  final VoidCallback? aoTentarDeNovo;

  @override
  Widget build(BuildContext context) => switch (valor) {
    AsyncData(:final value) when estaVazio?.call(value) ?? false =>
      vazio ?? const SizedBox.shrink(),
    AsyncData(:final value) => conteudo(value),
    AsyncError() => EstadoErro(aoTentarDeNovo: aoTentarDeNovo),
    _ => const EstadoCarregando(),
  };
}
