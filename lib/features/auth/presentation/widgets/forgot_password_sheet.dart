import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../commons/widgets/sheets/app_sheet.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/data/vendor_api.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/phone_helper.dart';
import '../../../../core/network/api_client.dart';

/// Asks the server for a reset link (GAP-044). The answer is the same for any
/// number, so it is shown as it comes; the link opens the partner web portal.
class ForgotPasswordSheet extends StatefulWidget {
  final String initialPhone;
  final PhoneCountry initialCountry;

  const ForgotPasswordSheet({super.key, this.initialPhone = '', required this.initialCountry});

  @override
  State<ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<ForgotPasswordSheet> {
  late final _phone = TextEditingController(text: widget.initialPhone);
  late PhoneCountry _country = widget.initialCountry;
  bool _busy = false;
  String? _error;

  /// The server's answer once sent.
  String? _answer;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_busy) return;
    final parsed = PhoneHelper.parse(_phone.text, _country);
    if (parsed == null) {
      setState(() => _error = 'auth.badPhone'.trParams({'example': _country.exampleLtr}));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _country = parsed.country;
    });
    try {
      final answer = await Get.find<VendorApi>().forgotPassword(phone: PhoneHelper.forApi(parsed));
      if (mounted) setState(() => _answer = answer ?? 'auth.forgotSent'.tr);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'error.offline'.tr);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final answer = _answer;
    if (answer != null) {
      return AppSheetBody(
        title: 'auth.forgotTitle'.tr,
        children: [
          Text(answer, style: text.bodyMedium),
          18.height,
          AppButton(title: 'common.close'.tr, onTap: () => Navigator.of(context).pop()),
        ],
      );
    }
    return AppSheetBody(
      title: 'auth.forgotTitle'.tr,
      subtitle: 'auth.forgotBody'.tr,
      children: [
        PhoneField(
          controller: _phone,
          label: 'auth.phone'.tr,
          country: _country,
          onCountryChanged: (c) => setState(() => _country = c),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _send(),
        ),
        if (_error != null) ...[
          8.height,
          Text(_error!, style: text.bodySmall?.copyWith(color: AppColors.danger)),
        ],
        18.height,
        AppButton(title: 'auth.forgotSend'.tr, loading: _busy, onTap: _send),
      ],
    );
  }
}
