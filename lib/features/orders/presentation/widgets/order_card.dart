import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/order.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../commons/widgets/effects/pressable.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
import '../../../../core/routing/app_routes.dart';

/// One order in a list. Tapping the card opens its details. When [onNextStep]
/// is given, the order's next step sits on the card as a button.
class OrderCard extends StatelessWidget {
  final OrderSummary order;
  final VoidCallback? onNextStep;
  final bool busy;

  const OrderCard({super.key, required this.order, this.onNextStep, this.busy = false});

  bool get _late =>
      order.overdueMin > 0 &&
      const [OrderStatus.pending, OrderStatus.confirmed, OrderStatus.waiting, OrderStatus.inService]
          .contains(order.status);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final next = order.nextAction;
    return Pressable(
      onTap: () => Get.toNamed(Routes.orderRoute, arguments: order.id),
      child: RoundedContainer(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(14.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42.r,
                  height: 42.r,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Icon(Iconsax.car, size: 21.r, color: AppColors.primary),
                ),
                12.width,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.plate, style: text.titleMedium),
                      Text(
                        [order.vehicleLabel, order.customerName]
                            .where((part) => part.isNotEmpty)
                            .join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
                order.status == OrderStatus.completed
                    ? StatusBadge.payment(order.paymentStatus)
                    : StatusBadge.order(order.status),
              ],
            ),
            10.height,
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.serviceName.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium,
                  ),
                ),
                Text(FormatHelper.money(order.total), style: text.titleSmall),
              ],
            ),
            4.height,
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${FormatHelper.dayTime(order.scheduledAt)} · ${'source.${order.source.key}'.tr} · ${order.number}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelSmall,
                  ),
                ),
                if (_late)
                  Text(
                    'orders.late'.trParams({'min': '${order.overdueMin}'}),
                    style: text.labelSmall?.copyWith(color: AppColors.danger),
                  )
                else if (next != null && onNextStep == null)
                  Text(
                    'action.${next.key}'.tr,
                    style: text.labelMedium?.copyWith(color: AppColors.primary),
                  ),
              ],
            ),
            if (next != null && onNextStep != null) ...[
              12.height,
              AppButton(
                title: 'action.${next.key}'.tr,
                small: true,
                loading: busy,
                onTap: onNextStep,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
