import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/customer.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../commons/widgets/effects/pressable.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
import '../../../../core/routing/app_routes.dart';
import '../../common/widgets/manage_cards.dart';
import '../../common/widgets/manage_page.dart';
import '../controllers/customers_controller.dart';
import 'customers_page.dart';

class CustomerDetailsPage extends GetView<CustomerDetailsController> {
  const CustomerDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final details = controller.data.value;
      return ManagePage(
        title: details?.name ?? 'customers.details'.tr,
        subtitle: details?.phone,
        trailing: details == null
            ? null
            : StatusBadge(
                label: labelOr('customers.segment.${details.segment}', details.segment),
                color: segmentColor(details.segment),
              ),
        body: manageLoader(
          ready: details != null,
          error: controller.error.value,
          onRetry: controller.load,
          content: () => _content(context, details!),
        ),
      );
    });
  }

  Widget _content(BuildContext context, CustomerDetails details) {
    final text = Theme.of(context).textTheme;
    return ManageScroll(
      onRefresh: () => controller.load(silent: true),
      children: [
        TileGrid(
          tiles: [
            StatTile(label: 'customers.visits'.tr, value: details.visits, icon: Iconsax.calendar_1),
            StatTile(
              label: 'customers.totalSpent'.tr,
              value: details.totalSpent,
              format: FormatHelper.money,
              icon: Iconsax.wallet_2,
            ),
            StatTile(
              label: 'customers.avgTicket'.tr,
              value: details.avgTicket,
              format: FormatHelper.money,
              icon: Iconsax.receipt_2,
            ),
            StatTile(
              label: 'customers.cancellations'.tr,
              value: details.cancellations + details.noShows,
              icon: Iconsax.close_circle,
            ),
          ],
        ),
        12.height,
        if (details.vehicles.isNotEmpty)
          SectionCard(
            title: 'customers.vehicles'.tr,
            children: [
              for (final vehicle in details.vehicles)
                InfoRow(vehicle.label.isEmpty ? '-' : vehicle.label, vehicle.plate),
            ],
          ),
        if (details.favoriteServices.isNotEmpty)
          SectionCard(
            title: 'customers.favorites'.tr,
            children: [
              for (final service in details.favoriteServices)
                InfoRow(service.name.shown, FormatHelper.number(service.count)),
            ],
          ),
        SectionCard(
          title: 'customers.orders'.tr,
          children: [
            if (details.orders.isEmpty) Text('customers.noOrders'.tr, style: text.bodySmall),
            for (final order in details.orders) _OrderRow(order: order),
          ],
        ),
        if (details.reviews.isNotEmpty)
          SectionCard(
            title: 'more.reviews'.tr,
            children: [for (final review in details.reviews) _ReviewRow(review: review)],
          ),
      ],
    );
  }
}

class _OrderRow extends StatelessWidget {
  final CustomerOrder order;

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
                  Text(order.serviceName.shown, style: text.titleSmall),
                  Text(
                    [
                      order.number,
                      if (order.scheduledAt != null) FormatHelper.dayTime(order.scheduledAt!),
                    ].join(' · '),
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
            8.width,
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(FormatHelper.money(order.total), style: text.titleSmall),
                4.height,
                StatusBadge.order(OrderStatus.fromKey(order.status)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final CustomerReview review;

  const _ReviewRow({required this.review});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var star = 1; star <= 5; star++)
                Icon(
                  Iconsax.star1,
                  size: 14.r,
                  color: star <= review.stars ? AppColors.star : AppColors.line,
                ),
            ],
          ),
          if (review.comment.shown.isNotEmpty) ...[
            4.height,
            Text(review.comment.shown, style: text.bodySmall),
          ],
        ],
      ),
    );
  }
}
