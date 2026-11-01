import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/shift.dart';
import '../../../../commons/widgets/effects/pressable.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/helpers/format_helper.dart';
import '../../../../core/routing/app_routes.dart';
import '../../common/widgets/manage_cards.dart';
import '../../common/widgets/manage_page.dart';
import '../controllers/shift_details_controller.dart';
import '../widgets/shift_review_form.dart';
import '../widgets/shift_status.dart';

class ShiftDetailsPage extends GetView<ShiftDetailsController> {
  const ShiftDetailsPage({super.key});

  String _range(DateTime? start, DateTime? end) {
    if (start == null) return '-';
    return end == null
        ? FormatHelper.dayTime(start)
        : '${FormatHelper.time(start)} - ${FormatHelper.time(end)}';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final details = controller.data.value;
      return ManagePage(
        title: details?.shift.staffName ?? 'shifts.details'.tr,
        subtitle: details?.shift.branchName.shown,
        trailing: details == null ? null : ShiftStatusBadge(status: details.shift.status),
        body: manageLoader(
          ready: details != null,
          error: controller.error.value,
          onRetry: controller.load,
          content: () => _content(context, details!),
        ),
      );
    });
  }

  Widget _content(BuildContext context, ShiftDetails details) {
    final shift = details.shift;
    final text = Theme.of(context).textTheme;
    return ManageScroll(
      onRefresh: () => controller.load(silent: true),
      children: [
        SectionCard(
          title: 'shifts.cash'.tr,
          children: [
            InfoRow('shifts.expectedCash'.tr, FormatHelper.money(shift.expectedCash)),
            InfoRow(
              'shifts.actualCash'.tr,
              shift.actualCash == null ? 'shifts.notHanded'.tr : FormatHelper.money(shift.actualCash!),
            ),
            InfoRow(
              'shifts.difference'.tr,
              shift.difference == null ? '-' : FormatHelper.money(shift.difference!),
              strong: true,
            ),
            InfoRow('shifts.cashPayments'.tr, FormatHelper.money(shift.cashPayments)),
            InfoRow('shifts.cardPayments'.tr, FormatHelper.money(shift.cardPayments)),
            InfoRow('shifts.ordersCompleted'.tr, FormatHelper.number(shift.ordersCompleted)),
          ],
        ),
        SectionCard(
          title: 'shifts.times'.tr,
          children: [
            InfoRow('shifts.scheduled'.tr, _range(shift.scheduledStart, shift.scheduledEnd)),
            InfoRow('shifts.actual'.tr, _range(shift.actualStart, shift.actualEnd)),
            if (shift.reason != null) InfoRow('shifts.reason'.tr, shift.reason!),
            if (shift.reviewNote != null)
              InfoRow(
                shift.reviewedBy == null
                    ? 'shifts.reviewNote'.tr
                    : '${'shifts.reviewNote'.tr} (${shift.reviewedBy})',
                shift.reviewNote!,
              ),
          ],
        ),
        SectionCard(
          title: 'shifts.orders'.trParams({'count': '${details.orders.length}'}),
          children: [
            if (details.orders.isEmpty) Text('shifts.noOrders'.tr, style: text.bodySmall),
            for (final order in details.orders) _OrderRow(order: order),
          ],
        ),
        if (shift.isOpen)
          NoticeCard(text: 'shifts.stillOpen'.tr, icon: Iconsax.info_circle)
        else if (!controller.canReview)
          NoticeCard(text: 'shifts.noPermission'.tr, icon: Iconsax.lock_1)
        else
          ShiftReviewForm(status: shift.status, onSubmit: controller.review),
      ],
    );
  }
}

class _OrderRow extends StatelessWidget {
  final ShiftOrder order;

  const _OrderRow({required this.order});

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
                  Text(order.number, style: text.titleSmall),
                  Text(
                    [
                      if (order.plate.isNotEmpty) order.plate,
                      if (order.method != null) labelOr('method.${order.method}', order.method!),
                    ].join(' · '),
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(FormatHelper.money(order.total), style: text.titleSmall),
                if (!order.paid)
                  Text('pay.pending'.tr, style: text.labelSmall?.copyWith(color: AppColors.warning)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
