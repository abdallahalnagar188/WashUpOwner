import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../common/widgets/manage_cards.dart';
import '../../common/widgets/manage_sheets.dart';

class ShiftReviewForm extends StatefulWidget {
  final String status;
  final Future<bool> Function({required String status, required String note}) onSubmit;

  const ShiftReviewForm({super.key, required this.status, required this.onSubmit});

  @override
  State<ShiftReviewForm> createState() => _ShiftReviewFormState();
}

class _ShiftReviewFormState extends State<ShiftReviewForm> {
  final _note = TextEditingController();
  String? _busyWith;

  List<String> get _presets => [
        'shifts.preset.matched'.tr,
        'shifts.preset.collected'.tr,
        'shifts.preset.justified'.tr,
        'shifts.preset.followUp'.tr,
      ];

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _addPreset(String preset) {
    final current = _note.text.trim();
    setState(() => _note.text = current.isEmpty ? preset : '$current${'manage.listJoin'.tr}$preset');
  }

  Future<void> _send(String status) async {
    setState(() => _busyWith = status);
    final ok = await widget.onSubmit(status: status, note: _note.text.trim());
    if (!mounted) return;
    setState(() {
      _busyWith = null;
      if (ok) _note.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final valid = _note.text.trim().length >= 3 && _busyWith == null;
    return SectionCard(
      title: widget.status == 'submitted' ? 'shifts.review'.tr : 'shifts.updateReview'.tr,
      children: [
        ChoiceWrap<String>(
          values: _presets,
          isSelected: (_) => false,
          label: (preset) => preset,
          onTap: _addPreset,
        ),
        10.height,
        AppTextField(
          controller: _note,
          label: 'shifts.reviewNote'.tr,
          maxLines: 2,
          onChanged: (_) => setState(() {}),
        ),
        14.height,
        Row(
          children: [
            Expanded(
              child: AppButton(
                title: 'shifts.flag'.tr,
                small: true,
                variant: AppButtonVariant.danger,
                loading: _busyWith == 'flagged',
                onTap: valid ? () => _send('flagged') : null,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: AppButton(
                title: 'shifts.markReviewed'.tr,
                small: true,
                loading: _busyWith == 'reviewed',
                onTap: valid ? () => _send('reviewed') : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
