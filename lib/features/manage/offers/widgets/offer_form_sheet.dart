import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/managed_service.dart';
import '../../../../commons/models/offer.dart';
import '../../../../commons/models/owner_account.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/data/vendor_manage_api.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
import '../../../../core/services/session_service.dart';
import '../../common/widgets/amount_input.dart';
import '../../common/widgets/manage_sheets.dart';
import '../../common/widgets/manage_cards.dart';

class OfferFormSheet extends StatefulWidget {
  final Offer? offer;
  final Future<bool> Function({String? id, required Map<String, dynamic> payload}) onSubmit;

  const OfferFormSheet({super.key, this.offer, required this.onSubmit});

  @override
  State<OfferFormSheet> createState() => _OfferFormSheetState();
}

class _OfferFormSheetState extends State<OfferFormSheet> {
  static const num _maxPercent = 50;

  final SessionService _session = Get.find<SessionService>();

  late final _titleAr = TextEditingController(text: widget.offer?.title.ar);
  late final _titleEn = TextEditingController(
    text: widget.offer == null || widget.offer!.title.en == widget.offer!.title.ar
        ? null
        : widget.offer!.title.en,
  );
  late final _descriptionAr = TextEditingController(text: widget.offer?.description.ar);
  late final _descriptionEn = TextEditingController(text: widget.offer?.description.en);
  late final _value = TextEditingController(
    text: widget.offer == null ? null : FormatHelper.plain(widget.offer!.discountValue),
  );

  late String _discountType = widget.offer?.discountType ?? 'percent';
  late DateTime _startAt;
  late DateTime _endAt;
  late final Set<String> _categories = {...?widget.offer?.serviceCategories};
  late final Set<String> _branchIds;

  List<OwnerBranch> get _branches => _session.account.value?.branches ?? const [];

  /// Only a new offer or a draft can stay unpublished.
  bool get _canStayDraft => widget.offer == null || widget.offer!.isDraft;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final nextHour = DateTime(now.year, now.month, now.day, now.hour + 1);
    _startAt = widget.offer?.startAt?.toLocal() ?? nextHour;
    _endAt = widget.offer?.endAt?.toLocal() ?? nextHour.add(const Duration(days: 7));
    final selected = _session.branchId.value;
    _branchIds = {
      ...?widget.offer?.branchIds,
      if (widget.offer == null)
        if (selected == SessionService.allBranches)
          ..._branches.map((branch) => branch.id)
        else
          selected,
    };
  }

  @override
  void dispose() {
    for (final input in [_titleAr, _titleEn, _descriptionAr, _descriptionEn, _value]) {
      input.dispose();
    }
    super.dispose();
  }

  num? get _number => parseAmount(_value.text);

  String? get _valueError {
    final value = _number;
    if (_value.text.isEmpty) return null;
    if (value == null || value <= 0) return 'offers.badValue'.tr;
    if (_discountType == 'percent' && value > _maxPercent) return 'offers.maxPercent'.tr;
    return null;
  }

  bool get _datesOk => _endAt.isAfter(_startAt);

  bool get _valid =>
      _titleAr.text.trim().length >= 3 &&
      _number != null &&
      _valueError == null &&
      _datesOk &&
      _branchIds.isNotEmpty;

  void _touch(String _) => setState(() {});

  Future<DateTime?> _pickMoment(DateTime current) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final first = current.isBefore(today) ? current : today;
    final latest = today.add(const Duration(days: 730));
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: first,
      lastDate: current.isAfter(latest) ? current : latest,
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(current));
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<bool> _submit({required bool publish}) => widget.onSubmit(
        id: widget.offer?.id,
        payload: VendorManageApi.offerPayload(
          titleAr: _titleAr.text.trim(),
          titleEn: _titleEn.text.trim(),
          descriptionAr: _descriptionAr.text.trim(),
          descriptionEn: _descriptionEn.text.trim(),
          discountType: _discountType,
          discountValue: _number!,
          startAt: _startAt,
          endAt: _endAt,
          branchIds: _branchIds.toList(),
          serviceCategories: _categories.toList(),
          publish: publish,
        ),
      );

  Widget _moment(String label, DateTime value, ValueChanged<DateTime> onPicked) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: const Icon(Iconsax.calendar_1),
      title: Text(label, style: Theme.of(context).textTheme.titleSmall),
      subtitle: Text(FormatHelper.dayTime(value)),
      onTap: () async {
        final picked = await _pickMoment(value);
        if (picked != null) setState(() => onPicked(picked));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SheetBody(
      title: widget.offer == null ? 'offers.add'.tr : 'offers.edit'.tr,
      children: [
        AppTextField(dense: true, controller: _titleAr, label: 'offers.titleAr'.tr, maxLength: 60, onChanged: _touch),
        12.height,
        AppTextField(dense: true, 
          controller: _titleEn,
          label: 'offers.titleEn'.tr,
          maxLength: 60,
          textDirection: TextDirection.ltr,
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
        14.height,
        FieldLabel('offers.discountType'.tr),
        ChoiceWrap<String>(
          values: const ['percent', 'fixed'],
          isSelected: (type) => type == _discountType,
          label: (type) => 'sheet.$type'.tr,
          onTap: (type) => setState(() => _discountType = type),
        ),
        12.height,
        AppTextField(dense: true, 
          controller: _value,
          label: 'sheet.discountValue'.tr,
          error: _valueError,
          keyboardType: amountKeyboard,
          inputFormatters: amountInput,
          textDirection: TextDirection.ltr,
          onChanged: _touch,
        ),
        8.height,
        _moment('offers.start'.tr, _startAt, (value) => _startAt = value),
        _moment('offers.end'.tr, _endAt, (value) => _endAt = value),
        if (!_datesOk)
          Text('offers.badDates'.tr, style: text.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error)),
        12.height,
        FieldLabel('offers.services'.tr),
        ChoiceWrap<String>(
          values: ManagedService.categories,
          isSelected: _categories.contains,
          label: (category) => 'services.category.$category'.tr,
          onTap: (category) => setState(() {
            if (!_categories.remove(category)) _categories.add(category);
          }),
        ),
        4.height,
        Text('offers.servicesHint'.tr, style: text.bodySmall),
        14.height,
        FieldLabel('offers.branches'.tr),
        ChoiceWrap<OwnerBranch>(
          values: _branches,
          isSelected: (branch) => _branchIds.contains(branch.id),
          label: (branch) => branch.name.shown,
          onTap: (branch) => setState(() {
            if (!_branchIds.remove(branch.id)) _branchIds.add(branch.id);
          }),
        ),
        18.height,
        if (_canStayDraft) ...[
          SubmitButton(
            title: 'offers.publish'.tr,
            onSubmit: _valid ? () => _submit(publish: true) : null,
          ),
          10.height,
          SubmitButton(
            title: 'offers.saveDraft'.tr,
            variant: AppButtonVariant.ghost,
            onSubmit: _valid ? () => _submit(publish: false) : null,
          ),
        ] else
          SubmitButton(
            title: 'common.save'.tr,
            onSubmit: _valid ? () => _submit(publish: true) : null,
          ),
      ],
    );
  }
}
