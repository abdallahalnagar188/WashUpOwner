import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/audit_entry.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../commons/widgets/layout/branch_picker.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
import '../audit_format.dart';
import '../../common/widgets/manage_cards.dart';
import '../../common/widgets/manage_page.dart';
import '../controllers/audit_controller.dart';

class AuditPage extends GetView<AuditController> {
  const AuditPage({super.key});

  @override
  Widget build(BuildContext context) {
    final branches = controller.session.account.value?.branches ?? const [];
    return ManagePage(
      title: 'more.audit'.tr,
      subtitle: 'audit.readOnly'.tr,
      headerChild: branches.length > 1 ? const BranchPickerChip() : null,
      body: Obx(_list),
    );
  }

  Widget _list() {
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
      emptyIcon: Iconsax.document_text,
      emptyTitle: 'audit.empty'.tr,
      itemBuilder: (_, index) => _AuditCard(entry: items[index]),
    );
  }
}

class _AuditCard extends StatelessWidget {
  final AuditEntry entry;

  const _AuditCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final changes = AuditFormat.changes(entry);
    return RoundedContainer(
      padding: EdgeInsets.all(14.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(labelOr('audit.action.${entry.action}', entry.action), style: text.titleSmall),
          3.height,
          Text(
            [
              entry.actorName,
              if (entry.at != null) FormatHelper.dayTime(entry.at!),
              if (entry.branchName != null) entry.branchName!.shown,
            ].where((part) => part.isNotEmpty).join(' · '),
            style: text.bodySmall,
          ),
          if (changes.isNotEmpty) ...[
            8.height,
            for (final change in changes.take(4)) _ChangeLine(change: change),
          ],
          if (entry.reason != null) ...[
            6.height,
            Text('audit.reason'.trParams({'text': entry.reason!}), style: text.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _ChangeLine extends StatelessWidget {
  final AuditChange change;

  const _ChangeLine({required this.change});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final from = change.from;
    final to = change.to;
    return Padding(
      padding: EdgeInsets.only(top: 3.h),
      child: Wrap(
        spacing: 6.w,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (change.label != null) Text('${change.label}:', style: text.bodySmall),
          if (from != null)
            Text(
              from,
              style: text.bodySmall?.copyWith(
                color: AppColors.ink500,
                decoration: to == null ? null : TextDecoration.lineThrough,
              ),
            ),
          if (from != null && to != null) Icon(
              Directionality.of(context) == TextDirection.rtl ? Iconsax.arrow_left : Iconsax.arrow_right,
              size: 13.r,
              color: AppColors.ink500,
            ),
          if (to != null) Text(to, style: text.labelMedium?.copyWith(color: AppColors.ink900)),
        ],
      ),
    );
  }
}
