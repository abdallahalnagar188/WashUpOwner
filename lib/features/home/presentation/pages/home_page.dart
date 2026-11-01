import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../commons/widgets/common_widgets.dart';
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

  static Widget _enter(int index, Widget child) => FadeSlideIn(
        delay: Duration(milliseconds: 70 * index),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const HomeHeader(),
        Expanded(
          child: Obx(() {
            final summary = controller.summary.value;
            if (summary == null) {
              return controller.error.value != null
                  ? AppErrorState(message: controller.error.value, onRetry: controller.load)
                  : const AppShimmerList();
            }
            return RefreshIndicator(
              onRefresh: controller.load,
              child: ListView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                padding: EdgeInsets.only(top: 16.h, bottom: 120.h),
                children: [
                  _enter(0, KpiGrid(summary: summary)),
                  _enter(
                    1,
                    SectionHeader(
                      title: 'home.branchesNow'.tr,
                      actionText: 'home.seeLive'.tr,
                      onAction: () => Get.find<MainController>().changeTab(MainController.liveTab),
                    ),
                  ),
                  for (final branch in summary.liveBranches) _enter(2, BranchNowCard(branch: branch)),
                  _enter(3, SectionHeader(title: 'home.attention'.tr)),
                  _enter(3, AlertsSection(alerts: summary.alerts)),
                  _enter(4, SectionHeader(title: 'home.carsInside'.tr)),
                  _enter(4, CarsInsideSection(cars: summary.carsInside)),
                  _enter(5, SectionHeader(title: 'home.revenueByHour'.tr)),
                  _enter(5, RevenueBars(points: summary.revenueByHour)),
                  8.height,
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}
