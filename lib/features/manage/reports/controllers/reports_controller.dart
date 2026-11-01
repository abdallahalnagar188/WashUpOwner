import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../commons/models/vendor_report.dart';
import '../../../../core/services/session_service.dart';
import '../../common/controllers/manage_controller.dart';
import '../../common/widgets/manage_cards.dart';

class ReportsController extends LoadController<VendorReport> {
  /// The server's type values; `source` and `employees` are the sources and
  /// staff reports.
  static const List<String> types = ['orders', 'revenue', 'services', 'source', 'employees'];
  static const List<String> ranges = ['7d', '14d', '30d', 'month'];

  final type = types.first.obs;
  final range = '14d'.obs;

  bool get singleBranch => session.branchId.value != SessionService.allBranches;

  /// First and last day of [range], counted back from today.
  static (String, String) datesFor(String range, DateTime today) {
    final from = switch (range) {
      '7d' => DateUtils.addDaysToDate(today, -6),
      '30d' => DateUtils.addDaysToDate(today, -29),
      'month' => DateTime(today.year, today.month),
      _ => DateUtils.addDaysToDate(today, -13),
    };
    return (apiDate(from), apiDate(today));
  }

  @override
  void onInit() {
    super.onInit();
    load();
    ever(session.branchId, (_) => load());
  }

  @override
  Future<VendorReport> fetch() {
    final (from, to) = datesFor(range.value, DateUtils.dateOnly(DateTime.now()));
    return api.report(type: type.value, branchId: session.branchId.value, from: from, to: to);
  }

  void selectType(String value) {
    if (type.value == value) return;
    type.value = value;
    load();
  }

  void selectRange(String value) {
    if (range.value == value) return;
    range.value = value;
    load();
  }
}
