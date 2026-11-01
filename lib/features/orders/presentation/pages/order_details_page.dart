import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/order.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../commons/widgets/layout/brand_header.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
import '../controllers/order_details_controller.dart';
import '../widgets/order_action_sheets.dart';
import '../widgets/order_timeline.dart';

class OrderDetailsPage extends GetView<OrderDetailsController> {
  const OrderDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        final order = controller.order.value;
        if (order == null) {
          return Column(
            children: [
              BrandHeader(title: 'orders.details'.tr, leading: const _BackButton()),
              Expanded(
                child: controller.error.value != null
                    ? AppErrorState(message: controller.error.value, onRetry: controller.load)
                    : const AppShimmerList(),
              ),
            ],
          );
        }
        return Column(
          children: [
            BrandHeader(
              title: order.plate,
              subtitle: order.number,
              leading: const _BackButton(),
              // White on the blue header; the status colors are made for white cards.
              trailing: StatusBadge(
                label: order.status == OrderStatus.completed
                    ? 'pay.${order.paymentStatus.name}'.tr
                    : 'status.${order.status.key}'.tr,
                color: Colors.white,
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.load,
                child: ListView(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
                  children: [
                    FadeSlideIn(child: _InfoCard(order: order)),
                    12.height,
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 70),
                      child: _ItemsCard(order: order),
                    ),
                    if (order.timeline.isNotEmpty) ...[
                      12.height,
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 140),
                        child: RoundedContainer(
                          padding: EdgeInsets.all(16.r),
                          child: OrderTimeline(entries: order.timeline),
                        ),
                      ),
                    ],
                    if (order.notes.isNotEmpty) ...[
                      12.height,
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 200),
                        child: _NotesCard(notes: order.notes),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            _ActionBar(order: order),
          ],
        );
      }),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return HeaderButton(
      icon: Directionality.of(context) == TextDirection.rtl ? Iconsax.arrow_right_3 : Iconsax.arrow_left_2,
      onTap: Get.back,
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;

  const _Row(this.label, this.value, {this.strong = false});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: strong ? text.titleSmall : text.bodySmall),
          12.width,
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: strong ? text.titleMedium : text.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final OrderDetails order;

  const _InfoCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return RoundedContainer(
      padding: EdgeInsets.all(16.r),
      child: Column(
        children: [
          if (order.customerName != null) _Row('orders.customer'.tr, order.customerName!),
          if (order.customerPhone != null) _Row('orders.phone'.tr, order.customerPhone!),
          if (order.vehicleLabel != null) _Row('orders.vehicle'.tr, order.vehicleLabel!),
          _Row('orders.time'.tr, FormatHelper.dayTime(order.scheduledAt)),
          _Row('orders.source'.tr, 'source.${order.source.key}'.tr),
          if (order.staffName != null) _Row('orders.staff'.tr, order.staffName!),
          if (order.code != null) _Row('orders.code'.tr, order.code!),
        ],
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  final OrderDetails order;

  const _ItemsCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return RoundedContainer(
      padding: EdgeInsets.all(16.r),
      child: Column(
        children: [
          for (final item in order.items) _Row(item.name.value, FormatHelper.money(item.price)),
          Divider(color: AppColors.line, height: 18.h),
          if (order.discountAmount > 0) ...[
            _Row('orders.subtotal'.tr, FormatHelper.money(order.subtotal)),
            _Row('orders.discount'.tr, '- ${FormatHelper.money(order.discountAmount)}'),
          ],
          _Row('orders.total'.tr, FormatHelper.money(order.total), strong: true),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  final List<OrderNote> notes;

  const _NotesCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return RoundedContainer(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('orders.notes'.tr, style: text.titleSmall),
          6.height,
          for (final note in notes)
            Padding(
              padding: EdgeInsets.only(bottom: 4.h),
              child: Text(note.text, style: text.bodyMedium),
            ),
        ],
      ),
    );
  }
}

class _ActionBar extends GetView<OrderDetailsController> {
  final OrderDetails order;

  const _ActionBar({required this.order});

  @override
  Widget build(BuildContext context) {
    final primary = controller.primaryAction;
    final others = controller.otherActions;
    if (primary == null && others.isEmpty) return empty;
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 12.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppColors.liftShadow,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (others.isNotEmpty) ...[
              AppIconButton(
                icon: Icon(Iconsax.more, size: 22.r, color: AppColors.ink900),
                onTap: () => showMoreActions(context, controller, order, others),
              ),
              if (primary != null) 10.width,
            ],
            if (primary != null)
              Expanded(
                child: AppButton(
                  title: 'action.${primary.key}'.tr,
                  loading: controller.busy.value,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    startOrderAction(context, controller, order, primary);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
