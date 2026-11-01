import 'package:get/get.dart';

import '../../../../commons/models/json_read.dart';
import '../../../../commons/models/shift.dart';
import '../../../../core/network/api_client.dart';
import '../../common/controllers/manage_controller.dart';

class ShiftsController extends PagedController<Shift> {
  static const List<String> filters = ['submitted', 'difference', 'open', 'flagged', 'reviewed', 'all'];

  final filter = filters.first.obs;

  Map<String, int> get counts => readCounts(meta['counts']);

  ShiftTotals get totals => ShiftTotals.fromJson(readMap(meta['totals']));

  @override
  void onInit() {
    super.onInit();
    load();
    ever(session.branchId, (_) => load());
  }

  @override
  Future<ApiPage<Shift>> fetchPage(int page) =>
      api.shifts(branchId: session.branchId.value, filter: filter.value, page: page);

  void selectFilter(String value) {
    if (filter.value == value) return;
    filter.value = value;
    load();
  }
}
