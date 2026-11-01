import 'package:flutter/material.dart';

/// Colors tab labels by where the pill is right now, so a label is [inside]
/// only over the pill, even halfway through a slide. [left] and [right] are the
/// pill's edges in the labels' own coordinates.
Shader pillLabelShader(
  Rect bounds, {
  required double left,
  required double right,
  required Color inside,
  required Color outside,
}) {
  final start = (left / bounds.width).clamp(0.0, 1.0);
  final end = (right / bounds.width).clamp(0.0, 1.0);
  return LinearGradient(
    colors: [outside, outside, inside, inside, outside, outside],
    stops: [0, start, start, end, end, 1],
  ).createShader(bounds);
}
