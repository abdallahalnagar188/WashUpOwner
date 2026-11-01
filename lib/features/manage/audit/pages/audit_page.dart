import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/audit_entry.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../commons/widgets/layout/branch_picker.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
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
    final oldValue = entry.oldValue;
    final newValue = entry.newValue;
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
          if (oldValue != null || newValue != null) ...[
            6.height,
            Text(
              [oldValue ?? '-', newValue ?? '-'].join(' ← '),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall,
            ),
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
