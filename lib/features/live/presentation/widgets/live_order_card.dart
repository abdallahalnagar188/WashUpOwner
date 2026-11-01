import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../commons/models/live_board.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
import '../../../../core/utils/utils.dart';
import '../controllers/live_controller.dart';

class LiveOrderCard extends GetView<LiveController> {
  final LiveOrder order;

  const LiveOrderCard({super.key, required this.order});

  Future<void> _onAction(LiveAction action) async {
    if (action == LiveAction.collect) {
      final ok = await Utils.confirm(
        title: 'live.collectTitle'.trParams({'amount': FormatHelper.money(order.total)}),
        body: 'live.collectBody'.trParams({'number': order.number}),
        okText: 'live.action.collect'.tr,
      );
      if (!ok) return;
    }
    await controller.run(order);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final action = order.nextAction;
    return RoundedContainer(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(order.plate, style: text.titleMedium)),
              order.status == OrderStatus.completed
                  ? StatusBadge.payment(order.paymentStatus)
                  : StatusBadge.order(order.status),
            ],
          ),
          4.height,
          Text('${order.vehicle} · ${order.customerName}', style: text.bodySmall),
          10.height,
          Row(
            children: [
              Expanded(child: Text(order.serviceName.value, style: text.bodyMedium)),
              Text(FormatHelper.money(order.total), style: text.titleSmall),
            ],
          ),
          4.height,
          Text(
            '${FormatHelper.time(order.scheduledAt)} · ${'source.${order.source.key}'.tr} · ${order.number}',
            style: text.labelSmall?.copyWith(color: AppColors.ink500),
          ),
          if (action != null && controller.canRun(action)) ...[
            12.height,
            Obx(
              () => AppButton(
                title: 'live.action.${action.name}'.tr,
                small: true,
                loading: controller.busyOrderId.value == order.id,
                onTap: () => _onAction(action),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
