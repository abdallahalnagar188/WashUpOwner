import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/staff_member.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../commons/widgets/effects/pressable.dart';
import '../../../../commons/widgets/layout/branch_picker.dart';
import '../../../../commons/widgets/layout/brand_header.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
import '../../common/widgets/manage_page.dart';
import '../../common/widgets/manage_sheets.dart';
import '../controllers/staff_controller.dart';
import '../widgets/staff_details_sheet.dart';
import '../widgets/staff_form_sheet.dart';
import '../../common/widgets/manage_cards.dart';

class StaffPage extends GetView<StaffController> {
  const StaffPage({super.key});

  String _roleLabel(String role) {
    final name = role == 'all' ? 'manage.all'.tr : 'more.role.$role'.tr;
    final count = controller.data.value?.counts[role];
    return count == null ? name : '$name ($count)';
  }

  @override
  Widget build(BuildContext context) {
    final branches = controller.session.account.value?.branches ?? const [];
    return Obx(
      () {
        final onShift = controller.data.value?.onShift ?? 0;
        return ManagePage(
          title: 'more.staff'.tr,
          subtitle: 'staff.onShiftCount'.trParams({'count': '$onShift'}),
          trailing: controller.canManage
              ? HeaderButton(
                  icon: Iconsax.add,
                  onTap: () => showManageSheet<void>(context, const StaffFormSheet()),
                )
              : null,
          headerChild: branches.length > 1 ? const BranchPickerChip() : null,
          body: Column(
            children: [
              ChipBar<String>(
                values: StaffController.roles,
                selected: controller.role.value,
                label: _roleLabel,
                onSelect: (value) => controller.role.value = value,
              ),
              Expanded(
                child: manageLoader(
                  ready: controller.data.value != null,
                  error: controller.error.value,
                  onRetry: controller.load,
                  content: () {
                    final members = controller.visible;
                    return ManageList(
                      onRefresh: () => controller.load(silent: true),
                      itemCount: members.length,
                      emptyIcon: Iconsax.people,
                      emptyTitle: 'staff.empty'.tr,
                      itemBuilder: (_, index) => _StaffCard(
                        member: members[index],
                        onTap: () => showManageSheet<void>(
                          context,
                          StaffDetailsSheet(memberId: members[index].id),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StaffCard extends StatelessWidget {
  final StaffMember member;
  final VoidCallback onTap;

  const _StaffCard({required this.member, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final performance = member.performance;
    return Pressable(
      onTap: onTap,
      child: RoundedContainer(
        padding: EdgeInsets.all(14.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InitialsAvatar(name: member.name, size: 42.r),
                10.width,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(member.name, style: text.titleSmall),
                      Text(
                        '${'more.role.${member.role}'.tr} · ${member.branchName.shown}',
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (!member.active)
                  StatusBadge(label: 'staff.suspended'.tr, color: AppColors.danger)
                else if (member.onShiftNow)
                  StatusBadge(label: 'staff.onShift'.tr, color: AppColors.success),
              ],
            ),
            10.height,
            Row(
              children: [
                _Figure(label: 'staff.completed'.tr, value: FormatHelper.number(performance.completed)),
                _Figure(label: 'staff.serviceValue'.tr, value: FormatHelper.money(performance.serviceValue)),
                _Figure(
                  label: 'staff.rating'.tr,
                  value: performance.rating == null ? '-' : FormatHelper.number(performance.rating!),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  final String label;
  final String value;

  const _Figure({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.labelSmall),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.titleSmall),
        ],
      ),
    );
  }
}
