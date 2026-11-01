import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/schedule_day.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../commons/widgets/layout/brand_header.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
import '../../../../core/utils/utils.dart';
import '../../common/widgets/manage_page.dart';
import '../../common/widgets/manage_sheets.dart';
import '../controllers/schedule_controller.dart';
import '../widgets/block_slot_sheet.dart';
import '../widgets/date_strip.dart';
import '../widgets/slot_row.dart';
import '../../common/widgets/manage_cards.dart';

class SchedulePage extends GetView<ScheduleController> {
  const SchedulePage({super.key});

  Future<void> _block(BuildContext context, ScheduleDay day, [String? start]) => showManageSheet<void>(
        context,
        BlockSlotSheet(day: day, initialStart: start, onSubmit: controller.block),
      );

  Future<void> _unblock(ScheduleBlock block) async {
    final ok = await Utils.confirm(
      title: 'schedule.unblockTitle'.tr,
      body: block.reason,
      okText: 'schedule.unblock'.tr,
    );
    if (ok) await controller.removeBlock(block);
  }

  Future<void> _pickDate(BuildContext context) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.date.value,
      firstDate: today.subtract(const Duration(days: 365)),
      lastDate: today.add(const Duration(days: 365)),
    );
    if (picked != null) controller.selectDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    final branches = controller.session.account.value?.branches ?? const [];
    return ManagePage(
      title: 'more.schedule'.tr,
      trailing: HeaderButton(icon: Iconsax.calendar_1, onTap: () => _pickDate(context)),
      body: Column(
        children: [
          if (branches.length > 1)
            Obx(
              () => ChipBar<String>(
                values: branches.map((b) => b.id).toList(),
                selected: controller.branchId.value,
                label: (id) => branches.firstWhere((b) => b.id == id).name.shown,
                onSelect: controller.selectBranch,
              ),
            ),
          Obx(() => DateStrip(selected: controller.date.value, onSelect: controller.selectDate)),
          Expanded(
            child: Obx(
              () => manageLoader(
                ready: controller.data.value != null,
                error: controller.error.value,
                onRetry: controller.load,
                content: () => _day(context, controller.data.value!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _day(BuildContext context, ScheduleDay day) {
    if (day.closed || day.slots.isEmpty) {
      return ManageList(
        onRefresh: () => controller.load(silent: true),
        itemCount: 0,
        itemBuilder: (_, __) => empty,
        emptyIcon: Iconsax.calendar_remove,
        emptyTitle: 'schedule.closed'.tr,
      );
    }
    final text = Theme.of(context).textTheme;
    return ManageList(
      onRefresh: () => controller.load(silent: true),
      itemCount: day.slots.length,
      emptyIcon: Iconsax.calendar_remove,
      emptyTitle: 'schedule.closed'.tr,
      header: Padding(
        padding: EdgeInsets.only(bottom: 10.h),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'schedule.hours'.trParams({
                      'open': day.open,
                      'close': day.close,
                      'min': '${day.slotIntervalMin}',
                    }),
                    style: text.bodySmall,
                  ),
                ),
                AppButton(
                  title: 'schedule.block'.tr,
                  icon: Iconsax.lock_1,
                  small: true,
                  expanded: false,
                  onTap: day.blockableStarts.isEmpty ? null : () => _block(context, day),
                ),
              ],
            ),
            for (final block in day.blocks) ...[
              8.height,
              _BlockTile(block: block, onRemove: () => _unblock(block)),
            ],
          ],
        ),
      ),
      itemBuilder: (_, index) {
        final slot = day.slots[index];
        return SlotRow(
          slot: slot,
          onBlock: () => _block(context, day, slot.start),
          onUnblock: () => _unblock(slot.blocked!),
        );
      },
    );
  }
}

class _BlockTile extends StatelessWidget {
  final ScheduleBlock block;
  final VoidCallback onRemove;

  const _BlockTile({required this.block, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final start = block.startAt;
    final end = block.endAt;
    return RoundedContainer(
      shadow: false,
      color: AppColors.tint(AppColors.warning),
      borderColor: Colors.transparent,
      padding: EdgeInsets.all(12.r),
      child: Row(
        children: [
          Icon(Iconsax.lock_1, size: 18.r, color: AppColors.warning),
          10.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (start != null && end != null)
                  Text(
                    '${FormatHelper.time(start)} - ${FormatHelper.time(end)}',
                    style: text.titleSmall,
                  ),
                Text(block.reason, style: text.bodySmall),
              ],
            ),
          ),
          TextButton(onPressed: onRemove, child: Text('schedule.unblock'.tr)),
        ],
      ),
    );
  }
}
