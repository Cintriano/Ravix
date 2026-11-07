import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Cantos chanfrados a 45°, o mesmo corte das letras e do símbolo.
abstract final class RavixShapes {
  /// Chips, ícone de categoria.
  static const double p = 4;

  /// Botões, campos.
  static const double m = 8;

  /// Cards, FAB, card de resumo, folhas.
  static const double g = 12;

  static BeveledRectangleBorder cut(double size, {BorderSide side = BorderSide.none}) =>
      BeveledRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(size)), side: side);

  static BeveledRectangleBorder cutTop(double size, {BorderSide side = BorderSide.none}) =>
      BeveledRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(size)), side: side);
}

/// Borda chanfrada para campos de texto ([InputDecoration]).
///
/// Funciona como borda "preenchida": o rótulo flutua dentro do campo,
/// como nas telas do Ravix. Use com `filled: true`.
class RavixCutInputBorder extends InputBorder {
  const RavixCutInputBorder({super.borderSide = const BorderSide(), this.cut = RavixShapes.m});

  final double cut;

  @override
  bool get isOutline => false;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(borderSide.width);

  @override
  RavixCutInputBorder copyWith({BorderSide? borderSide, double? cut}) =>
      RavixCutInputBorder(borderSide: borderSide ?? this.borderSide, cut: cut ?? this.cut);

  @override
  ShapeBorder scale(double t) => RavixCutInputBorder(borderSide: borderSide.scale(t), cut: cut * t);

  Path _path(Rect r) {
    final c = math.max(0.0, math.min(cut, math.min(r.width, r.height) / 2));
    return Path()
      ..moveTo(r.left + c, r.top)
      ..lineTo(r.right - c, r.top)
      ..lineTo(r.right, r.top + c)
      ..lineTo(r.right, r.bottom - c)
      ..lineTo(r.right - c, r.bottom)
      ..lineTo(r.left + c, r.bottom)
      ..lineTo(r.left, r.bottom - c)
      ..lineTo(r.left, r.top + c)
      ..close();
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => _path(rect.deflate(borderSide.width));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect);

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    if (borderSide.style == BorderStyle.none || borderSide.width == 0) return;
    canvas.drawPath(_path(rect.deflate(borderSide.width / 2)), borderSide.toPaint());
  }

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is RavixCutInputBorder) {
      return RavixCutInputBorder(
        borderSide: BorderSide.lerp(a.borderSide, borderSide, t),
        cut: lerpDouble(a.cut, cut, t)!,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is RavixCutInputBorder) {
      return RavixCutInputBorder(
        borderSide: BorderSide.lerp(borderSide, b.borderSide, t),
        cut: lerpDouble(cut, b.cut, t)!,
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  bool operator ==(Object other) =>
      other is RavixCutInputBorder && other.borderSide == borderSide && other.cut == cut;

  @override
  int get hashCode => Object.hash(borderSide, cut);
}
