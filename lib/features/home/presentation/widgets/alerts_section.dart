import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/dashboard_summary.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../commons/widgets/effects/pressable.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/routing/href_router.dart';

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
            icon: alert.severity == AlertSeverity.info ? Iconsax.info_circle : Iconsax.warning_2,
            color: _color(alert.severity),
            title: alert.title.value,
            body: alert.body?.value,
            // Only links the app has a screen for are tappable (GAP-079).
            onTap: HrefRouter.parse(alert.href) == null ? null : () => HrefRouter.open(alert.href),
          ),
      ],
    );
  }

  static Color _color(AlertSeverity severity) => switch (severity) {
        AlertSeverity.danger => AppColors.danger,
        AlertSeverity.warning => AppColors.warning,
        AlertSeverity.info => AppColors.info,
      };
}

class _AlertTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? body;
  final VoidCallback? onTap;

  const _AlertTile({
    required this.icon,
    required this.color,
    required this.title,
    this.body,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final tile = RoundedContainer(
      margin: EdgeInsets.fromLTRB(20.w, 0, 20.w, 10.h),
      padding: EdgeInsets.all(14.r),
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
          if (onTap != null) ...[
            8.width,
            Icon(
              Directionality.of(context) == TextDirection.rtl ? Iconsax.arrow_left_2 : Iconsax.arrow_right_3,
              size: 16.r,
              color: AppColors.ink500,
            ),
          ],
        ],
      ),
    );
    return onTap == null ? tile : Pressable(onTap: onTap, child: tile);
  }
}
