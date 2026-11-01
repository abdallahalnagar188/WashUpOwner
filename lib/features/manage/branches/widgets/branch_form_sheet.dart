import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../commons/models/managed_branch.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../common/widgets/manage_cards.dart';
import '../../common/widgets/amount_input.dart';
import '../../common/widgets/manage_sheets.dart';
import '../controllers/branches_controller.dart';

class _Day {
  String open;
  String close;
  bool closed;

  _Day(WorkingDay day)
      : open = day.open,
        close = day.close,
        closed = day.closed;

  WorkingDay get value => WorkingDay(open: open, close: close, closed: closed);
}

/// Edits a branch. The map pin stays out of this form, so the save leaves the
/// location as it is.
class BranchFormSheet extends StatefulWidget {
  final ManagedBranch branch;

  const BranchFormSheet({super.key, required this.branch});

  @override
  State<BranchFormSheet> createState() => _BranchFormSheetState();
}

class _BranchFormSheetState extends State<BranchFormSheet> {
  static final RegExp _phoneShape = RegExp(r'^\+?[\d\s-]{8,20}$');

  late final _nameAr = TextEditingController(text: widget.branch.name.ar);
  late final _nameEn = TextEditingController(text: widget.branch.name.en);
  late final _addressAr = TextEditingController(text: widget.branch.address.ar);
  late final _addressEn = TextEditingController(text: widget.branch.address.en);
  late final _phone = TextEditingController(text: widget.branch.phone);
  late final _capacity = TextEditingController(text: '${widget.branch.capacity}');
  final _reason = TextEditingController();

  late final Set<String> _amenities = {...widget.branch.amenities};
  late final List<_Day> _days = widget.branch.workingHours.map(_Day.new).toList();
  late bool _active = widget.branch.active;

  @override
  void dispose() {
    for (final input in [_nameAr, _nameEn, _addressAr, _addressEn, _phone, _capacity, _reason]) {
      input.dispose();
    }
    super.dispose();
  }

  num? get _capacityValue => parseAmount(_capacity.text);

  String? get _capacityError {
    if (_capacity.text.isEmpty) return null;
    final value = _capacityValue;
    return value == null || value < 1 || value > 30 ? 'branches.capacityRange'.tr : null;
  }

  static int _minutes(String clock, {bool end = false}) {
    final parts = clock.split(':');
    if (parts.length != 2) return -1;
    final total = (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
    return end && total == 0 ? 1440 : total;
  }

  bool _dayOk(_Day day) => day.closed || _minutes(day.close, end: true) > _minutes(day.open);

  bool get _valid =>
      _nameAr.text.trim().length >= 2 &&
      _addressAr.text.trim().length >= 3 &&
      _phoneShape.hasMatch(_phone.text.trim()) &&
      _capacityValue != null &&
      _capacityError == null &&
      _days.length == 7 &&
      _days.every(_dayOk) &&
      _reason.text.trim().length >= 3;

  void _touch(String _) => setState(() {});

  Widget _dayRow(int index) {
    final text = Theme.of(context).textTheme;
    final day = _days[index];
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          SizedBox(width: 66.w, child: Text('day.$index'.tr, style: text.bodySmall)),
          Switch.adaptive(activeTrackColor: AppColors.primary, 
            value: !day.closed,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (open) => setState(() => day.closed = !open),
          ),
          const Spacer(),
          if (day.closed)
            Text('branch.closed'.tr, style: text.bodySmall?.copyWith(color: AppColors.danger))
          else ...[
            ClockField(value: day.open, onChanged: (value) => setState(() => day.open = value)),
            6.width,
            ClockField(value: day.close, onChanged: (value) => setState(() => day.close = value)),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final stopping = widget.branch.active && !_active;
    final known = [
      ...ManagedBranch.knownAmenities,
      ...widget.branch.amenities.where((a) => !ManagedBranch.knownAmenities.contains(a)),
    ];
    return SheetBody(
      title: 'branches.edit'.tr,
      subtitle: widget.branch.name.shown,
      children: [
        AppTextField(dense: true, controller: _nameAr, label: 'manage.nameAr'.tr, onChanged: _touch),
        12.height,
        AppTextField(dense: true, 
          controller: _nameEn,
          label: 'manage.nameEn'.tr,
          maxLength: 80,
          textDirection: TextDirection.ltr,
        ),
        12.height,
        AppTextField(dense: true, controller: _addressAr, label: 'branches.addressAr'.tr, maxLines: 2, onChanged: _touch),
        12.height,
        AppTextField(dense: true, 
          controller: _addressEn,
          label: 'branches.addressEn'.tr,
          maxLength: 160,
          maxLines: 2,
          textDirection: TextDirection.ltr,
        ),
        12.height,
        AppTextField(dense: true, 
          controller: _phone,
          label: 'orders.phone'.tr,
          keyboardType: TextInputType.phone,
          textDirection: TextDirection.ltr,
          onChanged: _touch,
        ),
        12.height,
        AppTextField(dense: true, 
          controller: _capacity,
          label: 'branches.capacityLabel'.tr,
          error: _capacityError,
          keyboardType: amountKeyboard,
          inputFormatters: amountInput,
          textDirection: TextDirection.ltr,
          onChanged: _touch,
        ),
        14.height,
        FieldLabel('branches.amenities'.tr),
        ChoiceWrap<String>(
          values: known,
          isSelected: _amenities.contains,
          label: (amenity) => labelOr('branches.amenity.$amenity', amenity),
          onTap: (amenity) => setState(() {
            if (!_amenities.remove(amenity)) _amenities.add(amenity);
          }),
        ),
        14.height,
        FieldLabel('branches.hours'.tr),
        for (var i = 0; i < _days.length; i++) _dayRow(i),
        8.height,
        SwitchListTile.adaptive(activeTrackColor: AppColors.primary, 
          contentPadding: EdgeInsets.zero,
          title: Text('branches.activeSwitch'.tr, style: text.titleSmall),
          value: _active,
          onChanged: (value) => setState(() => _active = value),
        ),
        if (stopping) ...[
          Text(
            'branches.stopWarning'.trParams({'count': '${widget.branch.upcomingOrders}'}),
            style: text.bodySmall?.copyWith(color: AppColors.danger),
          ),
          8.height,
        ],
        AppTextField(dense: true, controller: _reason, label: 'sheet.reason'.tr, maxLines: 2, onChanged: _touch),
        18.height,
        SubmitButton(
          title: 'common.save'.tr,
          variant: stopping ? AppButtonVariant.danger : AppButtonVariant.primary,
          onSubmit: _valid
              ? () => Get.find<BranchesController>().saveBranch(
                    widget.branch,
                    nameAr: _nameAr.text.trim(),
                    nameEn: _nameEn.text.trim(),
                    addressAr: _addressAr.text.trim(),
                    addressEn: _addressEn.text.trim(),
                    phone: _phone.text.trim(),
                    capacity: _capacityValue!,
                    amenities: _amenities.toList(),
                    workingHours: _days.map((day) => day.value).toList(),
                    active: _active,
                    reason: _reason.text.trim(),
                  )
              : null,
        ),
      ],
    );
  }
}
