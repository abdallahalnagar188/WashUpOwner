import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/dashboard_summary.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../commons/widgets/effects/animated_number.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';

class KpiGrid extends StatelessWidget {
  final DashboardSummary summary;

  const KpiGrid({super.key, required this.summary});

  // Revenue sits on the header, so the grid starts with orders.
  static final List<(String, IconData, Color Function())> _tiles = [
    ('totalOrders', Iconsax.receipt_2, () => AppColors.primary),
    ('completed', Iconsax.tick_circle, () => AppColors.success),
    ('pendingPayments', Iconsax.wallet_money, () => AppColors.warning),
    ('confirmedBookings', Iconsax.calendar_tick, () => AppColors.statusConfirmed),
    ('walkIns', Iconsax.car, () => AppColors.statusInService),
    ('cancelled', Iconsax.close_circle, () => AppColors.danger),
  ];

  @override
  Widget build(BuildContext context) {
    final tiles = [
      for (final tile in _tiles)
        if (summary.kpi(tile.$1) != null) (summary.kpi(tile.$1)!, tile.$2, tile.$3()),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      itemCount: tiles.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        mainAxisExtent: 82.h,
      ),
      itemBuilder: (_, index) {
        final (kpi, icon, color) = tiles[index];
        return FadeSlideIn(
          delay: Duration(milliseconds: 50 * index),
          child: _KpiTile(kpi: kpi, icon: icon, color: color),
        );
      },
    );
  }
}

class _KpiTile extends StatelessWidget {
  final DashboardKpi kpi;
  final IconData icon;
  final Color color;

  const _KpiTile({required this.kpi, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return RoundedContainer(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: Row(
        children: [
          Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
              color: AppColors.tint(color),
              borderRadius: BorderRadius.circular(13.r),
            ),
            child: Icon(icon, size: 20.r, color: color),
          ),
          10.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedNumber(
                  value: kpi.value,
                  format: FormatHelper.number,
                  style: text.headlineSmall,
                ),
                Text(
                  'kpi.${kpi.key}'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
