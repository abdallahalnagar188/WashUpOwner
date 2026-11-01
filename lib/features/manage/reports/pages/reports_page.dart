import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/vendor_report.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../commons/widgets/layout/branch_picker.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../common/widgets/manage_cards.dart';
import '../../common/widgets/manage_page.dart';
import '../controllers/reports_controller.dart';
import '../widgets/report_chart.dart';
import '../widgets/report_table.dart';
import '../widgets/report_value.dart';

class ReportsPage extends GetView<ReportsController> {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final branches = controller.session.account.value?.branches ?? const [];
    return ManagePage(
      title: 'more.reports'.tr,
      headerChild: branches.length > 1 ? const BranchPickerChip() : null,
      body: Column(
        children: [
          Obx(
            () => ChipBar<String>(
              values: ReportsController.types,
              selected: controller.type.value,
              label: (type) => 'reports.type.$type'.tr,
              onSelect: controller.selectType,
            ),
          ),
          Obx(
            () => ChipBar<String>(
              values: ReportsController.ranges,
              selected: controller.range.value,
              label: (range) => 'reports.range.$range'.tr,
              onSelect: controller.selectRange,
            ),
          ),
          Expanded(
            child: Obx(
              () => manageLoader(
                ready: controller.data.value != null,
                error: controller.error.value,
                onRetry: controller.load,
                content: () => _content(controller.data.value!),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(VendorReport report) {
    final columns = report.columns
        .where((column) => !controller.singleBranch || column.key != 'branch')
        .toList();
    return ManageScroll(
      onRefresh: () => controller.load(silent: true),
      children: [
        TileGrid(tiles: [for (final stat in report.summary) ReportStatTile(stat: stat)]),
        12.height,
        if (report.rows.isEmpty)
          CustomEmptyState(icon: Iconsax.chart, title: 'reports.empty'.tr)
        else ...[
          SectionCard(
            title: 'reports.chart'.tr,
            children: [ReportChart(points: report.chart, format: report.valueFormat)],
          ),
          SectionCard(
            title: 'reports.table'.tr,
            children: [ReportTable(columns: columns, rows: report.rows)],
          ),
        ],
      ],
    );
  }
}
