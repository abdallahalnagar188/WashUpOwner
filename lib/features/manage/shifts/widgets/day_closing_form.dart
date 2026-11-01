import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../commons/models/day_closing.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
import '../../../../core/utils/utils.dart';
import '../../common/widgets/amount_input.dart';
import '../../common/widgets/manage_cards.dart';

/// End of day count: actual amounts against what the orders say. Cash starts
/// empty so it gets counted; card and online start at the expected amount.
class DayClosingForm extends StatefulWidget {
  final DayClosing day;
  final Future<bool> Function({required num cash, required num card, required num online, String? reason})
      onSubmit;

  const DayClosingForm({super.key, required this.day, required this.onSubmit});

  @override
  State<DayClosingForm> createState() => _DayClosingFormState();
}

class _DayClosingFormState extends State<DayClosingForm> {
  final _cash = TextEditingController();
  late final _card = TextEditingController(text: FormatHelper.plain(widget.day.expected.card));
  late final _online = TextEditingController(text: FormatHelper.plain(widget.day.expected.online));
  final _reason = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    for (final input in [_cash, _card, _online, _reason]) {
      input.dispose();
    }
    super.dispose();
  }

  num get _cashValue => parseAmount(_cash.text) ?? 0;

  num get _cardValue => parseAmount(_card.text) ?? 0;

  num get _onlineValue => parseAmount(_online.text) ?? 0;

  num get _total => _cashValue + _cardValue + _onlineValue;

  num get _difference => ((_total - widget.day.expected.total) * 100).round() / 100;

  bool get _filled =>
      parseAmount(_cash.text) != null && parseAmount(_card.text) != null && parseAmount(_online.text) != null;

  bool get _hasDifference => _difference.abs() > 0.001;

  bool get _valid =>
      !_busy &&
      !widget.day.hasOpenOrders &&
      _filled &&
      (!_hasDifference || _reason.text.trim().length >= 3);

  Future<void> _submit() async {
    final ok = await Utils.confirm(
      title: 'closing.confirmTitle'.tr,
      body: 'closing.confirmBody'.trParams({
        'expected': FormatHelper.money(widget.day.expected.total),
        'actual': FormatHelper.money(_total),
        'count': '${widget.day.paidOrders}',
      }),
      okText: 'closing.confirm'.tr,
      danger: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    await widget.onSubmit(
      cash: _cashValue,
      card: _cardValue,
      online: _onlineValue,
      reason: _reason.text.trim(),
    );
    if (mounted) setState(() => _busy = false);
  }

  Widget _amount(String method, TextEditingController input) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: AppTextField(
        controller: input,
        label: 'closing.actual'.trParams({
          'method': 'method.$method'.tr,
          'amount': FormatHelper.money(widget.day.expected.of(method)),
        }),
        keyboardType: amountKeyboard,
        inputFormatters: amountInput,
        textDirection: TextDirection.ltr,
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'closing.settle'.tr,
      children: [
        _amount('cash', _cash),
        _amount('card', _card),
        _amount('online', _online),
        InfoRow('closing.total'.tr, FormatHelper.money(_total), strong: true),
        if (_filled)
          Text(
            _hasDifference
                ? 'closing.differenceValue'.trParams({'amount': FormatHelper.money(_difference)})
                : 'closing.matched'.tr,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _hasDifference ? AppColors.danger : AppColors.success,
                ),
          ),
        if (_hasDifference) ...[
          12.height,
          AppTextField(
            controller: _reason,
            label: 'closing.differenceReason'.tr,
            maxLines: 2,
            onChanged: (_) => setState(() {}),
          ),
        ],
        16.height,
        AppButton(
          title: 'closing.submit'.tr,
          loading: _busy,
          onTap: _valid ? _submit : null,
        ),
      ],
    );
  }
}
