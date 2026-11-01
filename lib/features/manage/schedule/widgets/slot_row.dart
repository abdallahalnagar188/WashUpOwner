import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/schedule_day.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../commons/widgets/effects/animated_bar.dart';
import '../../../../commons/widgets/effects/pressable.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
import '../../../../core/routing/app_routes.dart';

class SlotRow extends StatelessWidget {
  final ScheduleSlot slot;
  final VoidCallback onBlock;
  final VoidCallback onUnblock;

  const SlotRow({super.key, required this.slot, required this.onBlock, required this.onUnblock});

  String get _state {
    if (slot.blocked != null) return 'schedule.blocked'.tr;
    if (slot.occupied > slot.capacity) return 'schedule.over'.tr;
    if (slot.occupied >= slot.capacity) return 'schedule.full'.tr;
    return 'schedule.free'.trParams({'count': '${slot.capacity - slot.occupied}'});
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final start = slot.startAt;
    final blocked = slot.blocked;
    return Opacity(
      opacity: slot.past ? 0.55 : 1,
      child: RoundedContainer(
        padding: EdgeInsets.all(12.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 64.w,
                  child: Text(start == null ? '' : FormatHelper.time(start), style: text.titleSmall),
                ),
                8.width,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedBar(value: blocked != null ? 1 : slot.fill),
                      4.height,
                      Text(
                        '${slot.occupied}/${slot.capacity} · $_state',
                        style: text.labelSmall?.copyWith(
                          color: slot.occupied > slot.capacity ? AppColors.danger : null,
                        ),
                      ),
                    ],
                  ),
                ),
                8.width,
                if (blocked != null)
                  AppIconButton(
                    size: 36.r,
                    icon: Icon(Iconsax.unlock, color: AppColors.warning),
                    onTap: onUnblock,
                  )
                else if (!slot.past)
                  AppIconButton(
                    size: 36.r,
                    icon: Icon(Iconsax.lock_1, color: AppColors.primary),
                    onTap: onBlock,
                  ),
              ],
            ),
            if (blocked != null && blocked.reason.isNotEmpty) ...[
              8.height,
              Text(blocked.reason, style: text.bodySmall?.copyWith(color: AppColors.warning)),
            ],
            if (slot.orders.isNotEmpty) ...[
              8.height,
              Wrap(
                spacing: 6.w,
                runSpacing: 6.h,
                children: [for (final order in slot.orders) _OrderTag(order: order)],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OrderTag extends StatelessWidget {
  final SlotOrder order;

  const _OrderTag({required this.order});

  @override
  Widget build(BuildContext context) {
    final color = StatusBadge.colorFor(OrderStatus.fromKey(order.status));
    return Pressable(
      onTap: () => Get.toNamed(Routes.orderRoute, arguments: order.id),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: AppColors.tint(color),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          order.plate.isEmpty ? order.number : order.plate,
          textDirection: TextDirection.ltr,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
        ),
      ),
    );
  }
}
