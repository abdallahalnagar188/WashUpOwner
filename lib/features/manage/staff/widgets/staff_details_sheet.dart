import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/staff_member.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
import '../../common/widgets/manage_cards.dart';
import '../../common/widgets/manage_sheets.dart';
import '../controllers/staff_controller.dart';
import 'staff_form_sheet.dart';
import 'staff_schedule_sheet.dart';

/// A member's file. Reads the member from the controller, so it shows the new
/// values after an edit.
class StaffDetailsSheet extends GetView<StaffController> {
  final String memberId;

  const StaffDetailsSheet({super.key, required this.memberId});

  void _toggle(BuildContext context, StaffMember member) {
    showReasonSheet(
      context,
      title: member.active ? 'staff.deactivate'.tr : 'staff.activate'.tr,
      body: member.active ? 'staff.deactivateBody'.tr : 'staff.activateBody'.tr,
      okText: member.active ? 'staff.deactivate'.tr : 'staff.activate'.tr,
      danger: member.active,
      presets: member.active
          ? [
              'staff.preset.contract'.tr,
              'staff.preset.absence'.tr,
              'staff.preset.violation'.tr,
              'staff.preset.leave'.tr,
            ]
          : const [],
      onSubmit: (reason) => controller.setActive(member, reason: reason),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final member = controller.byId(memberId);
      if (member == null) return empty;
      final performance = member.performance;
      final text = Theme.of(context).textTheme;
      return SheetBody(
        title: member.name,
        subtitle: '${'more.role.${member.role}'.tr} · ${member.branchName.shown}',
        children: [
          if (member.phone.isNotEmpty) InfoRow('orders.phone'.tr, member.phone),
          InfoRow('staff.discountLimit'.tr, '${FormatHelper.number(member.maxDiscountPct)}%'),
          InfoRow('staff.completed'.tr, FormatHelper.number(performance.completed)),
          InfoRow('staff.serviceValue'.tr, FormatHelper.money(performance.serviceValue)),
          if (performance.avgDurationMin != null)
            InfoRow(
              'staff.avgDuration'.tr,
              'services.minutes'.trParams({'count': FormatHelper.number(performance.avgDurationMin!)}),
            ),
          if (performance.discountsCount > 0)
            InfoRow(
              'staff.discounts'.tr,
              '${performance.discountsCount} · ${FormatHelper.money(performance.discountsAmount)}',
            ),
          12.height,
          Text('staff.permissions'.tr, style: text.titleSmall),
          8.height,
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: [
              for (final key in StaffMember.permissionKeys)
                if (member.permissions[key] == true)
                  StatusBadge(label: 'staff.permission.$key'.tr, color: AppColors.success),
            ],
          ),
          12.height,
          Text('staff.weekly'.tr, style: text.titleSmall),
          6.height,
          if (member.scheduledShifts.isEmpty)
            Text('staff.noShifts'.tr, style: text.bodySmall)
          else
            for (final shift in member.scheduledShifts)
              Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Text(
                  '${shift.start} - ${shift.end} · ${shift.days.map((d) => 'day.$d'.tr).join('manage.listJoin'.tr)}',
                  style: text.bodySmall,
                ),
              ),
          16.height,
          if (controller.canEdit(member)) ...[
            AppButton(
              title: 'manage.edit'.tr,
              icon: Iconsax.edit_2,
              variant: AppButtonVariant.ghost,
              onTap: () => showManageSheet<void>(context, StaffFormSheet(member: member)),
            ),
            10.height,
          ],
          if (controller.canEditSchedule(member)) ...[
            AppButton(
              title: 'staff.editSchedule'.tr,
              icon: Iconsax.calendar_1,
              variant: AppButtonVariant.ghost,
              onTap: () => showManageSheet<void>(context, StaffScheduleSheet(member: member)),
            ),
            10.height,
          ],
          if (controller.canToggle(member))
            AppButton(
              title: member.active ? 'staff.deactivate'.tr : 'staff.activate'.tr,
              icon: Iconsax.user_remove,
              variant: member.active ? AppButtonVariant.danger : AppButtonVariant.primary,
              onTap: () => _toggle(context, member),
            ),
        ],
      );
    });
  }
}
