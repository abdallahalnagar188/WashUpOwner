import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constance/app_colors.dart';

/// Progress bar that fills smoothly with the ribbon gradient.
class AnimatedBar extends StatelessWidget {
  final double value;
  final double? height;
  final Color? track;

  const AnimatedBar({super.key, required this.value, this.height, this.track});

  @override
  Widget build(BuildContext context) {
    final h = height ?? 8.h;
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: Container(
        height: h,
        color: track ?? AppColors.primarySoft,
        alignment: AlignmentDirectional.centerStart,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: value.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (_, current, __) => FractionallySizedBox(
            widthFactor: current,
            heightFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.ribbonGradient,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
