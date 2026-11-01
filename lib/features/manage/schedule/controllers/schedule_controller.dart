import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../commons/models/schedule_day.dart';
import '../../common/controllers/manage_controller.dart';
import '../../common/widgets/manage_cards.dart';

class ScheduleController extends LoadController<ScheduleDay> {
  /// The grid shows one branch, so "all branches" narrows to a real one.
  late final branchId = (session.workingBranchId ?? '').obs;
  final date = DateUtils.dateOnly(DateTime.now()).obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  Future<ScheduleDay> fetch() =>
      api.schedule(branchId: branchId.value, date: apiDate(date.value));

  void selectDate(DateTime value) {
    final day = DateUtils.dateOnly(value);
    if (day == date.value) return;
    date.value = day;
    load();
  }

  void selectBranch(String id) {
    if (id == branchId.value) return;
    branchId.value = id;
    load();
  }

  Future<bool> block({required String start, required String end, required String reason}) => write(
        () => api.blockSlot(branchId: branchId.value, start: start, end: end, reason: reason),
        reload: () => load(silent: true),
      );

  Future<bool> removeBlock(ScheduleBlock block) => write(
        () => api.removeBlock(block.id),
        reload: () => load(silent: true),
      );
}
