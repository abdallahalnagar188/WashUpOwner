import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../../commons/models/day_closing.dart';
import '../../../../commons/widgets/layout/brand_header.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
import '../../common/widgets/manage_cards.dart';
import '../../common/widgets/manage_page.dart';
import '../controllers/day_closing_controller.dart';
import '../widgets/day_closing_form.dart';

class DayClosingPage extends GetView<DayClosingController> {
  const DayClosingPage({super.key});

  Future<void> _pickDate(BuildContext context) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.date.value,
      firstDate: today.subtract(const Duration(days: 365)),
      lastDate: today,
    );
    if (picked != null) controller.selectDate(picked);
  }

  String _dayLabel(DateTime day) {
    final lang = Get.locale?.languageCode ?? 'ar';
    return DateFormat('EEEE d MMMM', lang).format(day);
  }

  @override
  Widget build(BuildContext context) {
    final branches = controller.session.account.value?.branches ?? const [];
    return Obx(
      () => ManagePage(
        title: 'closing.title'.tr,
        subtitle: _dayLabel(controller.date.value),
        trailing: HeaderButton(icon: Iconsax.calendar_1, onTap: () => _pickDate(context)),
        body: Column(
          children: [
            if (branches.length > 1)
              ChipBar<String>(
                values: branches.map((b) => b.id).toList(),
                selected: controller.branchId.value,
                label: (id) => branches.firstWhere((b) => b.id == id).name.shown,
                onSelect: controller.selectBranch,
              ),
            _DayStepper(controller: controller),
            Expanded(
              child: manageLoader(
                ready: controller.data.value != null,
                error: controller.error.value,
                onRetry: controller.load,
                content: () => _content(context, controller.data.value!),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, DayClosing day) {
    final closing = day.closing;
    return ManageScroll(
      onRefresh: () => controller.load(silent: true),
      children: [
        TileGrid(
          tiles: [
            StatTile(label: 'closing.expected.cash'.tr, value: day.expected.cash, format: FormatHelper.money, icon: Iconsax.money_3),
            StatTile(label: 'closing.expected.card'.tr, value: day.expected.card, format: FormatHelper.money, icon: Iconsax.card),
            StatTile(label: 'closing.expected.online'.tr, value: day.expected.online, format: FormatHelper.money, icon: Iconsax.global),
            StatTile(label: 'closing.completed'.tr, value: day.completedOrders, icon: Iconsax.task_square),
          ],
        ),
        12.height,
        if (closing != null)
          _ClosingReport(closing: closing)
        else ...[
          if (day.hasOpenOrders)
            NoticeCard(
              text: 'closing.blocked'.trParams({
                'inService': '${day.inServiceOrders}',
                'unpaid': '${day.unpaidOrders}',
              }),
              icon: Iconsax.warning_2,
              color: AppColors.warning,
            ),
          if (controller.canClose)
            DayClosingForm(key: ValueKey('${day.branchId}-${day.date}'), day: day, onSubmit: controller.close)
          else
            NoticeCard(text: 'closing.noPermission'.tr, icon: Iconsax.lock_1),
        ],
        if (day.history.isNotEmpty)
          SectionCard(
            title: 'closing.history'.tr,
            children: [
              for (final record in day.history)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(record.date, textDirection: TextDirection.ltr, textAlign: TextAlign.start),
                  subtitle: Text(record.closedByName),
                  trailing: Text(FormatHelper.money(record.difference), textDirection: TextDirection.ltr),
                  onTap: () {
                    final date = DateTime.tryParse(record.date);
                    if (date != null) controller.selectDate(date);
                  },
                ),
            ],
          ),
      ],
    );
  }
}

class _DayStepper extends StatelessWidget {
  final DayClosingController controller;

  const _DayStepper({required this.controller});

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final date = controller.date.value;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: () => controller.selectDate(DateUtils.addDaysToDate(date, -1)),
            icon: Icon(rtl ? Iconsax.arrow_right_3 : Iconsax.arrow_left_2, size: 16.r),
            label: Text('closing.previous'.tr),
          ),
          TextButton.icon(
            onPressed: controller.isToday
                ? null
                : () => controller.selectDate(DateUtils.addDaysToDate(date, 1)),
            icon: Icon(rtl ? Iconsax.arrow_left_2 : Iconsax.arrow_right_3, size: 16.r),
            label: Text('closing.next'.tr),
          ),
        ],
      ),
    );
  }
}

class _ClosingReport extends StatelessWidget {
  static const List<String> _methods = ['cash', 'card', 'online'];

  final ClosingRecord closing;

  const _ClosingReport({required this.closing});

  @override
  Widget build(BuildContext context) {
    final difference = closing.difference;
    return SectionCard(
      title: 'closing.report'.tr,
      children: [
        for (final method in _methods)
          InfoRow(
            'method.$method'.tr,
            '${FormatHelper.money(closing.actual.of(method))} / ${FormatHelper.money(closing.expected.of(method))}',
          ),
        InfoRow('closing.total'.tr, FormatHelper.money(closing.actual.total), strong: true),
        InfoRow(
          difference == 0 ? 'closing.matched'.tr : 'closing.differenceLabel'.tr,
          FormatHelper.money(difference),
          strong: true,
        ),
        if (closing.reason != null) InfoRow('sheet.reason'.tr, closing.reason!),
        InfoRow('closing.closedBy'.tr, closing.closedByName),
        if (closing.closedAt != null) InfoRow('closing.closedAt'.tr, FormatHelper.dayTime(closing.closedAt!)),
        InfoRow('closing.locked'.tr, FormatHelper.number(closing.ordersLocked)),
      ],
    );
  }
}
