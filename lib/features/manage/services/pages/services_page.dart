import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/managed_service.dart';
import '../../../../commons/widgets/effects/pressable.dart';
import '../../../../commons/widgets/layout/branch_picker.dart';
import '../../../../commons/widgets/layout/brand_header.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
import '../../common/widgets/manage_cards.dart';
import '../../common/widgets/manage_page.dart';
import '../../common/widgets/manage_sheets.dart';
import '../controllers/services_controller.dart';
import '../widgets/service_form_sheet.dart';

class ServicesPage extends GetView<ServicesController> {
  const ServicesPage({super.key});

  Future<void> _openForm(BuildContext context, [ManagedService? service]) => showManageSheet<void>(
        context,
        ServiceFormSheet(service: service, onSubmit: controller.save),
      );

  @override
  Widget build(BuildContext context) {
    final branches = controller.session.account.value?.branches ?? const [];
    return Obx(() {
      final list = controller.data.value;
      final canEdit = list?.canEdit ?? false;
      return ManagePage(
        title: 'more.services'.tr,
        trailing: canEdit
            ? HeaderButton(icon: Iconsax.add, onTap: () => _openForm(context))
            : null,
        headerChild: branches.length > 1 ? const BranchPickerChip() : null,
        body: manageLoader(
          ready: list != null,
          error: controller.error.value,
          onRetry: controller.load,
          content: () => _content(context, list!),
        ),
      );
    });
  }

  Widget _content(BuildContext context, ServiceList list) {
    final groups = controller.byBranch;
    if (groups.isEmpty) {
      return ManageList(
        onRefresh: () => controller.load(silent: true),
        itemCount: 0,
        itemBuilder: (_, __) => empty,
        emptyIcon: Iconsax.brush_1,
        emptyTitle: 'services.empty'.tr,
      );
    }
    return ManageScroll(
      onRefresh: () => controller.load(silent: true),
      children: [
        if (!list.canEdit) NoticeCard(text: 'services.readOnly'.tr, icon: Iconsax.lock_1),
        for (final group in groups.values)
          SectionCard(
            title: group.first.branchName.shown,
            children: [
              for (final service in group)
                _ServiceRow(
                  service: service,
                  canEdit: list.canEdit,
                  busy: controller.toggling.contains(service.id),
                  onTap: () => _openForm(context, service),
                  onToggle: (value) => controller.setActive(service, value),
                ),
            ],
          ),
      ],
    );
  }
}

class _ServiceRow extends StatelessWidget {
  final ManagedService service;
  final bool canEdit;
  final bool busy;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;

  const _ServiceRow({
    required this.service,
    required this.canEdit,
    required this.busy,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Pressable(
      onTap: canEdit ? onTap : null,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 6.h),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6.w,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        service.name.shown,
                        style: text.titleSmall?.copyWith(color: service.active ? null : AppColors.ink500),
                      ),
                      if (service.isAddon)
                        Text('services.type.addon'.tr, style: text.labelSmall?.copyWith(color: AppColors.primary)),
                    ],
                  ),
                  3.height,
                  Text(
                    '${FormatHelper.money(service.price)} · ${'services.minutes'.trParams({
                          'count': FormatHelper.number(service.durationMin),
                        })}',
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
            8.width,
            Switch.adaptive(activeTrackColor: AppColors.primary, 
              value: service.active,
              onChanged: canEdit && !busy ? onToggle : null,
            ),
          ],
        ),
      ),
    );
  }
}
