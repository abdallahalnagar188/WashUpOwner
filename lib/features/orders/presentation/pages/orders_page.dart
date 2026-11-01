import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../commons/widgets/layout/brand_header.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../controllers/orders_controller.dart';
import '../widgets/order_card.dart';

class OrdersPage extends GetView<OrdersController> {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BrandHeader(
          title: 'orders.title'.tr,
          child: Obx(
            () => _ViewSwitch(selected: controller.view.value, onSelect: controller.selectView),
          ),
        ),
        12.height,
        Obx(
          () => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              children: [
                for (final tab in OrdersController.tabs[controller.view.value]!) ...[
                  AppChip(
                    label: _tabLabel(tab, controller.counts[tab]),
                    selected: controller.tab.value == tab,
                    onTap: () => controller.selectTab(tab),
                  ),
                  8.width,
                ],
              ],
            ),
          ),
        ),
        10.height,
        Expanded(child: Obx(_list)),
      ],
    );
  }

  String _tabLabel(String tab, int? count) =>
      count == null ? 'orders.tab.$tab'.tr : '${'orders.tab.$tab'.tr} ($count)';

  Widget _list() {
    if (controller.loading.value) return const AppShimmerList();
    if (controller.error.value != null) {
      return AppErrorState(message: controller.error.value, onRetry: controller.load);
    }
    final orders = controller.orders;
    return RefreshIndicator(
      onRefresh: controller.load,
      child: orders.isEmpty
          ? ListView(
              children: [
                SizedBox(
                  height: 260.h,
                  child: CustomEmptyState(icon: Iconsax.receipt_2, title: 'orders.empty'.tr),
                ),
              ],
            )
          : NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification.metrics.extentAfter < 300) controller.loadMore();
                return false;
              },
              child: ListView.builder(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                padding: EdgeInsets.fromLTRB(20.w, 2.h, 20.w, 120.h),
                itemCount: orders.length,
                itemBuilder: (_, index) => FadeSlideIn(
                  key: ValueKey(orders[index].id),
                  delay: Duration(milliseconds: 40 * index.clamp(0, 6)),
                  child: OrderCard(order: orders[index]),
                ),
              ),
            ),
    );
  }
}

class _ViewSwitch extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _ViewSwitch({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final views = OrdersController.tabs.keys.toList();
    return Container(
      height: 40.h,
      padding: EdgeInsets.all(3.r),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        children: [
          for (final view in views)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelect(view),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: view == selected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    'orders.view.$view'.tr,
                    style: text.labelLarge?.copyWith(
                      color: view == selected ? AppColors.brand : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
