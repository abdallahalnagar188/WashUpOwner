import 'dart:async';

import 'package:get/get.dart';

import '../../../../commons/models/live_board.dart';
import '../../../../core/data/vendor_api.dart';
import '../../../../core/services/session_service.dart';
import '../../../main/presentation/controllers/main_controller.dart';

class LiveController extends GetxController {
  /// Same pace as the dashboard's live page.
  static const Duration pollEvery = Duration(seconds: 15);

  final _api = Get.find<VendorApi>();
  final _session = Get.find<SessionService>();

  final board = Rxn<LiveBoard>();
  final error = RxnString();
  final column = LiveColumn.waiting.obs;

  Timer? _poll;

  // Only the newest request may fill the screen.
  int _requestId = 0;

  @override
  void onInit() {
    super.onInit();
    load();
    ever(_session.branchId, (_) {
      board.value = null;
      load();
    });
    ever(_session.orderChanges, (_) => load());
    ever(Get.find<MainController>().selectedIndex, (index) {
      _setPolling(index == MainController.liveTab);
    });
  }

  void _setPolling(bool on) {
    _poll?.cancel();
    _poll = null;
    if (!on) return;
    load();
    _poll = Timer.periodic(pollEvery, (_) => load());
  }

  Future<void> load() async {
    final id = ++_requestId;
    error.value = null;
    try {
      final result = await _api.live(branchId: _session.branchId.value);
      if (id == _requestId) board.value = result;
    } catch (e) {
      if (id == _requestId) error.value = e.toString();
    }
  }

  @override
  void onClose() {
    _poll?.cancel();
    super.onClose();
  }
}
