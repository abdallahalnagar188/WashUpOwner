import 'json_read.dart';

class ReportStat {
  final String label;
  final dynamic value;
  final String format;

  const ReportStat({required this.label, required this.value, required this.format});

  factory ReportStat.fromJson(Map<String, dynamic> json) => ReportStat(
        label: readStr(json['label']),
        value: json['value'],
        format: readStr(json['format']).isEmpty ? 'text' : readStr(json['format']),
      );
}

class ReportPoint {
  final String label;
  final num value;

  const ReportPoint({required this.label, required this.value});

  factory ReportPoint.fromJson(Map<String, dynamic> json) => ReportPoint(
        label: readStr(json['label']),
        value: readNum(json['value']),
      );
}

class ReportColumn {
  final String key;
  final String label;
  final String format;
  final bool alignEnd;

  const ReportColumn({
    required this.key,
    required this.label,
    required this.format,
    required this.alignEnd,
  });

  factory ReportColumn.fromJson(Map<String, dynamic> json) => ReportColumn(
        key: readStr(json['key']),
        label: readStr(json['label']),
        format: readStr(json['format']).isEmpty ? 'text' : readStr(json['format']),
        alignEnd: json['align'] == 'end',
      );
}

class VendorReport {
  final String type;
  final List<ReportStat> summary;
  final List<ReportPoint> chart;
  final String chartKind;
  final String valueFormat;
  final List<ReportColumn> columns;
  final List<Map<String, dynamic>> rows;

  const VendorReport({
    required this.type,
    required this.summary,
    required this.chart,
    required this.chartKind,
    required this.valueFormat,
    required this.columns,
    required this.rows,
  });

  factory VendorReport.fromJson(Map<String, dynamic> json) => VendorReport(
        type: readStr(json['type']),
        summary: readMaps(json['summary']).map(ReportStat.fromJson).toList(),
        chart: readMaps(json['chart']).map(ReportPoint.fromJson).toList(),
        chartKind: readStr(json['chartKind']),
        valueFormat: readStr(json['valueFormat']).isEmpty ? 'number' : readStr(json['valueFormat']),
        columns: readMaps(json['columns']).map(ReportColumn.fromJson).toList(),
        rows: readMaps(json['rows']),
      );
}
