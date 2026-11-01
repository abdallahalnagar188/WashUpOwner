import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../main/presentation/controllers/main_controller.dart';
import '../controllers/home_controller.dart';
import '../widgets/alerts_section.dart';
import '../widgets/branch_now_card.dart';
import '../widgets/cars_inside_section.dart';
import '../widgets/home_header.dart';
import '../widgets/kpi_grid.dart';
import '../widgets/revenue_bars.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  String _periodLabel(DashboardPeriod period) => switch (period) {
        DashboardPeriod.today => 'home.today'.tr,
        DashboardPeriod.week => 'home.week'.tr,
        DashboardPeriod.month => 'home.month'.tr,
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const HomeHeader(),
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 8.h),
          child: Obx(
            () => Row(
              children: [
                for (final period in DashboardPeriod.values) ...[
                  AppChip(
                    label: _periodLabel(period),
                    selected: controller.period.value == period,
                    onTap: () => controller.selectPeriod(period),
                  ),
                  8.width,
                ],
              ],
            ),
          ),
        ),
        Expanded(
          child: Obx(() {
            final summary = controller.summary.value;
            if (summary == null) {
              return controller.failed.value
                  ? AppErrorState(onRetry: controller.load)
                  : const AppShimmerList();
            }
            return RefreshIndicator(
              onRefresh: controller.load,
              child: ListView(
                padding: EdgeInsets.only(bottom: 24.h),
                children: [
                  KpiGrid(summary: summary),
                  SectionHeader(
                    title: 'home.branchesNow'.tr,
                    actionText: 'home.seeLive'.tr,
                    onAction: () => Get.find<MainController>().changeTab(MainController.liveTab),
                  ),
                  for (final branch in summary.liveBranches) BranchNowCard(branch: branch),
                  SectionHeader(title: 'home.attention'.tr),
                  AlertsSection(alerts: summary.alerts),
                  SectionHeader(title: 'home.carsInside'.tr),
                  CarsInsideSection(cars: summary.carsInside),
                  SectionHeader(title: 'home.revenueByHour'.tr),
                  RevenueBars(points: summary.revenueByHour),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}
