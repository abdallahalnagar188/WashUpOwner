import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/order.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
import '../../../../core/utils/utils.dart';
import '../controllers/order_details_controller.dart';

const Map<OrderAction, IconData> _icons = {
  OrderAction.confirm: Iconsax.tick_circle,
  OrderAction.checkIn: Iconsax.location_tick,
  OrderAction.start: Iconsax.play,
  OrderAction.complete: Iconsax.task_square,
  OrderAction.collectPayment: Iconsax.wallet_money,
  OrderAction.cancel: Iconsax.close_circle,
  OrderAction.noShow: Iconsax.user_remove,
  OrderAction.assign: Iconsax.user_tick,
  OrderAction.addService: Iconsax.add_circle,
  OrderAction.discount: Iconsax.discount_shape,
  OrderAction.note: Iconsax.note_1,
  OrderAction.refund: Iconsax.money_recive,
};

Future<void> showMoreActions(
  BuildContext context,
  OrderDetailsController controller,
  OrderDetails order,
  List<OrderAction> actions,
) {
  final text = Theme.of(context).textTheme;
  return showModalBottomSheet<void>(
    context: context,
    shape: _sheetShape,
    builder: (sheet) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          12.height,
          for (final action in actions)
            ListTile(
              leading: Icon(
                _icons[action],
                size: 22.r,
                color: _isDanger(action) ? AppColors.danger : AppColors.primary,
              ),
              title: Text(
                'action.${action.key}'.tr,
                style: text.titleSmall?.copyWith(
                  color: _isDanger(action) ? AppColors.danger : null,
                ),
              ),
              onTap: () {
                Navigator.of(sheet).pop();
                startOrderAction(context, controller, order, action);
              },
            ),
        ],
      ),
    ),
  );
}

bool _isDanger(OrderAction action) =>
    action == OrderAction.cancel || action == OrderAction.noShow || action == OrderAction.refund;

ShapeBorder get _sheetShape => RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
    );

/// Runs [action], asking first for whatever the server needs with it.
Future<void> startOrderAction(
  BuildContext context,
  OrderDetailsController controller,
  OrderDetails order,
  OrderAction action,
) async {
  switch (action) {
    case OrderAction.confirm:
    case OrderAction.checkIn:
    case OrderAction.complete:
      await controller.run(action);
    case OrderAction.noShow:
      final ok = await Utils.confirm(
        title: 'action.no_show'.tr,
        body: 'sheet.noShowBody'.tr,
        okText: 'action.no_show'.tr,
        danger: true,
      );
      if (ok) await controller.run(action);
    case OrderAction.start:
    case OrderAction.assign:
      if (order.assignableStaff.isEmpty) {
        await controller.run(action);
        return;
      }
      final staff = await _pick<NamedRef>(
        context,
        title: 'sheet.chooseStaff'.tr,
        items: order.assignableStaff,
        label: (item) => item.name,
      );
      if (staff != null) await controller.run(action, {'staffId': staff.id});
    case OrderAction.addService:
      final addon = await _pick<AddonOption>(
        context,
        title: 'action.add_service'.tr,
        items: order.availableAddons,
        label: (item) => '${item.name.value} · ${FormatHelper.money(item.price)}',
      );
      if (addon != null) await controller.run(action, {'serviceId': addon.id});
    case OrderAction.collectPayment:
      final fields = await _sheet<Map<String, dynamic>>(context, _CollectSheet(total: order.total));
      if (fields != null) await controller.run(action, fields);
    case OrderAction.discount:
      final fields = await _sheet<Map<String, dynamic>>(
        context,
        _DiscountSheet(order: order),
      );
      if (fields != null) await controller.run(action, fields);
    case OrderAction.note:
      final value = await _sheet<String>(context, _TextSheet(title: 'action.note'.tr));
      if (value != null) await controller.run(action, {'text': value});
    case OrderAction.cancel:
    case OrderAction.refund:
      final value = await _sheet<String>(
        context,
        _TextSheet(title: 'action.${action.key}'.tr, hint: 'sheet.reason'.tr, danger: true),
      );
      if (value != null) await controller.run(action, {'reason': value});
  }
}

Future<T?> _sheet<T>(BuildContext context, Widget child) => showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      shape: _sheetShape,
      builder: (sheet) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheet).bottom),
        child: SafeArea(child: child),
      ),
    );

Future<T?> _pick<T>(
  BuildContext context, {
  required String title,
  required List<T> items,
  required String Function(T) label,
}) {
  final text = Theme.of(context).textTheme;
  return showModalBottomSheet<T>(
    context: context,
    shape: _sheetShape,
    builder: (sheet) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Text(title, style: text.titleLarge),
          ),
          if (items.isEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 24.h),
              child: Text('sheet.nothing'.tr, style: text.bodySmall),
            ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final item in items)
                  ListTile(
                    title: Text(label(item), style: text.titleSmall),
                    onTap: () => Navigator.of(sheet).pop(item),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _SheetBody extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SheetBody({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 16.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          14.height,
          ...children,
        ],
      ),
    );
  }
}

/// Digits with one optional decimal point, so 29.5 stays 29.5.
final List<TextInputFormatter> _amountInput = [
  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
];

class _CollectSheet extends StatefulWidget {
  final num total;

  const _CollectSheet({required this.total});

  @override
  State<_CollectSheet> createState() => _CollectSheetState();
}

class _CollectSheetState extends State<_CollectSheet> {
  static const List<String> _methods = ['cash', 'card', 'online'];

  String _method = 'cash';
  late final TextEditingController _received =
      TextEditingController(text: FormatHelper.plain(widget.total));

  @override
  void dispose() {
    _received.dispose();
    super.dispose();
  }

  num? get _amount => num.tryParse(_received.text);

  bool get _valid => _method != 'cash' || (_amount != null && _amount! >= widget.total);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final change = (_amount ?? 0) - widget.total;
    return _SheetBody(
      title: 'sheet.collectTitle'.trParams({'amount': FormatHelper.money(widget.total)}),
      children: [
        Row(
          children: [
            for (final method in _methods) ...[
              AppChip(
                label: 'method.$method'.tr,
                selected: _method == method,
                onTap: () => setState(() => _method = method),
              ),
              8.width,
            ],
          ],
        ),
        if (_method == 'cash') ...[
          14.height,
          AppTextField(
            controller: _received,
            label: 'sheet.received'.tr,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: _amountInput,
            textDirection: TextDirection.ltr,
            onChanged: (_) => setState(() {}),
          ),
          if (change > 0) ...[
            8.height,
            Text(
              'sheet.change'.trParams({'amount': FormatHelper.money(change)}),
              style: text.bodySmall?.copyWith(color: AppColors.success),
            ),
          ],
        ],
        18.height,
        AppButton(
          title: 'action.collect_payment'.tr,
          onTap: _valid
              ? () => Navigator.of(context).pop({
                    'method': _method,
                    'amountReceived': _method == 'cash' ? _amount : widget.total,
                  })
              : null,
        ),
      ],
    );
  }
}

class _DiscountSheet extends StatefulWidget {
  final OrderDetails order;

  const _DiscountSheet({required this.order});

  @override
  State<_DiscountSheet> createState() => _DiscountSheetState();
}

class _DiscountSheetState extends State<_DiscountSheet> {
  String _type = 'percent';
  final _value = TextEditingController();
  final _reason = TextEditingController();

  @override
  void dispose() {
    _value.dispose();
    _reason.dispose();
    super.dispose();
  }

  num? get _number => num.tryParse(_value.text);

  /// Null when the value is usable, otherwise why it is not.
  String? get _problem {
    final value = _number;
    if (value == null || value <= 0) return null;
    final total = widget.order.total;
    final pct = _type == 'percent' ? value : (total == 0 ? 0 : value / total * 100);
    if (pct > widget.order.maxDiscountPct) {
      return 'sheet.maxDiscount'.trParams({'pct': FormatHelper.number(widget.order.maxDiscountPct)});
    }
    return null;
  }

  bool get _valid =>
      (_number ?? 0) > 0 && _problem == null && _reason.text.trim().length >= 2;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final problem = _problem;
    return _SheetBody(
      title: 'action.discount'.tr,
      children: [
        Row(
          children: [
            AppChip(
              label: 'sheet.percent'.tr,
              selected: _type == 'percent',
              onTap: () => setState(() => _type = 'percent'),
            ),
            8.width,
            AppChip(
              label: 'sheet.fixed'.tr,
              selected: _type == 'fixed',
              onTap: () => setState(() => _type = 'fixed'),
            ),
          ],
        ),
        14.height,
        AppTextField(
          controller: _value,
          label: 'sheet.discountValue'.tr,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: _amountInput,
          textDirection: TextDirection.ltr,
          onChanged: (_) => setState(() {}),
        ),
        if (problem != null) ...[
          6.height,
          Text(problem, style: text.bodySmall?.copyWith(color: AppColors.danger)),
        ],
        12.height,
        AppTextField(
          controller: _reason,
          label: 'sheet.reason'.tr,
          onChanged: (_) => setState(() {}),
        ),
        18.height,
        AppButton(
          title: 'action.discount'.tr,
          onTap: _valid
              ? () => Navigator.of(context).pop({
                    'discountType': _type,
                    'discountValue': _number,
                    'reason': _reason.text.trim(),
                  })
              : null,
        ),
      ],
    );
  }
}

class _TextSheet extends StatefulWidget {
  final String title;
  final String? hint;
  final bool danger;

  const _TextSheet({required this.title, this.hint, this.danger = false});

  @override
  State<_TextSheet> createState() => _TextSheetState();
}

class _TextSheetState extends State<_TextSheet> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final valid = _input.text.trim().length >= 2;
    return _SheetBody(
      title: widget.title,
      children: [
        AppTextField(
          controller: _input,
          label: widget.hint,
          maxLines: 3,
          autofocus: true,
          onChanged: (_) => setState(() {}),
        ),
        18.height,
        AppButton(
          title: widget.title,
          variant: widget.danger ? AppButtonVariant.danger : AppButtonVariant.primary,
          onTap: valid ? () => Navigator.of(context).pop(_input.text.trim()) : null,
        ),
      ],
    );
  }
}
