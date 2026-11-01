import 'dart:async';

import 'package:get/get.dart';

import '../../../../commons/models/live_board.dart';
import '../../../../commons/models/order.dart';
import '../../../../core/data/vendor_api.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/utils/utils.dart';
import '../../../main/presentation/controllers/main_controller.dart';

class LiveController extends GetxController {
  /// Same pace as the dashboard's live page.
  static const Duration pollEvery = Duration(seconds: 15);

  final _api = Get.find<VendorApi>();
  final _session = Get.find<SessionService>();

  final board = Rxn<LiveBoard>();
  final error = RxnString();
  final column = LiveColumn.waiting.obs;
  final busyOrderId = RxnString();

  Timer? _poll;
  bool _columnChosen = false;

  // Only the newest request may fill the screen.
  int _requestId = 0;

  @override
  void onInit() {
    super.onInit();
    final main = Get.find<MainController>();
    _setPolling(main.selectedIndex.value == MainController.liveTab);
    ever(_session.branchId, (_) {
      board.value = null;
      load();
    });
    ever(_session.orderChanges, (_) => load());
    ever(main.selectedIndex, (index) {
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

  void selectColumn(LiveColumn value) {
    _columnChosen = true;
    column.value = value;
  }

  Future<void> load() async {
    final id = ++_requestId;
    error.value = null;
    try {
      final result = await _api.live(branchId: _session.branchId.value);
      if (id != _requestId) return;
      board.value = result;
      _openBusiestColumn(result);
    } catch (e) {
      if (id == _requestId) error.value = e.toString();
    }
  }

  // Opens on where the work is, until the owner picks a column.
  void _openBusiestColumn(LiveBoard result) {
    if (_columnChosen) return;
    const order = [
      LiveColumn.waiting,
      LiveColumn.inService,
      LiveColumn.paymentPending,
      LiveColumn.upcoming,
    ];
    for (final item in order) {
      if (result.ordersIn(item).isNotEmpty) {
        column.value = item;
        return;
      }
    }
  }

  /// The card's button, for owners who skip the details. Steps that need an
  /// answer, like who does the job or how it was paid, open the order.
  bool canRunNext(OrderSummary order) {
    final next = order.nextAction;
    return next != null && !order.locked && _session.can(next.permission);
  }

  Future<void> runNext(OrderSummary order) async {
    final next = order.nextAction;
    if (next == null || busyOrderId.value != null) return;
    const direct = [OrderAction.confirm, OrderAction.checkIn, OrderAction.complete];
    if (!direct.contains(next)) {
      Get.toNamed(Routes.orderRoute, arguments: order.id);
      return;
    }
    busyOrderId.value = order.id;
    try {
      await _api.runAction(order.id, next);
      _session.notifyOrderChanged();
      Utils.getSnakBar(message: 'action.done'.tr, type: TosterTypes.sucsses);
    } catch (e) {
      Utils.getSnakBar(message: e.toString(), type: TosterTypes.failed);
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
