import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../commons/models/vendor_report.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
import '../../common/widgets/manage_cards.dart';

/// A report cell the way the server's `format` asks for it.
String reportValue(dynamic value, String format) {
  if (value == null || value == '') return '-';
  if (value is! num) return value.toString();
  return switch (format) {
    'money' => FormatHelper.money(value),
    'percent' => '${FormatHelper.number(value)}%',
    _ => FormatHelper.number(value),
  };
}

/// Summary labels arrive in Arabic only; known ones have English text.
String reportLabel(String label) {
  final key = 'reports.stat.$label';
  final text = key.tr;
  return text == key ? label : text;
}

/// A summary value can be text too, such as the most ordered service.
class ReportStatTile extends StatelessWidget {
  final ReportStat stat;

  const ReportStatTile({super.key, required this.stat});

  @override
  Widget build(BuildContext context) {
    final value = stat.value;
    if (value is num) {
      return StatTile(
        label: reportLabel(stat.label),
        value: value,
        format: (current) => reportValue(current, stat.format),
      );
    }
    final text = Theme.of(context).textTheme;
    return RoundedContainer(
      padding: EdgeInsets.all(14.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(reportLabel(stat.label), style: text.bodySmall),
          4.height,
          Text(
            reportValue(value, stat.format),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.titleSmall,
          ),
        ],
      ),
    );
  }
}
