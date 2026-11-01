import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../commons/models/managed_branch.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
import '../../common/widgets/amount_input.dart';
import '../../common/widgets/manage_sheets.dart';
import '../controllers/branches_controller.dart';
import '../../common/widgets/manage_cards.dart';

class _Rule {
  final String key;
  final num min;
  final num max;
  final TextEditingController input;

  _Rule(this.key, this.min, this.max, num value)
      : input = TextEditingController(text: FormatHelper.plain(value));

  num? get value => parseAmount(input.text);

  bool get ok => value != null && value! >= min && value! <= max;
}

class BranchRulesSheet extends StatefulWidget {
  final ManagedBranch branch;

  const BranchRulesSheet({super.key, required this.branch});

  @override
  State<BranchRulesSheet> createState() => _BranchRulesSheetState();
}

class _BranchRulesSheetState extends State<BranchRulesSheet> {
  late final BranchRules _rules = widget.branch.settings;
  late bool _autoConfirm = _rules.autoConfirm;
  late num _slot = BranchRules.slotChoices.contains(_rules.slotIntervalMin) ? _rules.slotIntervalMin : 30;
  final _reason = TextEditingController();

  late final _leadTime = _Rule('branches.leadTime', 0, 240, _rules.leadTimeMin);
  late final _maxAdvance = _Rule('branches.maxAdvance', 1, 30, _rules.maxAdvanceDays);
  late final _freeCancel = _Rule('branches.freeCancel', 0, 1440, _rules.freeCancelMin);
  late final _noShow = _Rule('branches.noShowGrace', 5, 120, _rules.noShowGraceMin);
  late final _reminder = _Rule('branches.reminder', 5, 1440, _rules.reminderMin);

  List<_Rule> get _fields => [_leadTime, _maxAdvance, _freeCancel, _noShow, _reminder];

  @override
  void dispose() {
    for (final field in _fields) {
      field.input.dispose();
    }
    _reason.dispose();
    super.dispose();
  }

  bool get _valid => _fields.every((field) => field.ok) && _reason.text.trim().length >= 3;

  @override
  Widget build(BuildContext context) {
    return SheetBody(
      title: 'branches.editRules'.tr,
      subtitle: widget.branch.name.shown,
      children: [
        SwitchListTile.adaptive(activeTrackColor: AppColors.primary, 
          contentPadding: EdgeInsets.zero,
          title: Text('branches.autoConfirm'.tr, style: Theme.of(context).textTheme.titleSmall),
          value: _autoConfirm,
          onChanged: (value) => setState(() => _autoConfirm = value),
        ),
        8.height,
        FieldLabel('branches.slot'.tr),
        ChoiceWrap<num>(
          values: BranchRules.slotChoices,
          isSelected: (minutes) => minutes == _slot,
          label: (minutes) => 'services.minutes'.trParams({'count': '$minutes'}),
          onTap: (minutes) => setState(() => _slot = minutes),
        ),
        14.height,
        for (final field in _fields) ...[
          AppTextField(dense: true, 
            controller: field.input,
            label: '${field.key.tr} (${FormatHelper.plain(field.min)}-${FormatHelper.plain(field.max)})',
            error: field.input.text.isEmpty || field.ok ? null : 'branches.outOfRange'.tr,
            keyboardType: amountKeyboard,
            inputFormatters: amountInput,
            textDirection: TextDirection.ltr,
            onChanged: (_) => setState(() {}),
          ),
          12.height,
        ],
        AppTextField(dense: true, controller: _reason, label: 'sheet.reason'.tr, maxLines: 2, onChanged: (_) => setState(() {})),
        18.height,
        SubmitButton(
          title: 'common.save'.tr,
          onSubmit: _valid
              ? () => Get.find<BranchesController>().updateRules(
                    widget.branch,
                    BranchRules(
                      autoConfirm: _autoConfirm,
                      slotIntervalMin: _slot,
                      leadTimeMin: _leadTime.value!,
                      maxAdvanceDays: _maxAdvance.value!,
                      freeCancelMin: _freeCancel.value!,
                      noShowGraceMin: _noShow.value!,
                      reminderMin: _reminder.value!,
                    ),
                    _reason.text.trim(),
                  )
              : null,
        ),
      ],
    );
  }
}
