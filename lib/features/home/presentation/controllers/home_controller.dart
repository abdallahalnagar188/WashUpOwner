import 'dart:async';

import 'package:get/get.dart';

import '../../../../commons/models/dashboard_summary.dart';
import '../../../../core/data/vendor_api.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/services/session_service.dart';
import '../../../main/presentation/controllers/main_controller.dart';

class HomeController extends GetxController {
  static const Duration pollEvery = Duration(seconds: 30);

  final _api = Get.find<VendorApi>();
  final session = Get.find<SessionService>();

  final period = DashboardPeriod.today.obs;
  final summary = Rxn<DashboardSummary>();
  final unread = 0.obs;
  final error = RxnString();

  /// The old numbers stay on screen, dimmed, while a new period loads.
  final refreshing = false.obs;

  Timer? _poll;

  // Only the newest request may fill the screen.
  int _requestId = 0;

  @override
  void onInit() {
    super.onInit();
    load();
    _startPolling();
    ever(session.branchId, (_) => _reload());
    ever(session.orderChanges, (_) => load());
    ever(Get.find<MainController>().selectedIndex, (index) {
      _poll?.cancel();
      if (index == MainController.homeTab) {
        load();
        _startPolling();
      }
    });
  }

  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(pollEvery, (_) => load());
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
    _poll?.cancel();
    super.onClose();
  }
}
