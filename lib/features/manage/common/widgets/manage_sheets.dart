import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';

ShapeBorder get _sheetShape => RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
    );

/// A bottom sheet that rises above the keyboard and scrolls when it is long.
Future<T?> showManageSheet<T>(BuildContext context, Widget child) => showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      shape: _sheetShape,
      builder: (sheet) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheet).bottom),
        child: SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheet).height * 0.86),
            child: child,
          ),
        ),
      ),
    );

class SheetBody extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;

  const SheetBody({super.key, required this.title, this.subtitle, required this.children});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 16.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: text.titleLarge),
          if (subtitle != null) ...[
            4.height,
            Text(subtitle!, style: text.bodySmall),
          ],
          14.height,
          ...children,
        ],
      ),
    );
  }
}

/// A form label over its chips.
class FieldLabel extends StatelessWidget {
  final String text;

  const FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

/// Chips that wrap, for choices inside a form.
class ChoiceWrap<T> extends StatelessWidget {
  final List<T> values;
  final bool Function(T) isSelected;
  final String Function(T) label;
  final ValueChanged<T>? onTap;

  const ChoiceWrap({
    super.key,
    required this.values,
    required this.isSelected,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: [
        for (final value in values)
          AppChip(
            label: label(value),
            selected: isSelected(value),
            onTap: onTap == null ? null : () => onTap!(value),
          ),
      ],
    );
  }
}

/// Submits a form and closes it only when the server accepted it.
class SubmitButton extends StatefulWidget {
  final String title;
  final Future<bool> Function()? onSubmit;
  final AppButtonVariant variant;
  final IconData? icon;

  const SubmitButton({
    super.key,
    required this.title,
    required this.onSubmit,
    this.variant = AppButtonVariant.primary,
    this.icon,
  });

  @override
  State<SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<SubmitButton> {
  bool _busy = false;

  Future<void> _run() async {
    setState(() => _busy = true);
    final ok = await widget.onSubmit!();
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AppButton(
      title: widget.title,
      icon: widget.icon,
      variant: widget.variant,
      loading: _busy,
      onTap: widget.onSubmit == null ? null : _run,
    );
  }
}

/// Asks for the reason the server wants with a change, and returns it through
/// [onSubmit], which keeps the sheet open if the save is refused.
Future<void> showReasonSheet(
  BuildContext context, {
  required String title,
  String? body,
  String? okText,
  List<String> presets = const [],
  bool danger = false,
  bool optional = false,
  required Future<bool> Function(String reason) onSubmit,
}) =>
    showManageSheet<void>(
      context,
      ReasonSheet(
        title: title,
        body: body,
        okText: okText,
        presets: presets,
        danger: danger,
        optional: optional,
        onSubmit: onSubmit,
      ),
    );

class ReasonSheet extends StatefulWidget {
  final String title;
  final String? body;
  final String? okText;
  final List<String> presets;
  final bool danger;
  final bool optional;
  final Future<bool> Function(String reason) onSubmit;

  const ReasonSheet({
    super.key,
    required this.title,
    this.body,
    this.okText,
    this.presets = const [],
    this.danger = false,
    this.optional = false,
    required this.onSubmit,
  });

  @override
  State<ReasonSheet> createState() => _ReasonSheetState();
}

class _ReasonSheetState extends State<ReasonSheet> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  String get _text => _reason.text.trim();

  bool get _valid => widget.optional || _text.length >= 3;

  @override
  Widget build(BuildContext context) {
    return SheetBody(
      title: widget.title,
      subtitle: widget.body,
      children: [
        if (widget.presets.isNotEmpty) ...[
          ChoiceWrap<String>(
            values: widget.presets,
            isSelected: (value) => _text == value,
            label: (value) => value,
            onTap: (value) => setState(() => _reason.text = value),
          ),
          12.height,
        ],
        AppTextField(
          controller: _reason,
          label: 'sheet.reason'.tr,
          maxLines: 3,
          maxLength: 200,
          onChanged: (_) => setState(() {}),
        ),
        18.height,
        SubmitButton(
          title: widget.okText ?? 'common.save'.tr,
          variant: widget.danger ? AppButtonVariant.danger : AppButtonVariant.primary,
          onSubmit: _valid ? () => widget.onSubmit(_text) : null,
        ),
      ],
    );
  }
}

/// Picks a time of day and hands it back as HH:mm.
Future<String?> pickClock(BuildContext context, String current) async {
  final parts = current.split(':');
  final picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(
      hour: int.tryParse(parts.first) ?? 9,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    ),
  );
  if (picked == null) return null;
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(picked.hour)}:${two(picked.minute)}';
}

/// A tappable time of day, for the shift and working hour rows.
class ClockField extends StatelessWidget {
  final String value;
  final ValueChanged<String>? onChanged;

  const ClockField({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged == null
          ? null
          : () async {
              final picked = await pickClock(context, value);
              if (picked != null) onChanged!(picked);
            },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.clock, size: 14.r, color: AppColors.primary),
            5.width,
            Text(
              value,
              textDirection: TextDirection.ltr,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
