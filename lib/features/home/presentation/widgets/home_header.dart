import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/dashboard_summary.dart';
import '../../../../commons/models/owner_account.dart';
import '../../../../commons/widgets/effects/animated_number.dart';
import '../../../../commons/widgets/layout/brand_header.dart';
import '../../../../commons/widgets/layout/branch_picker.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
import '../../../../core/routing/app_routes.dart';
import '../controllers/home_controller.dart';

class HomeHeader extends GetView<HomeController> {
  const HomeHeader({super.key});

  String _periodLabel(DashboardPeriod period) => switch (period) {
        DashboardPeriod.today => 'home.today'.tr,
        DashboardPeriod.week => 'home.week'.tr,
        DashboardPeriod.month => 'home.month'.tr,
      };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Obx(() {
      final OwnerAccount? account = controller.session.account.value;
      if (account == null) return empty;
      final greeting = DateTime.now().hour < 12 ? 'home.morning' : 'home.evening';
      final DashboardSummary? summary = controller.summary.value;
      final revenue = summary?.kpi('revenue');
      return BrandHeader(
        title: greeting.trParams({'name': account.name.split(' ').first}),
        subtitle: account.businessName.value,
        trailing: HeaderButton(
          icon: Iconsax.notification,
          badge: controller.unread.value,
          onTap: () => Get.toNamed(Routes.notificationsRoute),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (account.branches.length > 1) ...[
              const BranchPickerChip(),
              12.height,
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'kpi.revenue'.tr,
                        style: text.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                      ),
                      2.height,
                      AnimatedNumber(
                        value: revenue?.value ?? 0,
                        format: FormatHelper.money,
                        style: text.headlineLarge?.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                if (revenue?.delta != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          revenue!.delta! >= 0 ? Iconsax.arrow_up_3 : Iconsax.arrow_down,
                          size: 12.r,
                          color: Colors.white,
                        ),
                        3.width,
                        Text(
                          '${FormatHelper.number(revenue.delta!.abs())}%',
                          style: text.labelMedium?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            14.height,
            _PeriodSwitch(
              selected: controller.period.value,
              label: _periodLabel,
              onSelect: controller.selectPeriod,
            ),
          ],
        ),
      );
    });
  }
}

/// Segmented control with a pill that slides to the selected period.
class _PeriodSwitch extends StatelessWidget {
  final DashboardPeriod selected;
  final String Function(DashboardPeriod) label;
  final ValueChanged<DashboardPeriod> onSelect;

  const _PeriodSwitch({required this.selected, required this.label, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    const periods = DashboardPeriod.values;
    final index = periods.indexOf(selected);
    return Container(
      height: 40.h,
      padding: EdgeInsets.all(3.r),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: AlignmentDirectional(-1 + index * (2 / (periods.length - 1)), 0),
            child: FractionallySizedBox(
              widthFactor: 1 / periods.length,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final period in periods)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onSelect(period),
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: (text.labelLarge ?? const TextStyle()).copyWith(
                          color: period == selected ? AppColors.brand : Colors.white,
                        ),
                        child: Text(label(period)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
