import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../commons/models/managed_service.dart';
import '../../../../commons/models/owner_account.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/data/vendor_manage_api.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
import '../../../../core/services/session_service.dart';
import '../../common/widgets/amount_input.dart';
import '../../common/widgets/manage_sheets.dart';
import '../../common/widgets/manage_cards.dart';

class ServiceFormSheet extends StatefulWidget {
  final ManagedService? service;
  final Future<bool> Function({String? id, required Map<String, dynamic> payload}) onSubmit;

  const ServiceFormSheet({super.key, this.service, required this.onSubmit});

  @override
  State<ServiceFormSheet> createState() => _ServiceFormSheetState();
}

class _ServiceFormSheetState extends State<ServiceFormSheet> {
  static const List<String> _types = ['primary', 'addon'];

  final SessionService _session = Get.find<SessionService>();

  late final _nameAr = TextEditingController(text: widget.service?.name.ar);
  late final _nameEn = TextEditingController(text: widget.service?.name.en);
  late final _descriptionAr = TextEditingController(text: widget.service?.description.ar);
  late final _descriptionEn = TextEditingController(text: widget.service?.description.en);
  late final _price = TextEditingController(
    text: widget.service == null ? null : FormatHelper.plain(widget.service!.price),
  );
  late final _duration = TextEditingController(
    text: widget.service == null ? '30' : FormatHelper.plain(widget.service!.durationMin),
  );
  final _reason = TextEditingController();

  late String _branchId = widget.service?.branchId ?? _session.workingBranchId ?? '';
  late String _type = widget.service?.type ?? _types.first;
  late String _category = ManagedService.categories.contains(widget.service?.category)
      ? widget.service!.category
      : ManagedService.categories.first;
  late bool _active = widget.service?.active ?? true;

  List<OwnerBranch> get _branches => _session.account.value?.branches ?? const [];

  @override
  void dispose() {
    for (final input in [_nameAr, _nameEn, _descriptionAr, _descriptionEn, _price, _duration, _reason]) {
      input.dispose();
    }
    super.dispose();
  }

  num? get _priceValue => parseAmount(_price.text);

  num? get _durationValue => parseAmount(_duration.text);

  bool get _priceChanged =>
      widget.service != null && _priceValue != null && _priceValue != widget.service!.price;

  bool _nameOk(String text) => text.trim().length >= 2;

  String? get _priceError {
    if (_price.text.isEmpty) return null;
    final value = _priceValue;
    return value == null || value < 10 || value > 5000 ? 'services.priceRange'.tr : null;
  }

  String? get _durationError {
    if (_duration.text.isEmpty) return null;
    final value = _durationValue;
    return value == null || value < 2 || value > 240 ? 'services.durationRange'.tr : null;
  }

  bool get _valid =>
      _branchId.isNotEmpty &&
      _nameOk(_nameAr.text) &&
      _nameOk(_nameEn.text) &&
      _priceValue != null &&
      _durationValue != null &&
      _priceError == null &&
      _durationError == null;

  void _touch(String _) => setState(() {});

  Future<bool> _submit() => widget.onSubmit(
        id: widget.service?.id,
        payload: VendorManageApi.servicePayload(
          branchId: _branchId,
          nameAr: _nameAr.text.trim(),
          nameEn: _nameEn.text.trim(),
          descriptionAr: _descriptionAr.text.trim(),
          descriptionEn: _descriptionEn.text.trim(),
          category: _category,
          type: _type,
          price: _priceValue!,
          durationMin: _durationValue!,
          active: _active,
          reason: _priceChanged ? _reason.text.trim() : null,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final editing = widget.service != null;
    return SheetBody(
      title: editing ? 'services.edit'.tr : 'services.add'.tr,
      children: [
        if (!editing && _branches.length > 1) ...[
          FieldLabel('manage.branch'.tr),
          ChoiceWrap<OwnerBranch>(
            values: _branches,
            isSelected: (branch) => branch.id == _branchId,
            label: (branch) => branch.name.shown,
            onTap: (branch) => setState(() => _branchId = branch.id),
          ),
          14.height,
        ],
        FieldLabel('services.type'.tr),
        ChoiceWrap<String>(
          values: _types,
          isSelected: (type) => type == _type,
          label: (type) => 'services.type.$type'.tr,
          onTap: (type) => setState(() => _type = type),
        ),
        14.height,
        FieldLabel('services.category'.tr),
        ChoiceWrap<String>(
          values: ManagedService.categories,
          isSelected: (category) => category == _category,
          label: (category) => 'services.category.$category'.tr,
          onTap: (category) => setState(() => _category = category),
        ),
        14.height,
        AppTextField(dense: true, controller: _nameAr, label: 'manage.nameAr'.tr, maxLength: 60, onChanged: _touch),
        12.height,
        AppTextField(dense: true, 
          controller: _nameEn,
          label: 'manage.nameEn'.tr,
          maxLength: 60,
          textDirection: TextDirection.ltr,
          onChanged: _touch,
        ),
        12.height,
        AppTextField(dense: true, 
          controller: _descriptionAr,
          label: 'manage.descriptionAr'.tr,
          maxLength: 200,
          maxLines: 2,
        ),
        12.height,
        AppTextField(dense: true, 
          controller: _descriptionEn,
          label: 'manage.descriptionEn'.tr,
          maxLength: 200,
          maxLines: 2,
          textDirection: TextDirection.ltr,
        ),
        12.height,
        AppTextField(dense: true, 
          controller: _price,
          label: 'services.price'.tr,
          error: _priceError,
          keyboardType: amountKeyboard,
          inputFormatters: amountInput,
          textDirection: TextDirection.ltr,
          onChanged: _touch,
        ),
        12.height,
        AppTextField(dense: true, 
          controller: _duration,
          label: 'services.duration'.tr,
          error: _durationError,
          keyboardType: amountKeyboard,
          inputFormatters: amountInput,
          textDirection: TextDirection.ltr,
          onChanged: _touch,
        ),
        if (_priceChanged) ...[
          12.height,
          AppTextField(dense: true, controller: _reason, label: 'services.priceReason'.tr, maxLength: 200),
        ],
        6.height,
        SwitchListTile.adaptive(activeTrackColor: AppColors.primary, 
          contentPadding: EdgeInsets.zero,
          title: Text('services.active'.tr, style: Theme.of(context).textTheme.titleSmall),
          value: _active,
          onChanged: (value) => setState(() => _active = value),
        ),
        12.height,
        SubmitButton(
          title: 'common.save'.tr,
          onSubmit: _valid ? _submit : null,
        ),
      ],
    );
  }
}
