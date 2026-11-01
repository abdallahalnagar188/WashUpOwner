import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/dashboard_summary.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';

class KpiGrid extends StatelessWidget {
  final DashboardSummary summary;

  const KpiGrid({super.key, required this.summary});

  static const List<String> _order = [
    'revenue',
    'totalOrders',
    'completed',
    'pendingPayments',
    'confirmedBookings',
    'walkIns',
    'cancelled',
    'noShows',
  ];

  @override
  Widget build(BuildContext context) {
    final items = _order.map(summary.kpi).whereType<DashboardKpi>().toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10.w,
        mainAxisSpacing: 10.h,
        mainAxisExtent: 84.h,
      ),
      itemBuilder: (_, index) => _KpiTile(kpi: items[index]),
    );
  }
}

class _KpiTile extends StatelessWidget {
  final DashboardKpi kpi;

  const _KpiTile({required this.kpi});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final delta = kpi.delta;
    return RoundedContainer(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'kpi.${kpi.key}'.tr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.bodySmall,
          ),
          4.height,
          Row(
            children: [
              Flexible(
                child: Text(
                  kpi.key == 'revenue' ? FormatHelper.money(kpi.value) : FormatHelper.number(kpi.value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.headlineSmall,
                ),
              ),
              if (delta != null) ...[
                6.width,
                Icon(
                  delta >= 0 ? Iconsax.arrow_up_3 : Iconsax.arrow_down,
                  size: 12.r,
                  color: delta >= 0 ? AppColors.success : AppColors.danger,
                ),
                2.width,
                Text(
                  '${FormatHelper.number(delta.abs())}%',
                  style: text.labelSmall?.copyWith(
                    color: delta >= 0 ? AppColors.success : AppColors.danger,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
