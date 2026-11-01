import 'package:flutter/material.dart';

/// Counts up to [value] and glides to new values.
class AnimatedNumber extends StatelessWidget {
  final num value;
  final String Function(num) format;
  final TextStyle? style;

  const AnimatedNumber({
    super.key,
    required this.value,
    required this.format,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: value.toDouble()),
      duration: const Duration(milliseconds: 750),
      curve: Curves.easeOutCubic,
      builder: (_, current, __) => Text(
        format(value is int ? current.round() : current),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }
}
