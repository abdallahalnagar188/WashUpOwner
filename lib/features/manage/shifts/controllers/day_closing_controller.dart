import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../commons/models/day_closing.dart';
import '../../../../commons/models/owner_account.dart';
import '../../common/controllers/manage_controller.dart';
import '../../common/widgets/manage_cards.dart';

class DayClosingController extends LoadController<DayClosing> {
  /// Closing happens per branch, so "all branches" narrows to a real one.
  late final branchId = (session.workingBranchId ?? '').obs;
  final date = DateUtils.dateOnly(DateTime.now()).obs;

  bool get canClose => session.can(OwnerPermission.closeShift);

  bool get isToday => DateUtils.isSameDay(date.value, DateTime.now());

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  Future<DayClosing> fetch() => api.dayClosing(branchId: branchId.value, date: apiDate(date.value));

  void selectDate(DateTime value) {
    final today = DateUtils.dateOnly(DateTime.now());
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
