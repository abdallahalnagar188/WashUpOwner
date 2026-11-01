import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../commons/widgets/effects/pressable.dart';
import '../../../../core/constance/app_colors.dart';

/// A sideways strip of days around today.
class DateStrip extends StatefulWidget {
  static const int daysBefore = 3;
  static const int daysAfter = 30;

  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  const DateStrip({super.key, required this.selected, required this.onSelect});

  @override
  State<DateStrip> createState() => _DateStripState();
}

class _DateStripState extends State<DateStrip> {
  static const double _itemWidth = 56;
  static const double _gap = 8;

  final DateTime _today = DateUtils.dateOnly(DateTime.now());
  late final ScrollController _scroll = ScrollController(
    initialScrollOffset: (DateStrip.daysBefore * (_itemWidth + _gap)).w,
  );

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final lang = Get.locale?.languageCode ?? 'ar';
    return SizedBox(
      height: 70.h,
      child: ListView.separated(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
        itemCount: DateStrip.daysBefore + DateStrip.daysAfter + 1,
        separatorBuilder: (_, __) => SizedBox(width: _gap.w),
        itemBuilder: (_, index) {
          final day = DateUtils.addDaysToDate(_today, index - DateStrip.daysBefore);
          final selected = DateUtils.isSameDay(day, widget.selected);
          final color = selected ? Colors.white : AppColors.ink900;
          return Pressable(
            onTap: () => widget.onSelect(day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: _itemWidth.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: selected ? AppColors.primaryGradient : null,
                color: selected ? null : AppColors.surface,
                borderRadius: BorderRadius.circular(14.r),
                border: selected ? null : Border.all(color: AppColors.line),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    child: Text(
                      DateFormat('EEE', lang).format(day),
                      style: text.labelSmall?.copyWith(color: color),
                    ),
                  ),
                  FittedBox(
                    child: Text(
                      '${day.day}',
                      style: text.titleMedium?.copyWith(color: color),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
