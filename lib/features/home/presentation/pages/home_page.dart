import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/utils/system_ui.dart';
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
    final header = HomeSliverHeader(topPadding: MediaQuery.paddingOf(context).top);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUi.onBrand,
      child: RefreshIndicator(
        onRefresh: controller.load,
        edgeOffset: header.minExtent,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverPersistentHeader(pinned: true, delegate: header),
            SliverToBoxAdapter(
              child: Obx(() {
                final summary = controller.summary.value;
                if (summary == null) {
                  return controller.error.value != null
                      ? SizedBox(
                          height: 360.h,
                          child: AppErrorState(message: controller.error.value, onRetry: controller.load),
                        )
                      : const AppShimmerList();
                }
                return AnimatedOpacity(
                  opacity: controller.refreshing.value ? 0.55 : 1,
                  duration: const Duration(milliseconds: 180),
                  child: Padding(
                    padding: EdgeInsets.only(top: 14.h, bottom: 120.h),
                    child: Column(
                      children: [
                        const _SuspendedBanner(),
                        _enter(0, KpiGrid(summary: summary)),
                        _enter(1, SectionHeader(title: 'home.attention'.tr)),
                        _enter(1, AlertsSection(alerts: summary.alerts)),
                        _enter(
                          2,
                          SectionHeader(
                            title: 'home.branchesNow'.tr,
                            actionText: 'home.seeLive'.tr,
                            onAction: () => Get.find<MainController>().changeTab(MainController.liveTab),
                          ),
                        ),
                        for (final branch in summary.liveBranches) _enter(2, BranchNowCard(branch: branch)),
                        _enter(3, SectionHeader(title: 'home.carsInside'.tr)),
                        _enter(3, CarsInsideSection(cars: summary.carsInside)),
                        _enter(
                          4,
                          SectionHeader(
                            title: (controller.period.value == DashboardPeriod.today
                                    ? 'home.revenueByHour'
                                    : 'home.revenueByDay')
                                .tr,
                          ),
                        ),
                        _enter(4, RevenueBars(points: summary.revenueByHour)),
                        8.height,
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

/// GAP-014: a suspended wash learns it here, with the platform's reason, instead of from a
/// failing action. Hidden for active businesses.
class _SuspendedBanner extends StatelessWidget {
  const _SuspendedBanner();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final account = Get.find<SessionService>().account.value;
      if (account == null || account.businessStatus != 'suspended') return const SizedBox.shrink();
      final reason = account.businessStatusReason?.trim() ?? '';
      final text = Theme.of(context).textTheme;
      return Container(
        width: double.infinity,
        margin: EdgeInsets.fromLTRB(20.w, 0, 20.w, 14.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.08),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('home.suspendedTitle'.tr, style: text.titleSmall?.copyWith(color: AppColors.danger)),
            SizedBox(height: 4.h),
            Text(
              reason.isEmpty ? 'home.suspendedBody'.tr : 'home.suspendedReason'.trParams({'reason': reason}),
              style: text.bodySmall,
            ),
          ],
        ),
      );
    });
  }
}
