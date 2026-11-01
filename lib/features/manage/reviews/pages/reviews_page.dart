import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/review.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../commons/widgets/effects/animated_bar.dart';
import '../../../../commons/widgets/effects/animated_number.dart';
import '../../../../commons/widgets/layout/branch_picker.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
import '../../common/widgets/manage_cards.dart';
import '../../common/widgets/manage_page.dart';
import '../../common/widgets/manage_sheets.dart';
import '../controllers/reviews_controller.dart';
import '../widgets/review_reply_sheet.dart';

class ReviewsPage extends GetView<ReviewsController> {
  const ReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final branches = controller.session.account.value?.branches ?? const [];
    return ManagePage(
      title: 'more.reviews'.tr,
      headerChild: branches.length > 1 ? const BranchPickerChip() : null,
      body: Obx(() => _list(context)),
    );
  }

  void _reply(BuildContext context, Review review) {
    showManageSheet<void>(
      context,
      ReviewReplySheet(review: review, onSubmit: (text) => controller.reply(review, text)),
    );
  }

  void _report(BuildContext context, Review review) {
    showReasonSheet(
      context,
      title: 'reviews.report'.tr,
      body: 'reviews.reportBody'.tr,
      okText: 'reviews.reportSend'.tr,
      danger: true,
      presets: [
        'reviews.preset.notVisited'.tr,
        'reviews.preset.abusive'.tr,
        'reviews.preset.falseInfo'.tr,
        'reviews.preset.competition'.tr,
      ],
      onSubmit: (reason) => controller.report(review, reason),
    );
  }

  Widget _list(BuildContext context) {
    if (controller.loading.value) return const AppShimmerList();
    if (controller.error.value != null) {
      return AppErrorState(message: controller.error.value, onRetry: controller.load);
    }
    final items = controller.items;
    return ManageList(
      onRefresh: controller.load,
      onLoadMore: controller.loadMore,
      loadingMore: controller.loadingMore.value,
      itemCount: items.length,
      emptyIcon: Iconsax.star,
      emptyTitle: 'reviews.empty'.tr,
      header: _StatsCard(stats: controller.stats),
      itemBuilder: (_, index) => _ReviewCard(
        review: items[index],
        onReply: () => _reply(context, items[index]),
        onReport: () => _report(context, items[index]),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final ReviewStats stats;

  const _StatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: RoundedContainer(
        child: Row(
          children: [
            Column(
              children: [
                AnimatedNumber(
                  value: stats.average.toDouble(),
                  format: (value) => value.toStringAsFixed(1),
                  style: text.headlineMedium,
                ),
                Icon(Iconsax.star1, size: 20.r, color: AppColors.star),
                4.height,
                Text('reviews.count'.trParams({'count': '${stats.count}'}), style: text.labelSmall),
              ],
            ),
            16.width,
            Expanded(
              child: Column(
                children: [
                  for (final entry in stats.distribution.entries)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      child: Row(
                        children: [
                          SizedBox(width: 14.w, child: Text('${entry.key}', style: text.labelSmall)),
                          6.width,
                          Expanded(
                            child: AnimatedBar(
                              value: stats.count == 0 ? 0 : entry.value / stats.count,
                              height: 6.h,
                            ),
                          ),
                          6.width,
                          SizedBox(
                            width: 22.w,
                            child: Text('${entry.value}', textAlign: TextAlign.end, style: text.labelSmall),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;
  final VoidCallback onReply;
  final VoidCallback onReport;

  const _ReviewCard({required this.review, required this.onReply, required this.onReport});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return RoundedContainer(
      padding: EdgeInsets.all(14.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var star = 1; star <= 5; star++)
                Icon(
                  Iconsax.star1,
                  size: 15.r,
                  color: star <= review.stars ? AppColors.star : AppColors.line,
                ),
              const Spacer(),
              if (review.reportedByWash)
                StatusBadge(label: 'reviews.reported'.tr, color: AppColors.warning)
              else if (review.reply != null)
                StatusBadge(label: 'reviews.replied'.tr, color: AppColors.success),
            ],
          ),
          8.height,
          Text(
            review.comment.shown.isEmpty ? 'reviews.noComment'.tr : review.comment.shown,
            style: review.comment.shown.isEmpty ? text.bodySmall : text.bodyMedium,
          ),
          if (review.tags.isNotEmpty) ...[
            6.height,
            Wrap(
              spacing: 6.w,
              runSpacing: 4.h,
              children: [
                for (final tag in review.tags)
                  Text(labelOr('reviews.tag.$tag', tag), style: text.labelSmall?.copyWith(color: AppColors.primary)),
              ],
            ),
          ],
          8.height,
          Text(
            [
              review.customerName,
              review.serviceName.shown,
              if (review.createdAt != null) FormatHelper.dayTime(review.createdAt!),
            ].where((part) => part.isNotEmpty).join(' · '),
            style: text.bodySmall,
          ),
          if (review.reply != null) ...[
            8.height,
            RoundedContainer(
              shadow: false,
              color: AppColors.secondarySoft,
              borderColor: Colors.transparent,
              padding: EdgeInsets.all(10.r),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'reviews.yourReply'.trParams({'text': review.reply!}),
                      style: text.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (review.reportedByWash) ...[
            6.height,
            Text(
              review.reportReason ?? 'reviews.underReview'.tr,
              style: text.bodySmall?.copyWith(color: AppColors.warning),
            ),
          ],
          if (review.reply == null || !review.reportedByWash)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!review.reportedByWash)
                  TextButton(onPressed: onReport, child: Text('reviews.report'.tr)),
                if (review.reply == null)
                  TextButton(onPressed: onReply, child: Text('reviews.reply'.tr)),
              ],
            ),
        ],
      ),
    );
  }
}
