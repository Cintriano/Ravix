import 'package:flutter/material.dart';

import '../widgets/ravix_brand.dart' show RavixLogoTone;
import 'ravix_motion.dart';

/// O que a marca faz.
enum RavixMarkMotion {
  /// Abertura: haste desce, seta sobe, letras sobem (só no logotipo). Roda uma vez.
  intro,

  /// Confirmação (gasto salvo): a seta sai pelo canto superior direito e outra entra por baixo.
  confirm,

  /// Carregando: a mesma passagem da seta, em laço.
  loop,
}

/// Símbolo ou logotipo animado, desenhado por vetores (sem arquivos SVG).
///
/// Substitui o [RavixSymbol] / [RavixLogo] quando houver movimento. Para o estado
/// final estático, os dois continuam valendo.
///
/// ```dart
/// const RavixMark.logo(height: 48, motion: RavixMarkMotion.intro)
/// const RavixMark.symbol(height: 24, motion: RavixMarkMotion.loop)
/// ```
class RavixMark extends StatefulWidget {
  const RavixMark.symbol({
    super.key,
    this.height = 32,
    this.motion = RavixMarkMotion.intro,
    this.tone = RavixLogoTone.auto,
    this.onCompleted,
  }) : withWordmark = false;

  const RavixMark.logo({
    super.key,
    this.height = 32,
    this.motion = RavixMarkMotion.intro,
    this.tone = RavixLogoTone.auto,
    this.onCompleted,
  }) : withWordmark = true;

  final bool withWordmark;
  final double height;
  final RavixMarkMotion motion;
  final RavixLogoTone tone;

  /// Chamado ao fim de `intro` e `confirm`. Nunca no `loop`.
  final VoidCallback? onCompleted;

  @override
  State<RavixMark> createState() => RavixMarkState();
}

class RavixMarkState extends State<RavixMark> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  bool _started = false;

  /// Duração total (ms) de cada movimento. Os tempos de cada peça estão no painter.
  static const _intro = 1290; // última letra: 520 + 3*70 + 560
  static const _introSymbol = 1140; // seta: 240 + 900
  static const _confirm = 420;
  static const _loop = 1200;

  int get _totalMs => switch (widget.motion) {
        RavixMarkMotion.intro => widget.withWordmark ? _intro : _introSymbol,
        RavixMarkMotion.confirm => _confirm,
        RavixMarkMotion.loop => _loop,
      };

  /// Roda de novo (por exemplo, a cada gasto salvo).
  void replay() {
    _c.duration = Duration(milliseconds: _totalMs);
    if (RavixMotion.reduced(context)) {
      _c.value = 1;
      widget.onCompleted?.call();
      return;
    }
    if (widget.motion == RavixMarkMotion.loop) {
      _c.repeat();
    } else {
      _c.forward(from: 0).whenComplete(() {
        if (mounted) widget.onCompleted?.call();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      replay();
    }
  }

  @override
  void didUpdateWidget(RavixMark old) {
    super.didUpdateWidget(old);
    if (old.motion != widget.motion) replay();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = switch (widget.tone) {
      RavixLogoTone.auto => Theme.of(context).brightness == Brightness.dark,
      RavixLogoTone.positivo => false,
      RavixLogoTone.negativo => true,
    };
    final ink = dark ? const Color(0xFFEEF4F0) : const Color(0xFF163730);
    final arrow = dark ? const Color(0xFF78CFA5) : const Color(0xFF3FB282);

    final box = widget.withWordmark ? _logoBox : _symbolBox;
    final width = widget.height * box.width / box.height;

    return Semantics(
      label: 'Ravix',
      image: true,
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, __) => CustomPaint(
              size: Size(width, widget.height),
              painter: _MarkPainter(
                t: _c.value * _totalMs,
                withWordmark: widget.withWordmark,
                motion: widget.motion,
                ink: ink,
                arrow: arrow,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Geometria (unidades da fonte; linha de base em y = 0; ponta da seta em y = -712)
// ---------------------------------------------------------------------------

const _symbolBox = Rect.fromLTWH(5, -712, 595, 712);
const _logoBox = Rect.fromLTWH(65, -712, 2487, 712);
const _symbolOffsetInLogo = 1952.0;

Path _poly(List<double> p) {
  final path = Path()..moveTo(p[0], p[1]);
  for (var i = 2; i < p.length; i += 2) {
    path.lineTo(p[i], p[i + 1]);
  }
  return path..close();
}

final Path _stemA = _poly([10, -498, 159, -498, 245.4, -379.8, 170.9, -277.8]);
final Path _stemB = _poly([357.1, -227, 523, 0, 374, 0, 282.6, -125.1]);
final Path _arrow = _poly([5, 0, 154, 0, 536.4, -523.1, 594.4, -480.7, 599.9, -712, 381.2, -636.5, 439.2, -594.1]);

// Letras R, a, v, i do logotipo. Só usam M, H, V, L e Z (traços retos).
const _letterData = [
  'M615 -232V0H479V-201L419 -268H201V0H65V-700H504L611 -592V-380L543 -311ZM201 -380H442L477 -415V-551L442 -586H201Z',
  'M700 -92V-206L792 -298H1045V-361L1014 -392H864L834 -361V-333H704V-390L811 -498H1068L1175 -390V0H1056V-71L982 0H792ZM973 -102 1045 -171V-204H857L830 -177V-127L855 -102Z',
  'M1210 -498H1347L1463 -151H1467L1583 -498H1720L1529 0H1401Z',
  'M1755 -602V-666L1801 -712H1871L1917 -666V-602L1871 -556H1801ZM1770 -498H1902V0H1770Z',
];

Path _parse(String d) {
  final path = Path();
  final tokens = RegExp(r'[MLHVZ]|-?\d+(?:\.\d+)?').allMatches(d).map((m) => m[0]!).toList();
  var i = 0;
  var x = 0.0, y = 0.0;
  String cmd = 'M';
  double n() => double.parse(tokens[i++]);
  while (i < tokens.length) {
    final t = tokens[i];
    if (RegExp(r'[MLHVZ]').hasMatch(t)) {
      cmd = t;
      i++;
      if (cmd == 'Z') {
        path.close();
        continue;
      }
    }
    switch (cmd) {
      case 'M':
        x = n();
        y = n();
        path.moveTo(x, y);
        cmd = 'L';
      case 'L':
        x = n();
        y = n();
        path.lineTo(x, y);
      case 'H':
        x = n();
        path.lineTo(x, y);
      case 'V':
        y = n();
        path.lineTo(x, y);
    }
  }
  return path;
}

final List<Path> _letters = _letterData.map(_parse).toList();

/// Eixo da seta: ela percorre (382, -523) e nasce abaixo da linha de base.
const _riseFrom = Offset(-535, 732);
const _passTo = Offset(535, -732);

class _MarkPainter extends CustomPainter {
  _MarkPainter({
    required this.t,
    required this.withWordmark,
    required this.motion,
    required this.ink,
    required this.arrow,
  });

  final double t; // ms desde o início do movimento
  final bool withWordmark;
  final RavixMarkMotion motion;
  final Color ink;
  final Color arrow;

  /// Progresso 0..1 de uma peça que começa em [delay] e dura [dur] ms.
  double _p(double delay, double dur) =>
      RavixMotion.curve.transform(((t - delay) / dur).clamp(0.0, 1.0));

  void _draw(Canvas canvas, Path path, Color color, {Offset shift = Offset.zero, double opacity = 1}) {
    canvas.save();
    canvas.translate(shift.dx, shift.dy);
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: opacity)..isAntiAlias = true);
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final box = withWordmark ? _logoBox : _symbolBox;
    final s = size.height / 712;
    canvas.clipRect(Offset.zero & size); // a base do quadro é a linha de base: o que passa dela some
    canvas.scale(s);
    canvas.translate(-box.left, 712);

    if (withWordmark) {
      final intro = motion == RavixMarkMotion.intro;
      for (var i = 0; i < _letters.length; i++) {
        final p = intro ? _p(520 + i * 70, 560) : 1.0;
        _draw(canvas, _letters[i], ink, shift: Offset(0, 720 * (1 - p)));
      }
      canvas.translate(_symbolOffsetInLogo, 0);
    }

    switch (motion) {
      case RavixMarkMotion.intro:
        final a = _p(0, 420), b = _p(90, 420), r = _p(240, 900);
        _draw(canvas, _stemA, ink, shift: Offset(-70 * (1 - a), -98 * (1 - a)), opacity: a);
        _draw(canvas, _stemB, ink, shift: Offset(-70 * (1 - b), -98 * (1 - b)), opacity: b);
        _draw(canvas, _arrow, arrow, shift: _riseFrom * (1 - r));
      case RavixMarkMotion.confirm:
        final p = _p(0, 420);
        _draw(canvas, _stemA, ink);
        _draw(canvas, _stemB, ink);
        _draw(canvas, _arrow, arrow, shift: _passTo * p);
        _draw(canvas, _arrow, arrow, shift: _riseFrom * (1 - p));
      case RavixMarkMotion.loop:
        // 0–12% parada, 12–60% passagem, 60–100% parada (igual ao CSS)
        final x = ((t / 1200 - .12) / .48).clamp(0.0, 1.0);
        final p = RavixMotion.curve.transform(x);
        _draw(canvas, _stemA, ink);
        _draw(canvas, _stemB, ink);
        _draw(canvas, _arrow, arrow, shift: _passTo * p);
        _draw(canvas, _arrow, arrow, shift: _riseFrom * (1 - p));
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) =>
      old.t != t || old.motion != motion || old.ink != ink || old.arrow != arrow || old.withWordmark != withWordmark;
}
