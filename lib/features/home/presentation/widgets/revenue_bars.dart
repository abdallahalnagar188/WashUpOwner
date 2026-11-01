import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../commons/models/dashboard_summary.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';

class RevenueBars extends StatelessWidget {
  final List<ChartPoint> points;

  const RevenueBars({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final highest = points.fold<num>(0, (max, p) => p.value > max ? p.value : max);
    final barArea = 96.h;
    return RoundedContainer(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(14.r),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final point in points)
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: highest == 0 ? 2.h : barArea * (point.value / highest) + 2.h,
                    margin: EdgeInsets.symmetric(horizontal: 6.w),
                    decoration: BoxDecoration(
                      gradient: AppColors.ribbonGradient,
                      borderRadius: BorderRadius.circular(6.r),
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
