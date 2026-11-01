import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/managed_branch.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../commons/widgets/effects/pressable.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
import '../../common/widgets/manage_cards.dart';
import '../../common/widgets/manage_page.dart';
import '../../common/widgets/manage_sheets.dart';
import '../controllers/branches_controller.dart';
import '../widgets/branch_details_sheet.dart';

class BranchesPage extends GetView<BranchesController> {
  const BranchesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ManagePage(
      title: 'more.branches'.tr,
      body: Obx(
        () => manageLoader(
          ready: controller.data.value != null,
          error: controller.error.value,
          onRetry: controller.load,
          content: () {
            final branches = controller.data.value!;
            return ManageList(
              onRefresh: () => controller.load(silent: true),
              itemCount: branches.length,
              emptyIcon: Iconsax.building,
              emptyTitle: 'branches.empty'.tr,
              header: controller.isOwner
                  ? null
                  : NoticeCard(text: 'branches.ownerOnly'.tr, icon: Iconsax.lock_1),
              itemBuilder: (_, index) => _BranchCard(
                branch: branches[index],
                onTap: () => showManageSheet<void>(
                  context,
                  BranchDetailsSheet(branchId: branches[index].id),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BranchCard extends StatelessWidget {
  final ManagedBranch branch;
  final VoidCallback onTap;

  const _BranchCard({required this.branch, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Pressable(
      onTap: onTap,
      child: RoundedContainer(
        padding: EdgeInsets.all(14.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(branch.name.shown, style: text.titleSmall)),
                8.width,
                StatusBadge(
                  label: branch.active ? 'branches.active'.tr : 'branches.inactive'.tr,
                  color: branch.active ? AppColors.success : AppColors.statusNoShow,
                ),
              ],
            ),
            4.height,
            Text(branch.address.shown, style: text.bodySmall),
            4.height,
            Text(
              [
                labelOr('branches.area.${branch.area}', branch.area),
                'branches.capacity'.trParams({'count': '${branch.capacity}'}),
                if (branch.reviewCount > 0) '★ ${FormatHelper.number(branch.rating)}',
              ].join(' · '),
              style: text.bodySmall,
            ),
            10.height,
            Row(
              children: [
                _Count(label: 'branches.todayOrders'.tr, value: branch.todayOrders),
                _Count(label: 'branches.upcoming'.tr, value: branch.upcomingOrders),
                _Count(label: 'branches.services'.tr, value: branch.servicesCount),
                _Count(label: 'branches.staff'.tr, value: branch.staffCount),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Count extends StatelessWidget {
  final String label;
  final int value;

  const _Count({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        children: [
          Text(FormatHelper.number(value), style: text.titleSmall),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.labelSmall),
        ],
      ),
    );
  }
}
