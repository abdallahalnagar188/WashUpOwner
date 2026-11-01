import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../commons/models/dashboard_summary.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';

class BranchNowCard extends StatelessWidget {
  final LiveBranch branch;

  const BranchNowCard({super.key, required this.branch});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final usage = branch.capacity == 0 ? 0.0 : branch.baysBusy / branch.capacity;
    return RoundedContainer(
      margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 10.h),
      padding: EdgeInsets.all(14.r),
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
          12.height,
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
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: usage,
              minHeight: 6.h,
              backgroundColor: AppColors.primarySoft,
              color: AppColors.primary,
            ),
          ),
          12.height,
          Row(
            children: [
              _Count(label: 'branch.waiting'.tr, value: '${branch.waiting}'),
              _Count(label: 'branch.inService'.tr, value: '${branch.inService}'),
              _Count(label: 'branch.pending'.tr, value: '${branch.paymentPending}'),
            ],
          ),
          10.height,
          Row(
            children: [
              Expanded(
                child: Text(
                  'branch.onShift'.trParams({'count': '${branch.staffOnShift.length}'}),
                  style: text.bodySmall,
                ),
              ),
              Text(
                '${'branch.revenue'.tr}: ${FormatHelper.money(branch.revenueToday)}',
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
  final String value;

  const _Count({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: text.titleLarge),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.labelSmall,
          ),
        ],
      ),
    );
  }
}
