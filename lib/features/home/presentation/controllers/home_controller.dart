import 'package:get/get.dart';

import '../../../../commons/models/dashboard_summary.dart';
import '../../../../core/data/owner_repo.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/services/session_service.dart';
import '../../../main/presentation/controllers/main_controller.dart';

class HomeController extends GetxController {
  final _repo = Get.find<OwnerRepo>();
  final session = Get.find<SessionService>();

  final period = DashboardPeriod.today.obs;
  final summary = Rxn<DashboardSummary>();
  final failed = false.obs;

  // Only the newest request may fill the screen.
  int _requestId = 0;

  @override
  void onInit() {
    super.onInit();
    load();
    ever(session.branchId, (_) => _reload());
    ever(Get.find<MainController>().selectedIndex, (index) {
      if (index == MainController.homeTab) load();
    });
  }

  void selectPeriod(DashboardPeriod value) {
    if (period.value == value) return;
    period.value = value;
    _reload();
  }

  Future<void> load() async {
    final id = ++_requestId;
    failed.value = false;
    try {
      final result = await _repo.dashboard(
        period: period.value,
        branchId: session.branchId.value,
      );
      if (id == _requestId) summary.value = result;
    } catch (_) {
      if (id == _requestId) failed.value = true;
    }
  }

  void _reload() {
    summary.value = null;
    load();
  }
}
