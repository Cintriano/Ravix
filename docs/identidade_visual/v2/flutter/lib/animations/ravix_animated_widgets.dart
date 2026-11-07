import 'package:flutter/material.dart';

import '../theme/ravix_theme.dart';
import '../widgets/ravix_brand.dart';
import 'ravix_motion.dart';

/// Valor em dinheiro que conta até o novo valor (ênfase, 420 ms).
/// Na primeira vez conta a partir de zero; nas seguintes, a partir do valor anterior.
class RavixCountUp extends StatelessWidget {
  const RavixCountUp({
    super.key,
    required this.value,
    required this.style,
    this.duration = RavixMotion.enfase,
    this.prefix = '',
    this.formatter = formatBRLNumber,
  });

  final double value;
  final TextStyle style;
  final Duration duration;

  /// Texto fixo antes do número, por exemplo `R$ `.
  final String prefix;
  final String Function(num) formatter;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value),
      duration: RavixMotion.of(context, duration),
      curve: RavixMotion.curve,
      builder: (_, v, __) => Text('$prefix${formatter(v)}', style: style),
    );
  }
}

/// Barra do orçamento: cresce da esquerda e muda de cor nos limites (80% e 100%).
/// Sem tremor nem piscada: o app não julga o gasto.
class RavixBudgetBar extends StatelessWidget {
  const RavixBudgetBar({super.key, required this.ratio, this.height = 8});

  /// 0.58 = 58% do orçamento usado. Acima de 1 a barra fica cheia e vermelha.
  final double ratio;
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = context.ravix;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: ratio),
      duration: RavixMotion.of(context, RavixMotion.enfase),
      curve: RavixMotion.curve,
      builder: (_, r, __) => TweenAnimationBuilder<Color?>(
        tween: ColorTween(end: t.budgetColor(ratio)),
        duration: RavixMotion.of(context, RavixMotion.padrao),
        builder: (_, color, __) => SizedBox(
          height: height,
          child: ColoredBox(
            color: t.summaryTrack,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: r.clamp(0.0, 1.0),
                child: ColoredBox(color: color ?? t.ok, child: const SizedBox.expand()),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Entrada de uma linha de lista: sobe 10 dp e aparece (220 ms), com 40 ms de
/// defasagem por posição. Anima só na primeira vez que o item é construído.
class RavixEnter extends StatefulWidget {
  const RavixEnter({super.key, required this.child, this.index = 0, this.fromTop = false});

  final Widget child;

  /// Posição na lista, para a defasagem. Limite prático: 10 (depois disso, sem atraso extra).
  final int index;

  /// Gasto novo entra de cima em vez de subir.
  final bool fromTop;

  @override
  State<RavixEnter> createState() => _RavixEnterState();
}

class _RavixEnterState extends State<RavixEnter> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: RavixMotion.padrao);
  late final CurvedAnimation _a = CurvedAnimation(parent: _c, curve: RavixMotion.curve);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.isAnimating || _c.isCompleted) return;
    if (RavixMotion.reduced(context)) {
      _c.value = 1;
      return;
    }
    final delay = RavixMotion.stagger * widget.index.clamp(0, 10);
    Future.delayed(delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _a.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dy = widget.fromTop ? -10.0 : 10.0;
    return AnimatedBuilder(
      animation: _a,
      child: widget.child,
      builder: (_, child) => Opacity(
        opacity: _a.value,
        child: Transform.translate(offset: Offset(0, dy * (1 - _a.value)), child: child),
      ),
    );
  }
}

/// Botão com o toque do Ravix: aperta para 97% em 120 ms.
class RavixPress extends StatefulWidget {
  const RavixPress({super.key, required this.child});
  final Widget child;

  @override
  State<RavixPress> createState() => _RavixPressState();
}

class _RavixPressState extends State<RavixPress> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _down = true),
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? .97 : 1,
        duration: RavixMotion.of(context, RavixMotion.rapido),
        curve: RavixMotion.curve,
        child: widget.child,
      ),
    );
  }
}

/// Troca de mês: o conteúdo antigo sai e o novo entra pelo lado (220 ms).
/// [forward] = true quando vai para o mês seguinte.
class RavixMonthSwitcher extends StatelessWidget {
  const RavixMonthSwitcher({super.key, required this.monthKey, required this.child, this.forward = true});

  final Object monthKey;
  final Widget child;
  final bool forward;

  @override
  Widget build(BuildContext context) {
    final dir = forward ? 1.0 : -1.0;
    return AnimatedSwitcher(
      duration: RavixMotion.of(context, RavixMotion.padrao),
      switchInCurve: RavixMotion.curve,
      switchOutCurve: RavixMotion.curve,
      transitionBuilder: (w, a) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween(begin: Offset(.08 * dir, 0), end: Offset.zero).animate(a),
          child: w,
        ),
      ),
      child: KeyedSubtree(key: ValueKey(monthKey), child: child),
    );
  }
}
