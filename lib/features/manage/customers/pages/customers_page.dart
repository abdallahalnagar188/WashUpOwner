import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/customer.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../commons/widgets/effects/pressable.dart';
import '../../../../commons/widgets/layout/branch_picker.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
import '../../../../core/routing/manage_pages.dart';
import '../../common/widgets/manage_cards.dart';
import '../../common/widgets/manage_page.dart';
import '../controllers/customers_controller.dart';

Color segmentColor(String segment) => switch (segment) {
      'new' => AppColors.info,
      'returning' => AppColors.success,
      'lost' => AppColors.danger,
      _ => AppColors.statusNoShow,
    };

class CustomersPage extends GetView<CustomersController> {
  const CustomersPage({super.key});

  String _label(String segment, Map<String, int> counts) {
    final name = 'customers.segment.$segment'.tr;
    final count = counts[segment];
    return count == null ? name : '$name ($count)';
  }

  @override
  Widget build(BuildContext context) {
    final branches = controller.session.account.value?.branches ?? const [];
    return ManagePage(
      title: 'more.customers'.tr,
      headerChild: branches.length > 1 ? const BranchPickerChip() : null,
      body: Column(
        children: [
          Obx(() {
            final counts = controller.counts;
            return ChipBar<String>(
              values: CustomersController.segments,
              selected: controller.segment.value,
              label: (segment) => _label(segment, counts),
              onSelect: controller.selectSegment,
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
      emptyIcon: Iconsax.profile_2user,
      emptyTitle: 'customers.empty'.tr,
      itemBuilder: (_, index) => _CustomerCard(customer: items[index]),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Customer customer;

  const _CustomerCard({required this.customer});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Pressable(
      onTap: () => Get.toNamed(ManageRoutes.customerRoute, arguments: customer.id),
      child: RoundedContainer(
        padding: EdgeInsets.all(14.r),
        child: Row(
          children: [
            InitialsAvatar(name: customer.name, size: 42.r),
            10.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer.name, style: text.titleSmall),
                  if (customer.phone.isNotEmpty) LtrText(customer.phone, style: text.bodySmall),
                  3.height,
                  Text(
                    'customers.line'.trParams({
                      'visits': '${customer.visits}',
                      'spent': FormatHelper.money(customer.totalSpent),
                    }),
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
            8.width,
            StatusBadge(
              label: labelOr('customers.segment.${customer.segment}', customer.segment),
              color: segmentColor(customer.segment),
            ),
          ],
        ),
      ),
    );
  }
}
