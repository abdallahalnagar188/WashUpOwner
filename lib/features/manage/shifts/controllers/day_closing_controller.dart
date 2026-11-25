import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../commons/models/branch_locale.dart';
import '../../../../commons/models/day_closing.dart';
import '../../../../commons/models/owner_account.dart';
import '../../common/controllers/manage_controller.dart';
import '../../common/widgets/manage_cards.dart';

class DayClosingController extends LoadController<DayClosing> {
  /// Closing happens per branch, so "all branches" narrows to a real one.
  late final branchId = (session.workingBranchId ?? '').obs;
  /// The branch's day, not the phone's: near midnight they differ (GAP-069).
  late final date = today.obs;

  DateTime get today => BranchLocale.todayOf(session.localeOf(branchId.value));

  bool get canClose => session.can(OwnerPermission.closeShift);

  bool get isToday => DateUtils.isSameDay(date.value, today);

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  Future<DayClosing> fetch() => api.dayClosing(branchId: branchId.value, date: apiDate(date.value));

  void selectDate(DateTime value) {
    final today = this.today;
    final day = DateUtils.dateOnly(value);
    if (day == date.value || day.isAfter(today)) return;
    date.value = day;
    load();
  }

  void selectBranch(String id) {
    if (id == branchId.value) return;
    branchId.value = id;
    load();
  }

  Future<bool> close({
    required num cash,
    required num card,
    required num online,
    String? reason,
  }) {
    final day = data.value!;
    return write(
      () => api.closeDay(
        branchId: day.branchId,
        date: day.date,
        cash: cash,
        card: card,
        online: online,
        reason: reason,
      ),
      reload: () => load(silent: true),
      doneText: 'closing.done'.tr,
    );
  }
}
