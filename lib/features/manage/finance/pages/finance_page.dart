import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/finance_summary.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../commons/widgets/effects/animated_bar.dart';
import '../../../../commons/widgets/effects/pressable.dart';
import '../../../../commons/widgets/layout/branch_picker.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
import '../../../../core/routing/app_routes.dart';
import '../../common/widgets/manage_cards.dart';
import '../../common/widgets/manage_page.dart';
import '../controllers/finance_controller.dart';

class FinancePage extends GetView<FinanceController> {
  const FinancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final branches = controller.session.account.value?.branches ?? const [];
    return ManagePage(
      title: 'more.finance'.tr,
      headerChild: branches.length > 1 ? const BranchPickerChip() : null,
      body: Column(
        children: [
          Obx(
            () => ChipBar<String>(
              values: FinanceController.periods,
              selected: controller.period.value,
              label: (period) => 'finance.period.$period'.tr,
              onSelect: controller.selectPeriod,
            ),
          ),
          Expanded(
            child: Obx(
              () => manageLoader(
                ready: controller.data.value != null,
                error: controller.error.value,
                onRetry: controller.load,
                content: () => _content(context, controller.data.value!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, FinanceSummary finance) {
    final text = Theme.of(context).textTheme;
    final methodTotal = finance.byMethod.fold<num>(0, (sum, m) => sum + m.amount);
    final branchTotal = finance.byBranch.fold<num>(0, (sum, b) => sum + b.revenue);
    return ManageScroll(
      onRefresh: () => controller.load(silent: true),
      children: [
        TileGrid(
          tiles: [
            StatTile(label: 'finance.revenue'.tr, value: finance.revenue, format: FormatHelper.money, icon: Iconsax.wallet_money),
            StatTile(
              label: 'finance.commission'.trParams({'rate': FormatHelper.number(finance.commissionRate)}),
              value: finance.commission,
              format: FormatHelper.money,
              icon: Iconsax.percentage_circle,
            ),
            StatTile(
              label: 'finance.net'.tr,
              value: finance.net,
              format: FormatHelper.money,
              icon: Iconsax.wallet_2,
              color: AppColors.success,
            ),
            StatTile(label: 'finance.paidOrders'.tr, value: finance.paidOrders, icon: Iconsax.receipt_2),
            StatTile(label: 'finance.refunds'.tr, value: finance.refunds, format: FormatHelper.money, icon: Iconsax.money_recive),
            StatTile(label: 'finance.discounts'.tr, value: finance.discounts, format: FormatHelper.money, icon: Iconsax.discount_shape),
          ],
        ),
        12.height,
        SectionCard(
          title: 'finance.byMethod'.tr,
          children: [
            if (methodTotal == 0) Text('finance.noPayments'.tr, style: text.bodySmall),
            if (methodTotal != 0)
              for (final method in finance.byMethod)
                _ShareRow(
                  label: '${labelOr('method.${method.method}', method.method)} (${method.count})',
                  amount: method.amount,
                  share: method.amount / methodTotal,
                ),
          ],
        ),
        SectionCard(
          title: 'finance.byBranch'.tr,
          children: [
            for (final branch in finance.byBranch)
              _ShareRow(
                label: '${branch.name.shown} (${branch.orders})',
                amount: branch.revenue,
                share: branchTotal == 0 ? 0 : branch.revenue / branchTotal,
              ),
          ],
        ),
        SectionCard(
          title: 'finance.pending'.tr,
          action: finance.pendingCount > 0
              ? Text(
                  '${finance.pendingCount} · ${FormatHelper.money(finance.pendingAmount)}',
                  style: text.labelMedium?.copyWith(color: AppColors.warning),
                )
              : null,
          children: [
            if (finance.pendingOrders.isEmpty) Text('finance.noPending'.tr, style: text.bodySmall),
            for (final order in finance.pendingOrders) _PendingRow(order: order),
          ],
        ),
        SectionCard(
          title: 'finance.payouts'.tr,
          children: [
            if (finance.payouts.isEmpty) Text('finance.noPayouts'.tr, style: text.bodySmall),
            for (final payout in finance.payouts) _PayoutRow(payout: payout),
          ],
        ),
      ],
    );
  }
}

class _ShareRow extends StatelessWidget {
  final String label;
  final num amount;
  final double share;

  const _ShareRow({required this.label, required this.amount, required this.share});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: text.bodySmall)),
              8.width,
              Text(FormatHelper.money(amount), style: text.labelMedium),
            ],
          ),
          4.height,
          AnimatedBar(value: share),
        ],
      ),
    );
  }
}

class _PendingRow extends StatelessWidget {
  final PendingPayment order;

  const _PendingRow({required this.order});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Pressable(
      onTap: () => Get.toNamed(Routes.orderRoute, arguments: order.id),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 6.h),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.plate.isEmpty ? order.number : order.plate, style: text.titleSmall),
                  Text(
                    [order.number, order.serviceName.shown].where((part) => part.isNotEmpty).join(' · '),
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
            8.width,
            Text(FormatHelper.money(order.total), style: text.titleSmall),
          ],
        ),
      ),
    );
  }
}

class _PayoutRow extends StatelessWidget {
  final Payout payout;

  const _PayoutRow({required this.payout});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final start = payout.periodStart;
    final end = payout.periodEnd;
    final paid = payout.status == 'paid';
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(FormatHelper.money(payout.amountPaid ?? payout.amountDue), style: text.titleSmall),
                if (start != null && end != null)
                  Text('${FormatHelper.shortDay(start)} - ${FormatHelper.shortDay(end)}', style: text.bodySmall),
                if (payout.reference != null) LtrText(payout.reference!, style: text.labelSmall),
              ],
            ),
          ),
          StatusBadge(
            label: labelOr('finance.payout.${payout.status}', payout.status),
            color: paid ? AppColors.success : AppColors.warning,
          ),
        ],
      ),
    );
  }
}
