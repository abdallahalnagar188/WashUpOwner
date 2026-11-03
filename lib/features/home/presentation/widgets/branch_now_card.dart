import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../commons/models/dashboard_summary.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../commons/widgets/effects/animated_bar.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
import '../../../../core/services/session_service.dart';

class BranchNowCard extends StatelessWidget {
  final LiveBranch branch;

  const BranchNowCard({super.key, required this.branch});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final usage = branch.capacity == 0 ? 0.0 : branch.baysBusy / branch.capacity;
    return RoundedContainer(
      margin: EdgeInsets.fromLTRB(20.w, 0, 20.w, 12.h),
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(branch.name.value, style: text.titleMedium),
                    Text('${branch.opensAt} – ${branch.closesAt}', style: text.bodySmall),
                  ],
                ),
              ),
              StatusBadge(
                label: (branch.isOpen ? 'branch.open' : 'branch.closed').tr,
                color: branch.isOpen ? AppColors.success : AppColors.statusNoShow,
              ),
            ],
          ),
          14.height,
          Row(
            children: [
              Expanded(child: Text('branch.bays'.tr, style: text.bodySmall)),
              Text(
                '${branch.baysBusy} / ${branch.capacity}',
                textDirection: TextDirection.ltr,
                style: text.labelLarge,
              ),
            ],
          ),
          6.height,
          AnimatedBar(value: usage),
          14.height,
          Row(
            children: [
              _Count(label: 'branch.waiting'.tr, value: branch.waiting, color: AppColors.statusWaiting),
              _Count(label: 'branch.inService'.tr, value: branch.inService, color: AppColors.statusInService),
              _Count(label: 'branch.pending'.tr, value: branch.paymentPending, color: AppColors.warning),
            ],
          ),
          12.height,
          Row(
            children: [
              Expanded(
                child: Text(
                  'branch.onShift'.trParams({'count': '${branch.staffOnShift.length}'}),
                  style: text.bodySmall,
                ),
              ),
              Text(
                '${'branch.revenue'.tr}: ${FormatHelper.money(branch.revenueToday, locale: Get.find<SessionService>().localeOf(branch.id))}',
                style: text.labelMedium?.copyWith(color: AppColors.ink900),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Count extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _Count({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        margin: EdgeInsetsDirectional.only(end: 8.w),
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: AppColors.tint(color, 0.08),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          children: [
            Text('$value', style: text.titleLarge?.copyWith(color: color)),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
