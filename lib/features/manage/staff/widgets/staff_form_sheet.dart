import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../commons/models/owner_account.dart';
import '../../../../commons/models/staff_member.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
import '../../common/widgets/amount_input.dart';
import '../../common/widgets/manage_cards.dart';
import '../../common/widgets/manage_sheets.dart';
import '../controllers/staff_controller.dart';

/// Adds a member, or edits one when [member] is set. Name and phone are fixed
/// after adding: the API takes neither on edit.
class StaffFormSheet extends StatefulWidget {
  final StaffMember? member;

  const StaffFormSheet({super.key, this.member});

  @override
  State<StaffFormSheet> createState() => _StaffFormSheetState();
}

class _StaffFormSheetState extends State<StaffFormSheet> {
  static const List<String> _roles = ['employee', 'manager'];

  final StaffController _controller = Get.find<StaffController>();

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _reason = TextEditingController();
  late final _discount = TextEditingController(
    text: FormatHelper.plain(widget.member?.maxDiscountPct ?? _defaultDiscount),
  );

  late String _role = widget.member?.role == 'manager' ? 'manager' : 'employee';
  late String _branchId;
  late Map<String, bool> _permissions;

  num get _defaultDiscount => _limit < 10 ? _limit : 10;

  num get _limit => _controller.maxDiscountLimit;

  bool get _creating => widget.member == null;

  /// A branch manager adds plain employees on the default terms.
  bool get _locked => _creating && !_controller.isOwner;

  List<OwnerBranch> get _branches => _controller.session.account.value?.branches ?? const [];

  @override
  void initState() {
    super.initState();
    final member = widget.member;
    final account = _controller.session.account.value;
    _branchId = member?.branchId ??
        (_controller.isOwner ? _controller.session.workingBranchId : account?.homeBranchId) ??
        _controller.session.workingBranchId ??
        '';
    _permissions = {...StaffMember.defaultPermissions(_role), ...?member?.permissions};
  }

  @override
  void dispose() {
    for (final input in [_name, _phone, _reason, _discount]) {
      input.dispose();
    }
    super.dispose();
  }

  num? get _discountValue => parseAmount(_discount.text);

  String? get _discountError {
    if (_discount.text.isEmpty) return null;
    final value = _discountValue;
    return value == null || value < 0 || value > _limit
        ? 'staff.discountRange'.trParams({'max': FormatHelper.number(_limit)})
        : null;
  }

  bool get _changed {
    final member = widget.member!;
    return _role != member.role ||
        _branchId != member.branchId ||
        _discountValue != member.maxDiscountPct ||
        StaffMember.permissionKeys.any((key) => (_permissions[key] ?? false) != (member.permissions[key] ?? false));
  }

  bool get _valid {
    if (_branchId.isEmpty || _discountValue == null || _discountError != null) return false;
    if (_creating) return _name.text.trim().length >= 3 && StaffMember.validPhone(_phone.text);
    return _changed && _reason.text.trim().length >= 3;
  }

  void _touch(String _) => setState(() {});

  void _setRole(String role) {
    if (role == _role) return;
    setState(() {
      _role = role;
      _permissions = StaffMember.defaultPermissions(role);
    });
  }

  Map<String, bool> get _permissionsBody => {
        for (final key in StaffMember.permissionKeys) key: _permissions[key] ?? false,
      };

  Future<bool> _submit() => _creating
      ? _controller.create(
          name: _name.text.trim(),
          phone: _phone.text.trim(),
          role: _role,
          branchId: _branchId,
          maxDiscountPct: _discountValue!,
          permissions: _permissionsBody,
        )
      : _controller.saveMember(
          widget.member!,
          role: _role,
          branchId: _branchId,
          maxDiscountPct: _discountValue!,
          permissions: _permissionsBody,
          reason: _reason.text.trim(),
        );

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SheetBody(
      title: _creating ? 'staff.add'.tr : widget.member!.name,
      children: [
        if (_creating) ...[
          AppTextField(controller: _name, label: 'staff.name'.tr, onChanged: _touch),
          12.height,
          AppTextField(
            controller: _phone,
            label: 'orders.phone'.tr,
            hint: '01xxxxxxxxx',
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            onChanged: _touch,
          ),
          14.height,
        ],
        FieldLabel('staff.role'.tr),
        ChoiceWrap<String>(
          values: _locked ? const ['employee'] : _roles,
          isSelected: (role) => role == _role,
          label: (role) => 'more.role.$role'.tr,
          onTap: _locked ? null : _setRole,
        ),
        14.height,
        if (_branches.length > 1 || !_creating) ...[
          FieldLabel('manage.branch'.tr),
          ChoiceWrap<OwnerBranch>(
            values: _branches,
            isSelected: (branch) => branch.id == _branchId,
            label: (branch) => branch.name.shown,
            onTap: _locked ? null : (branch) => setState(() => _branchId = branch.id),
          ),
          14.height,
        ],
        IgnorePointer(
          ignoring: _locked,
          child: AppTextField(
            controller: _discount,
            label: 'staff.discountLimit'.tr,
            error: _discountError,
            keyboardType: amountKeyboard,
            inputFormatters: amountInput,
            textDirection: TextDirection.ltr,
            onChanged: _touch,
          ),
        ),
        14.height,
        Text('staff.permissions'.tr, style: text.titleSmall),
        for (final key in StaffMember.permissionKeys)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text('staff.permission.$key'.tr, style: text.bodyMedium),
            value: _permissions[key] ?? false,
            onChanged: _locked ? null : (value) => setState(() => _permissions[key] = value),
          ),
        if (!_creating) ...[
          10.height,
          AppTextField(controller: _reason, label: 'sheet.reason'.tr, onChanged: _touch),
        ],
        18.height,
        SubmitButton(
          title: _creating ? 'staff.add'.tr : 'common.save'.tr,
          onSubmit: _valid ? _submit : null,
        ),
      ],
    );
  }
}
