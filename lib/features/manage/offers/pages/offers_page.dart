import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/offer.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../commons/widgets/layout/branch_picker.dart';
import '../../../../commons/widgets/layout/brand_header.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
import '../../common/widgets/manage_cards.dart';
import '../../common/widgets/manage_page.dart';
import '../../common/widgets/manage_sheets.dart';
import '../controllers/offers_controller.dart';
import '../widgets/offer_form_sheet.dart';

class OffersPage extends GetView<OffersController> {
  const OffersPage({super.key});

  Future<void> _openForm(BuildContext context, [Offer? offer]) => showManageSheet<void>(
        context,
        OfferFormSheet(offer: offer, onSubmit: controller.save),
      );

  String _statusLabel(String status) {
    final name = status == OffersController.allStatuses ? 'manage.all'.tr : 'offers.status.$status'.tr;
    final counts = controller.data.value?.counts;
    if (counts == null) return name;
    final count = status == OffersController.allStatuses
        ? counts.values.fold<int>(0, (sum, value) => sum + value)
        : counts[status];
    return count == null ? name : '$name ($count)';
  }

  @override
  Widget build(BuildContext context) {
    final branches = controller.session.account.value?.branches ?? const [];
    return Obx(
      () => ManagePage(
        title: 'more.offers'.tr,
        trailing: controller.isOwner
            ? HeaderButton(icon: Iconsax.add, onTap: () => _openForm(context))
            : null,
        headerChild: branches.length > 1 ? const BranchPickerChip() : null,
        body: Column(
          children: [
            ChipBar<String>(
              values: const [OffersController.allStatuses, ...Offer.statuses],
              selected: controller.status.value,
              label: _statusLabel,
              onSelect: (value) => controller.status.value = value,
            ),
            Expanded(
              child: manageLoader(
                ready: controller.data.value != null,
                error: controller.error.value,
                onRetry: controller.load,
                content: () {
                  final offers = controller.visible;
                  return ManageList(
                    onRefresh: () => controller.load(silent: true),
                    itemCount: offers.length,
                    emptyIcon: Iconsax.discount_shape,
                    emptyTitle: 'offers.empty'.tr,
                    itemBuilder: (_, index) {
                      final offer = offers[index];
                      return _OfferCard(
                        offer: offer,
                        canManage: controller.isOwner,
                        busy: controller.toggling.contains(offer.id),
                        onEdit: () => _openForm(context, offer),
                        onToggle: (value) => controller.setEnabled(offer, value),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final Offer offer;
  final bool canManage;
  final bool busy;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggle;

  const _OfferCard({
    required this.offer,
    required this.canManage,
    required this.busy,
    required this.onEdit,
    required this.onToggle,
  });

  Color get _statusColor => switch (offer.status) {
        'active' => AppColors.success,
        'scheduled' => AppColors.info,
        'disabled' => AppColors.danger,
        _ => AppColors.statusNoShow,
      };

  String get _discount => offer.discountType == 'percent'
      ? '${FormatHelper.number(offer.discountValue)}%'
      : FormatHelper.money(offer.discountValue);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final start = offer.startAt;
    final end = offer.endAt;
    final canEdit = canManage && offer.editable;
    return RoundedContainer(
      padding: EdgeInsets.all(14.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(offer.title.shown, style: text.titleSmall)),
              8.width,
              StatusBadge(
                label: labelOr('offers.status.${offer.status}', offer.status),
                color: _statusColor,
              ),
            ],
          ),
          if (offer.description.shown.isNotEmpty) ...[
            4.height,
            Text(offer.description.shown, style: text.bodySmall),
          ],
          8.height,
          Text(
            'offers.discountLine'.trParams({'value': _discount, 'count': '${offer.redemptions}'}),
            style: text.titleSmall?.copyWith(color: AppColors.primary),
          ),
          if (start != null && end != null) ...[
            4.height,
            Text('${FormatHelper.dayTime(start)} - ${FormatHelper.dayTime(end)}', style: text.bodySmall),
          ],
          4.height,
          Text(
            offer.serviceCategories.isEmpty
                ? 'offers.allServices'.tr
                : offer.serviceCategories
                    .map((category) => labelOr('services.category.$category', category))
                    .join('manage.listJoin'.tr),
            style: text.bodySmall,
          ),
          if (offer.isPlatform) ...[
            6.height,
            Text('offers.platform'.tr, style: text.labelSmall?.copyWith(color: AppColors.info)),
          ],
          if (canEdit)
            Row(
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: Icon(Iconsax.edit_2, size: 16.r),
                  label: Text(offer.isDraft ? 'offers.review'.tr : 'manage.edit'.tr),
                ),
                const Spacer(),
                if (offer.canToggle)
                  Switch.adaptive(activeTrackColor: AppColors.primary, value: offer.enabled, onChanged: busy ? null : onToggle),
              ],
            ),
        ],
      ),
    );
  }
}
