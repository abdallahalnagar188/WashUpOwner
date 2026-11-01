import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/staff_member.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../common/widgets/manage_sheets.dart';
import '../controllers/staff_controller.dart';

class _Pattern {
  String start;
  String end;
  final Set<int> days;

  _Pattern(this.start, this.end, this.days);
}

/// Weekly shifts of one member; each row is a time range on chosen days.
class StaffScheduleSheet extends StatefulWidget {
  final StaffMember member;

  const StaffScheduleSheet({super.key, required this.member});

  @override
  State<StaffScheduleSheet> createState() => _StaffScheduleSheetState();
}

class _StaffScheduleSheetState extends State<StaffScheduleSheet> {
  late final List<_Pattern> _patterns = [
    for (final shift in widget.member.scheduledShifts) _Pattern(shift.start, shift.end, {...shift.days}),
  ];

  /// Midnight as an end time means the end of the day.
  static int _minutes(String clock, {bool end = false}) {
    final parts = clock.split(':');
    if (parts.length != 2) return -1;
    final total = (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
    return end && total == 0 ? 1440 : total;
  }

  bool _rowOk(_Pattern pattern) =>
      pattern.days.isNotEmpty && _minutes(pattern.end, end: true) > _minutes(pattern.start);

  bool get _overlap {
    for (var a = 0; a < _patterns.length; a++) {
      for (var b = a + 1; b < _patterns.length; b++) {
        final first = _patterns[a];
        final second = _patterns[b];
        if (first.days.intersection(second.days).isEmpty) continue;
        if (_minutes(first.start) < _minutes(second.end, end: true) &&
            _minutes(second.start) < _minutes(first.end, end: true)) {
          return true;
        }
      }
    }
    return false;
  }

  bool get _valid => _patterns.every(_rowOk) && !_overlap;

  Widget _row(int index, _Pattern pattern) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: RoundedContainer(
        shadow: false,
        padding: EdgeInsets.all(12.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClockField(value: pattern.start, onChanged: (value) => setState(() => pattern.start = value)),
                8.width,
                Text('schedule.to'.tr, style: text.bodySmall),
                8.width,
                ClockField(value: pattern.end, onChanged: (value) => setState(() => pattern.end = value)),
                const Spacer(),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Iconsax.trash, size: 18.r, color: AppColors.danger),
                  onPressed: () => setState(() => _patterns.removeAt(index)),
                ),
              ],
            ),
            8.height,
            ChoiceWrap<int>(
              values: const [0, 1, 2, 3, 4, 5, 6],
              isSelected: pattern.days.contains,
              label: (day) => 'day.$day'.tr,
              onTap: (day) => setState(() {
                if (!pattern.days.remove(day)) pattern.days.add(day);
              }),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SheetBody(
      title: 'staff.editSchedule'.tr,
      subtitle: widget.member.name,
      children: [
        for (var i = 0; i < _patterns.length; i++) _row(i, _patterns[i]),
        if (_patterns.isEmpty) ...[
          Text('staff.noShifts'.tr, style: text.bodySmall),
          12.height,
        ],
        if (_overlap) ...[
          Text('staff.overlap'.tr, style: text.bodySmall?.copyWith(color: AppColors.danger)),
          8.height,
        ],
        AppButton(
          title: 'staff.addShift'.tr,
          icon: Iconsax.add,
          small: true,
          variant: AppButtonVariant.ghost,
          onTap: () => setState(() => _patterns.add(_Pattern('09:00', '17:00', {}))),
        ),
        18.height,
        SubmitButton(
          title: 'common.save'.tr,
          onSubmit: _valid
              ? () => Get.find<StaffController>().saveSchedule(
                    widget.member,
                    [
                      for (final pattern in _patterns)
                        ShiftPattern(start: pattern.start, end: pattern.end, days: pattern.days.toList()),
                    ],
                  )
              : null,
        ),
      ],
    );
  }
}
