import 'package:get/get.dart';

import '../../../../commons/models/finance_summary.dart';
import '../../common/controllers/manage_controller.dart';

class FinanceController extends LoadController<FinanceSummary> {
  static const List<String> periods = ['today', '7d', '30d'];

  final period = '30d'.obs;

  @override
  void onInit() {
    super.onInit();
    load();
    ever(session.branchId, (_) => load());
  }

  @override
  Future<FinanceSummary> fetch() =>
      api.finance(branchId: session.branchId.value, period: period.value);

  void selectPeriod(String value) {
    if (period.value == value) return;
    period.value = value;
    load();
  }
}
