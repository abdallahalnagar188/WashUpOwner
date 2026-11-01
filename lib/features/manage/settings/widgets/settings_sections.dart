import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../commons/models/business_settings.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../common/widgets/manage_cards.dart';
import '../../common/widgets/manage_sheets.dart';

/// Each section saves on its own, after asking the reason the server requires.
void _askReason(
  BuildContext context, {
  required String section,
  required String impact,
  required Future<bool> Function(String reason) onSubmit,
}) {
  showReasonSheet(
    context,
    title: 'settings.saveTitle'.trParams({'section': section}),
    body: impact,
    onSubmit: onSubmit,
  );
}

class BusinessSection extends StatefulWidget {
  final BusinessDetails details;
  final bool readOnly;
  final Future<bool> Function({
    required String nameAr,
    required String nameEn,
    required String phone,
    required String email,
    required String reason,
  }) onSave;

  const BusinessSection({
    super.key,
    required this.details,
    required this.readOnly,
    required this.onSave,
  });

  @override
  State<BusinessSection> createState() => _BusinessSectionState();
}

class _BusinessSectionState extends State<BusinessSection> {
  static final RegExp _phoneShape = RegExp(r'^\+?[\d\s-]{8,20}$');
  static final RegExp _emailShape = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  late final _nameAr = TextEditingController(text: widget.details.name.ar);
  late final _nameEn = TextEditingController(text: widget.details.name.en);
  late final _phone = TextEditingController(text: widget.details.phone);
  late final _email = TextEditingController(text: widget.details.email);

  @override
  void dispose() {
    for (final input in [_nameAr, _nameEn, _phone, _email]) {
      input.dispose();
    }
    super.dispose();
  }

  String get _emailText => _email.text.trim().toLowerCase();

  bool get _dirty =>
      _nameAr.text.trim() != widget.details.name.ar ||
      _nameEn.text.trim() != widget.details.name.en ||
      _phone.text.trim() != widget.details.phone ||
      _emailText != widget.details.email.toLowerCase();

  bool get _valid =>
      _nameAr.text.trim().length >= 2 &&
      _phoneShape.hasMatch(_phone.text.trim()) &&
      (_emailText.isEmpty || _emailShape.hasMatch(_emailText));

  void _touch(String _) => setState(() {});

  void _save() {
    _askReason(
      context,
      section: 'settings.business'.tr,
      impact: 'settings.businessImpact'.tr,
      onSubmit: (reason) => widget.onSave(
        nameAr: _nameAr.text.trim(),
        nameEn: _nameEn.text.trim(),
        phone: _phone.text.trim(),
        email: _emailText,
        reason: reason,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'settings.business'.tr,
      children: [
        IgnorePointer(
          ignoring: widget.readOnly,
          child: Column(
            children: [
              AppTextField(controller: _nameAr, label: 'manage.nameAr'.tr, maxLength: 60, onChanged: _touch),
              12.height,
              AppTextField(
                controller: _nameEn,
                label: 'manage.nameEn'.tr,
                maxLength: 60,
                textDirection: TextDirection.ltr,
                onChanged: _touch,
              ),
              12.height,
              AppTextField(
                controller: _phone,
                label: 'orders.phone'.tr,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                onChanged: _touch,
              ),
              12.height,
              AppTextField(
                controller: _email,
                label: 'settings.email'.tr,
                keyboardType: TextInputType.emailAddress,
                textDirection: TextDirection.ltr,
                onChanged: _touch,
              ),
            ],
          ),
        ),
        if (!widget.readOnly) ...[
          14.height,
          AppButton(title: 'common.save'.tr, small: true, onTap: _dirty && _valid ? _save : null),
        ],
      ],
    );
  }
}

class ManagerEditsSection extends StatefulWidget {
  final bool value;
  final bool readOnly;
  final Future<bool> Function(bool value, String reason) onSave;

  const ManagerEditsSection({
    super.key,
    required this.value,
    required this.readOnly,
    required this.onSave,
  });

  @override
  State<ManagerEditsSection> createState() => _ManagerEditsSectionState();
}

class _ManagerEditsSectionState extends State<ManagerEditsSection> {
  late bool _value = widget.value;

  void _save() {
    _askReason(
      context,
      section: 'settings.permissions'.tr,
      impact: _value ? 'settings.managerOn'.tr : 'settings.managerOff'.tr,
      onSubmit: (reason) => widget.onSave(_value, reason),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'settings.permissions'.tr,
      children: [
        SwitchListTile.adaptive(activeTrackColor: AppColors.primary, 
          contentPadding: EdgeInsets.zero,
          title: Text('settings.managerEdits'.tr, style: Theme.of(context).textTheme.bodyMedium),
          value: _value,
          onChanged: widget.readOnly ? null : (value) => setState(() => _value = value),
        ),
        if (!widget.readOnly) ...[
          6.height,
          AppButton(title: 'common.save'.tr, small: true, onTap: _value != widget.value ? _save : null),
        ],
      ],
    );
  }
}

class PrefsSection extends StatefulWidget {
  final Map<String, bool> prefs;
  final bool readOnly;
  final Future<bool> Function(Map<String, bool> prefs, String reason) onSave;

  const PrefsSection({
    super.key,
    required this.prefs,
    required this.readOnly,
    required this.onSave,
  });

  @override
  State<PrefsSection> createState() => _PrefsSectionState();
}

class _PrefsSectionState extends State<PrefsSection> {
  late final Map<String, bool> _prefs = {
    ...widget.prefs,
    BusinessSettings.alwaysOnPref: true,
  };

  bool get _dirty => BusinessSettings.prefKeys.any(
        (key) =>
            key != BusinessSettings.alwaysOnPref &&
            (_prefs[key] ?? false) != (widget.prefs[key] ?? false),
      );

  void _save() {
    _askReason(
      context,
      section: 'settings.notifications'.tr,
      impact: 'settings.prefsImpact'.tr,
      onSubmit: (reason) => widget.onSave(
        {for (final key in BusinessSettings.prefKeys) key: _prefs[key] ?? false},
        reason,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SectionCard(
      title: 'settings.notifications'.tr,
      children: [
        for (final key in BusinessSettings.prefKeys)
          SwitchListTile.adaptive(activeTrackColor: AppColors.primary, 
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text('settings.pref.$key'.tr, style: text.bodyMedium),
            subtitle: key == BusinessSettings.alwaysOnPref ? Text('settings.alwaysOn'.tr) : null,
            value: _prefs[key] ?? false,
            onChanged: widget.readOnly || key == BusinessSettings.alwaysOnPref
                ? null
                : (value) => setState(() => _prefs[key] = value),
          ),
        if (!widget.readOnly) ...[
          6.height,
          AppButton(title: 'common.save'.tr, small: true, onTap: _dirty ? _save : null),
        ],
      ],
    );
  }
}
