import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constance/app_colors.dart';
import 'pill_label_shader.dart';

/// Equal segments for use on the blue header, with a white pill that slides.
class SlidingSegment<T> extends StatelessWidget {
  final List<T> items;
  final T selected;
  final String Function(T item) label;
  final ValueChanged<T> onSelect;

  const SlidingSegment({
    super.key,
    required this.items,
    required this.selected,
    required this.label,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge ?? const TextStyle();
    final index = items.indexOf(selected).toDouble();
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Container(
      height: 38.h,
      padding: EdgeInsets.all(3.r),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(99),
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: index, end: index),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        child: Row(
          children: [
            for (final item in items)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (item == selected) return;
                    HapticFeedback.selectionClick();
                    onSelect(item);
                  },
                  child: Center(child: Text(label(item), style: style)),
                ),
              ),
          ],
        ),
        builder: (context, position, labels) {
          final share = 1 / items.length;
          final start = position * share;
          return Stack(
            children: [
              Align(
                alignment: AlignmentDirectional(
                  items.length < 2 ? 0 : -1 + position * (2 / (items.length - 1)),
                  0,
                ),
                child: FractionallySizedBox(
                  widthFactor: share,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) => pillLabelShader(
                  bounds,
                  left: bounds.width * (isRtl ? 1 - start - share : start),
                  right: bounds.width * (isRtl ? 1 - start : start + share),
                  inside: AppColors.brand,
                  outside: Colors.white,
                ),
                child: labels,
              ),
            ],
          );
        },
      ),
    );
  }
}
