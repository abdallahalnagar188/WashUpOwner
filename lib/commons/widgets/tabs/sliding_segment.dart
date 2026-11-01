import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constance/app_colors.dart';

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
    final index = items.indexOf(selected);
    return Container(
      height: 38.h,
      padding: EdgeInsets.all(3.r),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: AlignmentDirectional(
              items.length < 2 ? 0 : -1 + index * (2 / (items.length - 1)),
              0,
            ),
            child: FractionallySizedBox(
              widthFactor: 1 / items.length,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
          Row(
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
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: style.copyWith(
                          color: item == selected ? AppColors.brand : Colors.white,
                        ),
                        child: Text(label(item)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
