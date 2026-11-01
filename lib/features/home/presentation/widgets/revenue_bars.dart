import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../commons/models/dashboard_summary.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';

/// Bars rise from the bottom when the chart appears.
class RevenueBars extends StatelessWidget {
  final List<ChartPoint> points;

  const RevenueBars({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final highest = points.fold<num>(0, (max, p) => p.value > max ? p.value : max);
    final barArea = 96.h;
    return RoundedContainer(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(16.r),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final point in points)
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: highest == 0 ? 0 : point.value / highest),
                    duration: const Duration(milliseconds: 750),
                    curve: Curves.easeOutCubic,
                    builder: (_, share, __) => Container(
                      height: barArea * share + 3.h,
                      margin: EdgeInsets.symmetric(horizontal: 5.w),
                      decoration: BoxDecoration(
                        gradient: AppColors.ribbonGradient,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                    ),
                  ),
                  6.height,
                  Text(point.label, style: text.labelSmall),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
