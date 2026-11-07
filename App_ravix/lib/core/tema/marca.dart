/// Logotipo e símbolo do Ravix desenhados por vetores, com a animação de
/// abertura da marca (`docs/identidade_visual/v2/motion`).
///
/// A geometria vem dos contornos da Chakra Petch Bold, em unidades da fonte
/// (linha de base em y = 0, ponta da seta em y = -712).
library;

import 'package:flutter/material.dart';
import 'package:ravix/core/tema/tokens.dart';

/// Marca do Ravix: logotipo completo ou só o símbolo (o x com a seta).
///
/// Com [animar], roda a abertura uma vez: a haste desce, a seta sobe e as
/// letras sobem da linha de base. Respeita o "reduzir movimento" do sistema.
class MarcaRavix extends StatefulWidget {
  /// Logotipo completo.
  const new logo({
    super.key,
    this.altura = 32,
    this.negativo,
    this.animar = false,
  }) : _comLetras = true,
       emLaco = false;

  /// Só o símbolo.
  const new simbolo({
    super.key,
    this.altura = 32,
    this.negativo,
    this.animar = false,
    this.emLaco = false,
  }) : _comLetras = false;

  final bool _comLetras;

  /// Altura em dp (mínimo de 24 para o logotipo).
  final double altura;

  /// Versão para fundo escuro (Névoa e Menta). Nulo segue o tema.
  final bool? negativo;

  /// Roda a abertura ao aparecer.
  final bool animar;

  /// Carregando: a seta sai pelo canto e outra entra por baixo, em laço.
  /// Fica parado quando o sistema pede para reduzir movimento.
  final bool emLaco;

  @override
  State<MarcaRavix> createState() => _MarcaRavixState();
}

class _MarcaRavixState extends State<MarcaRavix>
    with SingleTickerProviderStateMixin {
  // Última letra: 520 + 3 × 70 + 560. Só o símbolo: seta em 240 + 900.
  int get _totalMs => widget.emLaco
      ? 1200
      : widget._comLetras
      ? 1290
      : 1140;

  late final _controle = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _totalMs),
    value: widget.animar ? 0 : 1,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ajustar();
  }

  @override
  void didUpdateWidget(MarcaRavix antigo) {
    super.didUpdateWidget(antigo);
    if (antigo.emLaco != widget.emLaco ||
        antigo._comLetras != widget._comLetras) {
      _controle
        ..stop()
        ..duration = Duration(milliseconds: _totalMs)
        ..value = widget.emLaco ? 0 : 1;
      _ajustar();
    }
  }

  void _ajustar() {
    final reduzir = MediaQuery.disableAnimationsOf(context);
    if (widget.emLaco) {
      if (reduzir) {
        _controle
          ..stop()
          ..value = 0;
      } else if (!_controle.isAnimating) {
        _controle.repeat();
      }
    } else if (_controle.value == 0 && !_controle.isAnimating) {
      if (reduzir) {
        _controle.value = 1;
      } else {
        _controle.forward();
      }
    }
  }

  @override
  void dispose() {
    _controle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final escuro =
        widget.negativo ?? Theme.of(context).brightness == Brightness.dark;
    final caixa = widget._comLetras ? _caixaLogo : _caixaSimbolo;
    return Semantics(
      label: 'Ravix',
      image: true,
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controle,
            builder: (_, _) => CustomPaint(
              size: Size(
                widget.altura * caixa.width / caixa.height,
                widget.altura,
              ),
              painter: _PintorDaMarca(
                ms: _controle.value * _totalMs,
                comLetras: widget._comLetras,
                emLaco: widget.emLaco,
                tinta: escuro ? CoresRavix.nevoa : CoresRavix.floresta,
                seta: escuro ? CoresRavix.menta : CoresRavix.menta600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const _caixaSimbolo = Rect.fromLTWH(5, -712, 595, 712);
const _caixaLogo = Rect.fromLTWH(65, -712, 2487, 712);
const _simboloNoLogo = 1952.0;

Path _poligono(List<double> p) {
  final caminho = Path()..moveTo(p[0], p[1]);
  for (var i = 2; i < p.length; i += 2) {
    caminho.lineTo(p[i], p[i + 1]);
  }
  return caminho..close();
}

final Path _hasteA = _poligono([
  10,
  -498,
  159,
  -498,
  245.4,
  -379.8,
  170.9,
  -277.8,
]);
final Path _hasteB = _poligono([357.1, -227, 523, 0, 374, 0, 282.6, -125.1]);
final Path _seta = _poligono([
  5, 0, 154, 0, 536.4, -523.1, 594.4, -480.7, //
  599.9, -712, 381.2, -636.5, 439.2, -594.1,
]);

// Letras R, a, v, i. Só usam M, H, V, L e Z (traços retos).
const _letrasSvg = [
  [
    'M615 -232V0H479V-201L419 -268H201V0H65V-700H504L611 -592V-380L543 -311Z',
    'M201 -380H442L477 -415V-551L442 -586H201Z',
  ],
  [
    'M700 -92V-206L792 -298H1045V-361L1014 -392H864L834 -361V-333H704V-390',
    'L811 -498H1068L1175 -390V0H1056V-71L982 0H792Z',
    'M973 -102 1045 -171V-204H857L830 -177V-127L855 -102Z',
  ],
  ['M1210 -498H1347L1463 -151H1467L1583 -498H1720L1529 0H1401Z'],
  [
    'M1755 -602V-666L1801 -712H1871L1917 -666V-602L1871 -556H1801Z',
    'M1770 -498H1902V0H1770Z',
  ],
];

Path _lerSvg(String d) {
  final caminho = Path();
  final partes = RegExp(r'[MLHVZ]|-?\d+(?:\.\d+)?')
      .allMatches(d)
      .map((m) => m[0]!)
      .toList();
  var i = 0;
  var x = 0.0;
  var y = 0.0;
  var comando = 'M';
  double numero() => double.parse(partes[i++]);
  while (i < partes.length) {
    final parte = partes[i];
    if ('MLHVZ'.contains(parte)) {
      comando = parte;
      i++;
      if (comando == 'Z') {
        caminho.close();
        continue;
      }
    }
    switch (comando) {
      case 'M':
        x = numero();
        y = numero();
        caminho.moveTo(x, y);
        comando = 'L';
      case 'L':
        x = numero();
        y = numero();
        caminho.lineTo(x, y);
      case 'H':
        x = numero();
        caminho.lineTo(x, y);
      case 'V':
        y = numero();
        caminho.lineTo(x, y);
    }
  }
  return caminho;
}

final List<Path> _letras = [
  for (final partes in _letrasSvg) _lerSvg(partes.join(' ')),
];

/// A seta nasce abaixo da linha de base, pelo próprio eixo.
const _subidaDaSeta = Offset(-535, 732);

/// No laço, a seta sai pelo canto superior direito.
const _saidaDaSeta = Offset(535, -732);

class _PintorDaMarca extends CustomPainter {
  new({
    required this.ms,
    required this.comLetras,
    required this.emLaco,
    required this.tinta,
    required this.seta,
  });

  final double ms;
  final bool comLetras;
  final bool emLaco;
  final Color tinta;
  final Color seta;

  /// Progresso de 0 a 1 de uma peça que começa em [atraso] e dura [duracao].
  double _p(double atraso, double duracao) =>
      TokensRavix.curva.transform(((ms - atraso) / duracao).clamp(0.0, 1.0));

  void _desenhar(
    Canvas canvas,
    Path caminho,
    Color cor, {
    Offset desvio = Offset.zero,
    double opacidade = 1,
  }) {
    canvas
      ..save()
      ..translate(desvio.dx, desvio.dy)
      ..drawPath(caminho, Paint()..color = cor.withValues(alpha: opacidade))
      ..restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final caixa = comLetras ? _caixaLogo : _caixaSimbolo;
    // A base do quadro é a linha de base: o que passa dela some.
    canvas
      ..clipRect(Offset.zero & size)
      ..scale(size.height / 712)
      ..translate(-caixa.left, 712);

    if (comLetras) {
      for (var i = 0; i < _letras.length; i++) {
        final p = _p(520 + i * 70.0, 560);
        _desenhar(canvas, _letras[i], tinta, desvio: Offset(0, 720 * (1 - p)));
      }
      canvas.translate(_simboloNoLogo, 0);
    }

    if (emLaco) {
      // 0–12% parada, 12–60% passagem, 60–100% parada.
      final p = TokensRavix.curva.transform(
        ((ms / 1200 - 0.12) / 0.48).clamp(0.0, 1.0),
      );
      _desenhar(canvas, _hasteA, tinta);
      _desenhar(canvas, _hasteB, tinta);
      _desenhar(canvas, _seta, seta, desvio: _saidaDaSeta * p);
      _desenhar(canvas, _seta, seta, desvio: _subidaDaSeta * (1 - p));
      return;
    }

    final a = _p(0, 420);
    final b = _p(90, 420);
    final r = _p(240, 900);
    _desenhar(
      canvas,
      _hasteA,
      tinta,
      desvio: Offset(-70 * (1 - a), -98 * (1 - a)),
      opacidade: a,
    );
    _desenhar(
      canvas,
      _hasteB,
      tinta,
      desvio: Offset(-70 * (1 - b), -98 * (1 - b)),
      opacidade: b,
    );
    _desenhar(canvas, _seta, seta, desvio: _subidaDaSeta * (1 - r));
  }

  @override
  bool shouldRepaint(_PintorDaMarca old) =>
      old.ms != ms ||
      old.emLaco != emLaco ||
      old.tinta != tinta ||
      old.seta != seta ||
      old.comLetras != comLetras;
}
