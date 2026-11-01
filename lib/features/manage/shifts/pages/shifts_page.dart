import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/shift.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../commons/widgets/effects/pressable.dart';
import '../../../../commons/widgets/layout/branch_picker.dart';
import '../../../../commons/widgets/layout/brand_header.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
import '../../../../core/routing/manage_pages.dart';
import '../../common/widgets/manage_cards.dart';
import '../../common/widgets/manage_page.dart';
import '../controllers/shifts_controller.dart';
import '../widgets/shift_status.dart';

class ShiftsPage extends GetView<ShiftsController> {
  const ShiftsPage({super.key});

  String _label(String filter, Map<String, int> counts) {
    final name = 'shifts.filter.$filter'.tr;
    final count = counts[filter];
    return count == null ? name : '$name ($count)';
  }

  @override
  Widget build(BuildContext context) {
    final branches = controller.session.account.value?.branches ?? const [];
    return ManagePage(
      title: 'more.shifts'.tr,
      trailing: HeaderButton(
        icon: Iconsax.calendar_tick,
        onTap: () => Get.toNamed(ManageRoutes.dayClosingRoute),
      ),
      headerChild: branches.length > 1 ? const BranchPickerChip() : null,
      body: Column(
        children: [
          Obx(() {
            final counts = controller.counts;
            return ChipBar<String>(
              values: ShiftsController.filters,
              selected: controller.filter.value,
              label: (filter) => _label(filter, counts),
              onSelect: controller.selectFilter,
            );
          }),
          Expanded(child: Obx(_list)),
        ],
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
      emptyIcon: Iconsax.timer_1,
      emptyTitle: 'shifts.empty'.tr,
      header: Padding(
        padding: EdgeInsets.only(bottom: 12.h),
        child: TileGrid(
          tiles: [
            StatTile(
              label: 'shifts.expectedCash'.tr,
              value: controller.totals.expected,
              format: FormatHelper.money,
            ),
            StatTile(
              label: 'shifts.totalDifference'.tr,
              value: controller.totals.difference,
              format: FormatHelper.money,
              color: controller.totals.difference < 0 ? AppColors.danger : null,
            ),
          ],
        ),
      ),
      itemBuilder: (_, index) => _ShiftCard(shift: items[index]),
    );
  }
}

class _ShiftCard extends StatelessWidget {
  final Shift shift;

  const _ShiftCard({required this.shift});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final difference = shift.difference ?? 0;
    return Pressable(
      onTap: () => Get.toNamed(ManageRoutes.shiftRoute, arguments: shift.id),
      child: RoundedContainer(
        padding: EdgeInsets.all(14.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InitialsAvatar(name: shift.staffName, size: 38.r),
                10.width,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(shift.staffName, style: text.titleSmall),
                      if (shift.scheduledStart != null)
                        Text(FormatHelper.dayTime(shift.scheduledStart!), style: text.bodySmall),
                    ],
                  ),
                ),
                ShiftStatusBadge(status: shift.status),
              ],
            ),
            10.height,
            Row(
              children: [
                Expanded(
                  child: Text(
                    'shifts.expectedLine'.trParams({'amount': FormatHelper.money(shift.expectedCash)}),
                    style: text.bodySmall,
                  ),
                ),
                if (difference != 0)
                  Text(
                    FormatHelper.money(difference),
                    textDirection: TextDirection.ltr,
                    style: text.titleSmall?.copyWith(
                      color: difference < 0 ? AppColors.danger : AppColors.warning,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
