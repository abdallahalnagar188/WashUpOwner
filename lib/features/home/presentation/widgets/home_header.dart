import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/effects/animated_number.dart';
import '../../../../commons/widgets/layout/branch_picker.dart';
import '../../../../commons/widgets/layout/brand_header.dart';
import '../../../../commons/widgets/tabs/sliding_segment.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
import '../../../../core/routing/app_routes.dart';
import '../controllers/home_controller.dart';

/// Blue header that shrinks to one line as the page scrolls, keeping the bell
/// and today's revenue in reach.
class HomeSliverHeader extends SliverPersistentHeaderDelegate {
  final double topPadding;

  HomeSliverHeader({required this.topPadding});

  double get _rowTop => topPadding + 6.h;
  double get _rowHeight => 44.r;
  double get _revenueHeight => 36.h;
  double get _segmentHeight => 38.h;

  @override
  double get maxExtent => _rowTop + _rowHeight + 4.h + _revenueHeight + 8.h + _segmentHeight + 12.h;

  @override
  double get minExtent => _rowTop + _rowHeight + 10.h;

  @override
  bool shouldRebuild(covariant HomeSliverHeader oldDelegate) => oldDelegate.topPadding != topPadding;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final controller = Get.find<HomeController>();
    final range = maxExtent - minExtent;
    final t = (shrinkOffset / range).clamp(0.0, 1.0);
    final extent = math.max(minExtent, maxExtent - shrinkOffset);
    final expandedOpacity = (1 - t * 1.8).clamp(0.0, 1.0);
    final collapsedOpacity = ((t - 0.55) / 0.45).clamp(0.0, 1.0);

    return Container(
      height: extent,
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30.r - 10.r * t)),
        boxShadow: t > 0.95 ? AppColors.softShadow : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          PositionedDirectional(
            end: -50.w,
            top: -40.h - 40.h * t,
            child: _Bubble(size: 170.r),
          ),
          PositionedDirectional(
            top: _rowTop,
            start: 20.w,
            end: 20.w,
            height: _rowHeight,
            child: Row(
              children: [
                Expanded(
                  child: Stack(
                    alignment: AlignmentDirectional.centerStart,
                    children: [
                      Opacity(opacity: expandedOpacity, child: const _Greeting()),
                      Opacity(opacity: collapsedOpacity, child: const _CollapsedRevenue()),
                    ],
                  ),
                ),
                const _BranchButton(),
                Obx(
                  () => HeaderButton(
                    icon: Iconsax.notification,
                    badge: controller.unread.value,
                    onTap: () => Get.toNamed(Routes.notificationsRoute),
                  ),
                ),
              ],
            ),
          ),
          if (expandedOpacity > 0)
            PositionedDirectional(
              top: _rowTop + _rowHeight + 4.h - 20.h * t,
              start: 20.w,
              end: 20.w,
              height: _revenueHeight,
              child: IgnorePointer(
                child: Opacity(
                  opacity: expandedOpacity,
                  child: Transform.scale(
                    scale: 1 - 0.08 * t,
                    alignment: AlignmentDirectional.centerStart,
                    child: const _Revenue(),
                  ),
                ),
              ),
            ),
          if (expandedOpacity > 0)
            PositionedDirectional(
              bottom: 12.h,
              start: 20.w,
              end: 20.w,
              height: _segmentHeight,
              child: Opacity(
                opacity: (1 - t * 2.4).clamp(0.0, 1.0),
                child: IgnorePointer(
                  ignoring: t > 0.3,
                  child: Obx(
                    () => SlidingSegment<DashboardPeriod>(
                      items: DashboardPeriod.values,
                      selected: controller.period.value,
                      label: _periodLabel,
                      onSelect: controller.selectPeriod,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _periodLabel(DashboardPeriod period) => switch (period) {
        DashboardPeriod.today => 'home.today'.tr,
        DashboardPeriod.week => 'home.week'.tr,
        DashboardPeriod.month => 'home.month'.tr,
      };
}

class _Greeting extends GetView<HomeController> {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Obx(() {
      final account = controller.session.account.value;
      if (account == null) return empty;
      final greeting = DateTime.now().hour < 12 ? 'home.morning' : 'home.evening';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            greeting.trParams({'name': account.name.split(' ').first}),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.titleLarge?.copyWith(color: Colors.white),
          ),
          Text(
            account.businessName.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.8)),
          ),
        ],
      );
    });
  }
}

class _Revenue extends GetView<HomeController> {
  const _Revenue();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Obx(() {
      final revenue = controller.summary.value?.kpi('revenue');
      final delta = revenue?.delta;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'kpi.revenue'.tr,
            style: text.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.8)),
          ),
          8.width,
          Expanded(
            child: AnimatedNumber(
              value: revenue?.value ?? 0,
              format: FormatHelper.money,
              style: text.headlineMedium?.copyWith(color: Colors.white),
            ),
          ),
          if (delta != null)
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
                    delta >= 0 ? Iconsax.arrow_up_3 : Iconsax.arrow_down,
                    size: 12.r,
                    color: Colors.white,
                  ),
                  3.width,
                  Text(
                    '${FormatHelper.number(delta.abs())}%',
                    style: text.labelMedium?.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }
}

/// Only the number: the label stays in the expanded header.
class _CollapsedRevenue extends GetView<HomeController> {
  const _CollapsedRevenue();

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => AnimatedNumber(
        value: controller.summary.value?.kpi('revenue')?.value ?? 0,
        format: FormatHelper.money,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
      ),
    );
  }
}

class _BranchButton extends GetView<HomeController> {
  const _BranchButton();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final branches = controller.session.account.value?.branches.length ?? 0;
      if (branches < 2) return empty;
      return Padding(
        padding: EdgeInsetsDirectional.only(end: 8.w),
        child: const BranchPickerChip(),
      );
    });
  }
}

class _Bubble extends StatelessWidget {
  final double size;

  const _Bubble({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.07),
      ),
    );
  }
}
