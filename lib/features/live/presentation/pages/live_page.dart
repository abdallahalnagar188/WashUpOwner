import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/live_board.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../commons/widgets/effects/animated_bar.dart';
import '../../../../commons/widgets/layout/brand_header.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
import '../../../orders/presentation/widgets/order_card.dart';
import '../controllers/live_controller.dart';

class LivePage extends GetView<LiveController> {
  const LivePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final board = controller.board.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BrandHeader(
            title: 'live.title'.tr,
            subtitle: board == null
                ? null
                : 'live.updated'.trParams({'time': FormatHelper.time(board.generatedAt)}),
            child: board == null ? null : _BaysSummary(board: board),
          ),
          if (board == null)
            Expanded(
              child: controller.error.value != null
                  ? AppErrorState(message: controller.error.value, onRetry: controller.load)
                  : const AppShimmerList(),
            )
          else ...[
            12.height,
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                children: [
                  for (final column in LiveColumn.values) ...[
                    AppChip(
                      label: '${'live.column.${column.name}'.tr} (${board.ordersIn(column).length})',
                      selected: controller.column.value == column,
                      onTap: () => controller.column.value = column,
                    ),
                    8.width,
                  ],
                ],
              ),
            ),
            10.height,
            Expanded(child: _ColumnList(board: board, column: controller.column.value)),
          ],
        ],
      );
    });
  }
}

class _ColumnList extends GetView<LiveController> {
  final LiveBoard board;
  final LiveColumn column;

  const _ColumnList({required this.board, required this.column});

  @override
  Widget build(BuildContext context) {
    final orders = board.ordersIn(column);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      child: RefreshIndicator(
        key: ValueKey(column),
        onRefresh: controller.load,
        child: orders.isEmpty
            ? ListView(
                children: [
                  SizedBox(
                    height: 260.h,
                    child: CustomEmptyState(
                      icon: Iconsax.car,
                      title: 'live.empty.${column.name}'.tr,
                    ),
                  ),
                ],
              )
            : ListView.builder(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                padding: EdgeInsets.fromLTRB(20.w, 2.h, 20.w, 120.h),
                itemCount: orders.length,
                itemBuilder: (_, index) => FadeSlideIn(
                  key: ValueKey(orders[index].id),
                  delay: Duration(milliseconds: 40 * index.clamp(0, 6)),
                  child: OrderCard(order: orders[index]),
                ),
              ),
      ),
    );
  }
}

class _BaysSummary extends StatelessWidget {
  final LiveBoard board;

  const _BaysSummary({required this.board});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final usage = board.capacity == 0 ? 0.0 : board.baysBusy / board.capacity;
    return Column(
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
                style: text.titleSmall?.copyWith(color: Colors.white),
              ),
            ),
            Text(
              'branch.onShift'.trParams({'count': '${board.staffOnShift.length}'}),
              style: text.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
            ),
          ],
        ),
        8.height,
        AnimatedBar(value: usage, track: Colors.white.withValues(alpha: 0.2)),
      ],
    );
  }
}
