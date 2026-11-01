import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/live_board.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
import '../controllers/live_controller.dart';
import '../widgets/live_order_card.dart';

class LivePage extends GetView<LiveController> {
  const LivePage({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Obx(() {
      final board = controller.board.value;
      if (board == null) {
        return controller.failed.value
            ? AppErrorState(onRetry: controller.load)
            : const AppShimmerList();
      }
      final selected = controller.column.value;
      final orders = board.ordersIn(selected);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 10.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('live.title'.tr, style: text.headlineSmall),
                2.height,
                Text(
                  'live.updated'.trParams({'time': FormatHelper.time(board.generatedAt)}),
                  style: text.bodySmall,
                ),
                12.height,
                _BaysSummary(board: board),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                for (final column in LiveColumn.values) ...[
                  AppChip(
                    label: '${'live.column.${column.name}'.tr} (${board.ordersIn(column).length})',
                    selected: selected == column,
                    onTap: () => controller.column.value = column,
                  ),
                  8.width,
                ],
              ],
            ),
          ),
          10.height,
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.load,
              child: orders.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: 260.h,
                          child: CustomEmptyState(
                            icon: Iconsax.car,
                            title: 'live.empty.${selected.name}'.tr,
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
                      itemCount: orders.length,
                      itemBuilder: (_, index) => LiveOrderCard(order: orders[index]),
                    ),
            ),
          ),
        ],
      );
    });
  }
}

class _BaysSummary extends StatelessWidget {
  final LiveBoard board;

  const _BaysSummary({required this.board});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final usage = board.capacity == 0 ? 0.0 : board.baysBusy / board.capacity;
    return RoundedContainer(
      padding: EdgeInsets.all(14.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'live.bays'.trParams({
                    'busy': '${board.baysBusy}',
                    'capacity': '${board.capacity}',
                  }),
                  style: text.titleSmall,
                ),
              ),
              Text(
                'branch.onShift'.trParams({'count': '${board.staffOnShift.length}'}),
                style: text.bodySmall,
              ),
            ],
          ),
          8.height,
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: usage,
              minHeight: 6.h,
              backgroundColor: AppColors.primarySoft,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
