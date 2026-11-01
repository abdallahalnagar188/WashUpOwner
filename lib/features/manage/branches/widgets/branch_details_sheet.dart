import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
import '../../common/widgets/manage_cards.dart';
import '../../common/widgets/manage_sheets.dart';
import '../controllers/branches_controller.dart';
import 'branch_form_sheet.dart';
import 'branch_rules_sheet.dart';

class BranchDetailsSheet extends GetView<BranchesController> {
  final String branchId;

  const BranchDetailsSheet({super.key, required this.branchId});

  String _minutes(num value) => 'services.minutes'.trParams({'count': FormatHelper.number(value)});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final branch = controller.byId(branchId);
      if (branch == null) return empty;
      final text = Theme.of(context).textTheme;
      final rules = branch.settings;
      return SheetBody(
        title: branch.name.shown,
        subtitle: branch.address.shown,
        children: [
          InfoRow('orders.phone'.tr, branch.phone.isEmpty ? '-' : branch.phone),
          InfoRow('branches.capacityLabel'.tr, '${branch.capacity}'),
          14.height,
          Text('branches.hours'.tr, style: text.titleSmall),
          6.height,
          for (var day = 0; day < branch.workingHours.length; day++)
            InfoRow(
              'day.$day'.tr,
              branch.workingHours[day].closed
                  ? 'branch.closed'.tr
                  : '${branch.workingHours[day].open} - ${branch.workingHours[day].close}',
            ),
          14.height,
          Text('branches.amenities'.tr, style: text.titleSmall),
          6.height,
          Wrap(
            spacing: 6.w,
            runSpacing: 6.h,
            children: [
              for (final amenity in branch.amenities)
                AppChip(label: labelOr('branches.amenity.$amenity', amenity), flat: true),
            ],
          ),
          14.height,
          Text('branches.rules'.tr, style: text.titleSmall),
          6.height,
          InfoRow(
            'branches.autoConfirm'.tr,
            rules.autoConfirm ? 'branches.yes'.tr : 'branches.no'.tr,
          ),
          InfoRow('branches.slot'.tr, _minutes(rules.slotIntervalMin)),
          InfoRow('branches.leadTime'.tr, _minutes(rules.leadTimeMin)),
          InfoRow(
            'branches.maxAdvance'.tr,
            'branches.days'.trParams({'count': FormatHelper.number(rules.maxAdvanceDays)}),
          ),
          InfoRow('branches.freeCancel'.tr, _minutes(rules.freeCancelMin)),
          InfoRow('branches.noShowGrace'.tr, _minutes(rules.noShowGraceMin)),
          InfoRow('branches.reminder'.tr, _minutes(rules.reminderMin)),
          if (controller.isOwner) ...[
            16.height,
            AppButton(
              title: 'branches.edit'.tr,
              icon: Iconsax.edit_2,
              variant: AppButtonVariant.ghost,
              onTap: () => showManageSheet<void>(context, BranchFormSheet(branch: branch)),
            ),
            10.height,
            AppButton(
              title: 'branches.editRules'.tr,
              icon: Iconsax.setting_4,
              variant: AppButtonVariant.ghost,
              onTap: () => showManageSheet<void>(context, BranchRulesSheet(branch: branch)),
            ),
          ],
        ],
      );
    });
  }
}
