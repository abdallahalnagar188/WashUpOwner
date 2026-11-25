import 'package:get/get.dart';

import '../../../../commons/models/dashboard_summary.dart';
import '../../../../core/data/vendor_api.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/utils/poller.dart';
import '../../../../core/utils/workers.dart';
import '../../../main/presentation/controllers/main_controller.dart';

class HomeController extends GetxController with DisposesWorkers {
  static const Duration pollEvery = Duration(seconds: 30);

  final _api = Get.find<VendorApi>();
  final session = Get.find<SessionService>();

  final period = DashboardPeriod.today.obs;
  final summary = Rxn<DashboardSummary>();
  final unread = 0.obs;
  final error = RxnString();

  /// The old numbers stay on screen, dimmed, while a new period loads.
  final refreshing = false.obs;

  /// Only while Home is the open tab and the app is in the foreground (GAP-099).
  /// Coming back from the background reloads through `orderChanges`.
  late final Poller _poll = Poller(pollEvery, load);

  // Only the newest request may fill the screen.
  int _requestId = 0;

  @override
  void onInit() {
    super.onInit();
    load();
    _poll.start();
    keep(ever(session.branchId, (_) => _reload()));
    keep(ever(session.orderChanges, (_) => load()));
    keep(ever(Get.find<MainController>().selectedIndex, (index) {
      if (index == MainController.homeTab) {
        load();
        _poll.start();
      } else {
        _poll.stop();
      }
    }));
  }

  void selectPeriod(DashboardPeriod value) {
    if (period.value == value) return;
    period.value = value;
    _reload();
  }

  Future<void> load() async {
    final id = ++_requestId;
    error.value = null;
    try {
      final result = await _api.dashboard(period: period.value, branchId: session.branchId.value);
      if (id == _requestId) summary.value = result;
      unread.value = await _api.unreadNotifications();
    } catch (e) {
      if (id == _requestId) error.value = e.toString();
    } finally {
      if (id == _requestId) refreshing.value = false;
    }
  }

  void _reload() {
    refreshing.value = true;
    load();
  }

  @override
  void onClose() {
    _poll.dispose();
    super.onClose();
  }
}
