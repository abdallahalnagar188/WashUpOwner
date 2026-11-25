import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../commons/widgets/sheets/app_sheet.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/data/vendor_api.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/form_rules.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/utils.dart';

/// Changes the signed-in account's password, e.g. to replace the temporary one
/// the owner handed over (GAP-044).
class ChangePasswordSheet extends StatefulWidget {
  const ChangePasswordSheet({super.key});

  /// Null when the three fields can be sent, otherwise why not.
  static String? problem({required String current, required String next, required String repeat}) {
    if (current.isEmpty || next.isEmpty) return null;
    if (next.length < FormRules.passwordMin) return 'password.tooShort'.trParams({'min': '${FormRules.passwordMin}'});
    if (next == current) return 'password.same'.tr;
    if (repeat.isNotEmpty && repeat != next) return 'password.mismatch'.tr;
    return null;
  }

  @override
  State<ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<ChangePasswordSheet> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _repeat = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _repeat.dispose();
    super.dispose();
  }

  String? get _problem =>
      ChangePasswordSheet.problem(current: _current.text, next: _next.text, repeat: _repeat.text);

  bool get _ready =>
      _current.text.isNotEmpty && _next.text.isNotEmpty && _repeat.text == _next.text && _problem == null;

  Future<void> _save() async {
    if (_busy || !_ready) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final outcome = await Get.find<VendorApi>().changePassword(
        currentPassword: _current.text,
        newPassword: _next.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      Utils.getSnakBar(message: outcome ?? 'password.changed'.tr, type: TosterTypes.sucsses);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'error.offline'.tr);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _field(TextEditingController controller, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AppTextField(
          dense: true,
          controller: controller,
          label: label,
          obscureText: true,
          textDirection: TextDirection.ltr,
          onChanged: (_) => setState(() {}),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final message = _error ?? _problem;
    return AppSheetBody(
      title: 'password.title'.tr,
      subtitle: 'password.body'.trParams({'min': '${FormRules.passwordMin}'}),
      children: [
        _field(_current, 'password.current'.tr),
        _field(_next, 'password.new'.tr),
        _field(_repeat, 'password.repeat'.tr),
        if (message != null) ...[
          Text(message, style: text.bodySmall?.copyWith(color: AppColors.danger)),
          8.height,
        ],
        10.height,
        AppButton(title: 'password.save'.tr, loading: _busy, onTap: _ready ? _save : null),
      ],
    );
  }
}
