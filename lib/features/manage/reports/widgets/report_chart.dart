import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../commons/models/vendor_report.dart';
import '../../../../commons/widgets/effects/animated_bar.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import 'report_value.dart';

/// Rising columns for a run of days, labelled bars for a few categories.
class ReportChart extends StatelessWidget {
  static const int _maxBars = 8;

  final List<ReportPoint> points;
  final String format;

  const ReportChart({super.key, required this.points, required this.format});

  num get _highest => points.fold<num>(0, (max, p) => p.value > max ? p.value : max);

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return empty;
    return points.length > _maxBars ? _columns(context) : _bars(context);
  }

  Widget _bars(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final highest = _highest;
    return Column(
      children: [
        for (final point in points)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 5.h),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: Text(point.label, style: text.bodySmall)),
                    8.width,
                    Text(reportValue(point.value, format), style: text.labelMedium),
                  ],
                ),
                4.height,
                AnimatedBar(value: highest == 0 ? 0 : point.value / highest),
              ],
            ),
          ),
      ],
    );
  }

  Widget _columns(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final highest = _highest;
    final area = 110.h;
    final labelEvery = (points.length / 5).ceil();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(reportValue(highest, format), style: text.labelSmall),
        6.height,
        SizedBox(
          height: area,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final point in points)
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: highest == 0 ? 0 : point.value / highest),
                    duration: const Duration(milliseconds: 750),
                    curve: Curves.easeOutCubic,
                    builder: (_, share, __) => Container(
                      height: (area - 3.h) * share + 3.h,
                      margin: EdgeInsets.symmetric(horizontal: 1.5.w),
                      decoration: BoxDecoration(
                        gradient: AppColors.ribbonGradient,
                        borderRadius: BorderRadius.circular(3.r),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        6.height,
        Row(
          children: [
            for (var i = 0; i < points.length; i += labelEvery)
              Expanded(
                child: Text(
                  points[i].label,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: text.labelSmall,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
