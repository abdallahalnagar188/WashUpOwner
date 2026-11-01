import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../commons/models/vendor_report.dart';
import 'report_value.dart';

/// The report's rows; the server names the columns and how to show each.
class ReportTable extends StatelessWidget {
  final List<ReportColumn> columns;
  final List<Map<String, dynamic>> rows;

  const ReportTable({super.key, required this.columns, required this.rows});

  String _heading(ReportColumn column) {
    final key = 'reports.column.${column.key}';
    final text = key.tr;
    return text == key ? column.label : text;
  }

  String _cell(Map<String, dynamic> row, ReportColumn column) {
    final value = row[column.key];
    if (column.key == 'rating' && value == 0) return '-';
    return reportValue(value, column.format);
  }

  @override
  Widget build(BuildContext context) {
    if (columns.isEmpty) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 36.h,
        dataRowMinHeight: 34.h,
        dataRowMaxHeight: 44.h,
        horizontalMargin: 0,
        columnSpacing: 22.w,
        columns: [
          for (final column in columns)
            DataColumn(numeric: column.alignEnd, label: Text(_heading(column), style: text.labelMedium)),
        ],
        rows: [
          for (final row in rows)
            DataRow(
              cells: [
                for (final column in columns) DataCell(Text(_cell(row, column), style: text.bodySmall)),
              ],
            ),
        ],
      ),
    );
  }
}
