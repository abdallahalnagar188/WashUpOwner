import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/constance/app_colors.dart';
import '../../../core/extensions/sized_box_extension.dart';
import '../../../core/helpers/phone_helper.dart';
import '../sheets/app_sheet.dart';
import 'app_text_field.dart';

/// Mobile number input with a country picker in front of it. The number is
/// always laid out left to right, the way it is dialled.
class PhoneField extends StatefulWidget {
  final TextEditingController controller;
  final PhoneCountry country;
  final ValueChanged<PhoneCountry> onCountryChanged;
  final String? label;
  final String? error;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const PhoneField({
    super.key,
    required this.controller,
    required this.country,
    required this.onCountryChanged,
    this.label,
    this.error,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  State<PhoneField> createState() => _PhoneFieldState();
}

class _PhoneFieldState extends State<PhoneField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  Future<void> _pickCountry() async {
    final picked = await showAppSheet<PhoneCountry>(
      context,
      CountryPickerSheet(selected: widget.country),
    );
    if (picked != null && picked != widget.country) widget.onCountryChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final hasError = widget.error != null;
    final borderColor = hasError
        ? AppColors.danger
        : _focus.hasFocus
            ? AppColors.primary
            : AppColors.line;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: text.titleSmall),
          8.height,
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 56.h,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: borderColor, width: _focus.hasFocus ? 1.8 : 1.5),
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                Semantics(
                  button: true,
                  label: 'phone.country'.tr,
                  child: InkWell(
                    onTap: _pickCountry,
                    borderRadius: BorderRadius.horizontal(left: Radius.circular(16.r)),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      child: Row(
                        children: [
                          Text(widget.country.flag, style: TextStyle(fontSize: 20.sp)),
                          6.width,
                          Text(
                            widget.country.dialCode,
                            style: text.titleSmall?.copyWith(color: AppColors.ink900),
                          ),
                          2.width,
                          Icon(Iconsax.arrow_down_1, size: 14.r, color: AppColors.ink500),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(width: 1, height: 26.h, color: AppColors.line),
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focus,
                    keyboardType: TextInputType.phone,
                    textInputAction: widget.textInputAction,
                    onSubmitted: widget.onSubmitted,
                    autofillHints: const [AutofillHints.telephoneNumberNational],
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
                      LengthLimitingTextInputFormatter(18),
                    ],
                    style: text.bodyLarge?.copyWith(letterSpacing: 0.6),
                    decoration: InputDecoration(
                      hintText: widget.country.example,
                      hintStyle: text.bodyMedium?.copyWith(color: AppColors.hintGray),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12.w),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasError) ...[
          6.height,
          Text(widget.error!, style: text.bodySmall?.copyWith(color: AppColors.danger)),
        ],
      ],
    );
  }
}

/// Searchable list of [PhoneHelper.countries]; pops the chosen one.
class CountryPickerSheet extends StatefulWidget {
  final PhoneCountry selected;

  const CountryPickerSheet({super.key, required this.selected});

  @override
  State<CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<CountryPickerSheet> {
  String _query = '';

  List<PhoneCountry> get _matches {
    final q = _query.trim().toLowerCase().replaceFirst('+', '');
    if (q.isEmpty) return PhoneHelper.countries;
    return PhoneHelper.countries
        .where((c) =>
            c.nameAr.contains(q) ||
            c.nameEn.toLowerCase().contains(q) ||
            c.dialCode.substring(1).startsWith(q) ||
            c.iso.name.toLowerCase() == q)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final lang = Get.locale?.languageCode ?? 'ar';
    final matches = _matches;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSheetHeader(title: 'phone.country'.tr),
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 8.h),
          child: AppTextField(
            hint: 'phone.search'.tr,
            dense: true,
            onChanged: (v) => setState(() => _query = v),
            prefix: Icon(Iconsax.search_normal_1, size: 18.r, color: AppColors.ink500),
          ),
        ),
        Flexible(
          child: matches.isEmpty
              ? Padding(
                  padding: EdgeInsets.all(24.r),
                  child: Text('phone.empty'.tr, style: text.bodyMedium?.copyWith(color: AppColors.ink500)),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.only(bottom: 12.h),
                  itemCount: matches.length,
                  itemBuilder: (_, i) {
                    final c = matches[i];
                    final selected = c == widget.selected;
                    return ListTile(
                      onTap: () => Navigator.of(context).pop(c),
                      contentPadding: EdgeInsets.symmetric(horizontal: 20.w),
                      leading: Text(c.flag, style: TextStyle(fontSize: 24.sp)),
                      title: Text(c.name(lang), style: text.bodyLarge),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            c.dialCode,
                            textDirection: TextDirection.ltr,
                            style: text.titleSmall?.copyWith(color: AppColors.ink500),
                          ),
                          if (selected) ...[
                            12.width,
                            Icon(Iconsax.tick_circle5, size: 20.r, color: AppColors.primary),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
