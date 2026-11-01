import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/app_notification.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../commons/widgets/effects/pressable.dart';
import '../../../../commons/widgets/layout/brand_header.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
import '../../common/widgets/manage_page.dart';
import '../controllers/notifications_controller.dart';
import '../../common/widgets/manage_cards.dart';

class NotificationsPage extends GetView<NotificationsController> {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => ManagePage(
        title: 'notifications.title'.tr,
        subtitle: controller.unread > 0
            ? 'notifications.unreadCount'.trParams({'count': '${controller.unread}'})
            : null,
        trailing: controller.unread > 0
            ? HeaderButton(icon: Iconsax.tick_square, onTap: controller.readAll)
            : null,
        body: Column(
          children: [
            ChipBar<String>(
              values: NotificationsController.filters,
              selected: controller.filter.value,
              label: (filter) => 'notifications.filter.$filter'.tr,
              onSelect: controller.selectFilter,
            ),
            Expanded(child: _list()),
          ],
        ),
      ),
    );
  }

  Widget _list() {
    if (controller.loading.value) return const AppShimmerList();
    if (controller.error.value != null) {
      return AppErrorState(message: controller.error.value, onRetry: controller.load);
    }
    final items = controller.items;
    return ManageList(
      onRefresh: controller.load,
      onLoadMore: controller.loadMore,
      loadingMore: controller.loadingMore.value,
      itemCount: items.length,
      emptyIcon: Iconsax.notification,
      emptyTitle: 'notifications.empty'.tr,
      itemBuilder: (_, index) => _NotificationCard(
        item: items[index],
        onTap: () => controller.open(items[index]),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification item;
  final VoidCallback onTap;

  const _NotificationCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Pressable(
      onTap: onTap,
      child: RoundedContainer(
        color: item.read ? null : AppColors.primarySoft,
        padding: EdgeInsets.all(14.r),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 9.r,
              height: 9.r,
              margin: EdgeInsetsDirectional.only(top: 5.h, end: 10.w),
              decoration: BoxDecoration(
                color: item.read ? AppColors.line : AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title.shown, style: text.titleSmall),
                  if (item.body.shown.isNotEmpty) ...[
                    3.height,
                    Text(item.body.shown, style: text.bodySmall),
                  ],
                  if (item.createdAt != null) ...[
                    5.height,
                    Text(FormatHelper.dayTime(item.createdAt!), style: text.labelSmall),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
