import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../commons/models/schedule_day.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
import '../../common/widgets/manage_sheets.dart';

class BlockSlotSheet extends StatefulWidget {
  final ScheduleDay day;
  final String? initialStart;
  final Future<bool> Function({required String start, required String end, required String reason})
      onSubmit;

  const BlockSlotSheet({super.key, required this.day, this.initialStart, required this.onSubmit});

  @override
  State<BlockSlotSheet> createState() => _BlockSlotSheetState();
}

class _BlockSlotSheetState extends State<BlockSlotSheet> {
  final _reason = TextEditingController();
  late String _start;
  late String _end;

  List<String> get _starts => widget.day.blockableStarts;

  List<String> get _ends => widget.day.endsAfter(_start);

  List<String> get _presets => [
        'schedule.preset.maintenance'.tr,
        'schedule.preset.staff'.tr,
        'schedule.preset.cleaning'.tr,
        'schedule.preset.event'.tr,
        'schedule.preset.utilities'.tr,
      ];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialStart;
    _start = initial != null && _starts.contains(initial) ? initial : _starts.first;
    _end = _ends.isEmpty ? _start : _ends.first;
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  String _time(String iso) {
    final at = DateTime.tryParse(iso);
    return at == null ? iso : FormatHelper.time(at);
  }

  void _setStart(String value) {
    setState(() {
      _start = value;
      final ends = _ends;
      if (!ends.contains(_end)) _end = ends.isEmpty ? value : ends.first;
    });
  }

  bool get _valid => _reason.text.trim().length >= 3 && _ends.contains(_end);

  Widget _times(List<String> values, String selected, ValueChanged<String> onSelect) {
    return SizedBox(
      height: 38.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: values.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (_, index) => Center(
          child: AppChip(
            label: _time(values[index]),
            selected: values[index] == selected,
            onTap: () => onSelect(values[index]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SheetBody(
      title: 'schedule.block'.tr,
      subtitle: 'schedule.blockBody'.tr,
      children: [
        FieldLabel('schedule.from'.tr),
        _times(_starts, _start, _setStart),
        14.height,
        FieldLabel('schedule.to'.tr),
        _times(_ends, _end, (value) => setState(() => _end = value)),
        14.height,
        FieldLabel('sheet.reason'.tr),
        ChoiceWrap<String>(
          values: _presets,
          isSelected: (value) => _reason.text.trim() == value,
          label: (value) => value,
          onTap: (value) => setState(() => _reason.text = value),
        ),
        10.height,
        AppTextField(dense: true, 
          controller: _reason,
          maxLines: 2,
          maxLength: 160,
          onChanged: (_) => setState(() {}),
        ),
        18.height,
        SubmitButton(
          title: 'schedule.block'.tr,
          onSubmit: _valid
              ? () => widget.onSubmit(start: _start, end: _end, reason: _reason.text.trim())
              : null,
        ),
      ],
    );
  }
}
