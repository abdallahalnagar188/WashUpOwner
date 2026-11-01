import 'dart:async';

import 'package:get/get.dart';

import '../../../../commons/models/live_board.dart';
import '../../../../core/data/owner_repo.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/utils/utils.dart';
import '../../../main/presentation/controllers/main_controller.dart';

class LiveController extends GetxController {
  static const Duration pollEvery = Duration(seconds: 20);

  final _repo = Get.find<OwnerRepo>();
  final _session = Get.find<SessionService>();

  final board = Rxn<LiveBoard>();
  final failed = false.obs;
  final column = LiveColumn.waiting.obs;
  final busyOrderId = RxnString();

  Timer? _poll;

  // Only the newest request may fill the screen, so a poll that was already on
  // its way cannot undo the result of an action.
  int _requestId = 0;

  @override
  void onInit() {
    super.onInit();
    load();
    ever(_session.branchId, (_) {
      board.value = null;
      load();
    });
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
    failed.value = false;
    try {
      final result = await _repo.live(branchId: _session.branchId.value);
      if (id == _requestId) board.value = result;
    } catch (_) {
      if (id == _requestId) failed.value = true;
    }
  }

  bool canRun(LiveAction action) => _session.can(action.permission);

  Future<void> run(LiveOrder order) async {
    final action = order.nextAction;
    if (action == null || busyOrderId.value != null) return;
    if (!canRun(action)) {
      Utils.getSnakBar(message: 'live.noPermission'.tr, type: TosterTypes.warning);
      return;
    }
    final id = ++_requestId;
    busyOrderId.value = order.id;
    try {
      final result = await _repo.runAction(
        orderId: order.id,
        action: action,
        branchId: _session.branchId.value,
      );
      if (id == _requestId) board.value = result;
      Utils.getSnakBar(
        message: (action == LiveAction.collect ? 'live.collected' : 'live.done').tr,
        type: TosterTypes.sucsses,
      );
    } on OwnerRepoException catch (e) {
      Utils.getSnakBar(message: e.messageKey.tr, type: TosterTypes.failed);
      await load();
    } catch (_) {
      Utils.getSnakBar(message: 'live.actionFailed'.tr, type: TosterTypes.failed);
      await load();
    } finally {
      busyOrderId.value = null;
    }
  }

  @override
  void onClose() {
    _poll?.cancel();
    super.onClose();
  }
}
