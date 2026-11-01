import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../commons/widgets/layout/brand_header.dart';
import '../../../../commons/widgets/tabs/sliding_segment.dart';
import '../../../../commons/widgets/tabs/sliding_tabs.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/routing/app_routes.dart';
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
          trailing: HeaderButton(
            icon: Iconsax.search_normal_1,
            onTap: () => Get.toNamed(Routes.searchRoute),
          ),
          child: Obx(
            () => SlidingSegment<String>(
              items: OrdersController.tabs.keys.toList(),
              selected: controller.view.value,
              label: (view) => 'orders.view.$view'.tr,
              onSelect: controller.selectView,
            ),
          ),
        ),
        12.height,
        Obx(
          () => SlidingTabs<String>(
            // A new key per view, so the pill does not cross between two tab sets.
            key: ValueKey(controller.view.value),
            items: OrdersController.tabs[controller.view.value]!,
            selected: controller.tab.value,
            label: (tab) => _tabLabel(tab, controller.counts[tab]),
            onSelect: controller.selectTab,
          ),
        ),
        10.height,
        Expanded(
          child: Obx(
            () => AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: KeyedSubtree(key: ValueKey(controller.listKey), child: _list()),
            ),
          ),
        ),
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
              physics: const AlwaysScrollableScrollPhysics(),
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
                itemBuilder: (_, index) => OrderCard(key: ValueKey(orders[index].id), order: orders[index]),
              ),
            ),
    );
  }
}
