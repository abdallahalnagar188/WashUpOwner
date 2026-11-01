import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/dashboard_summary.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';

class AlertsSection extends StatelessWidget {
  final List<DashboardAlert> alerts;

  const AlertsSection({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return _AlertTile(
        icon: Iconsax.tick_circle,
        color: AppColors.success,
        title: 'home.allGood'.tr,
        body: 'home.allGoodBody'.tr,
      );
    }
    return Column(
      children: [
        for (final alert in alerts)
          _AlertTile(
            icon: Iconsax.warning_2,
            color: AppColors.warning,
            title: alert.title.value,
            body: alert.body?.value,
          ),
      ],
    );
  }
}

class _AlertTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? body;

  const _AlertTile({
    required this.icon,
    required this.color,
    required this.title,
    this.body,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return RoundedContainer(
      margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
      padding: EdgeInsets.all(14.r),
      child: Row(
        children: [
          Container(
            width: 38.r,
            height: 38.r,
            decoration: BoxDecoration(
              color: AppColors.tint(color),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, size: 20.r, color: color),
          ),
          12.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleSmall),
                if (body != null) Text(body!, style: text.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
