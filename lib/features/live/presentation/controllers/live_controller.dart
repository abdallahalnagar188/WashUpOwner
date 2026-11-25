import 'package:get/get.dart';

import '../../../../commons/models/live_board.dart';
import '../../../../commons/models/order.dart';
import '../../../../commons/models/owner_account.dart';
import '../../../../core/data/vendor_api.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/utils/poller.dart';
import '../../../../core/utils/utils.dart';
import '../../../../core/utils/workers.dart';
import '../../../main/presentation/controllers/main_controller.dart';

class LiveController extends GetxController with DisposesWorkers {
  /// The partner-app pace in VENDOR_API.md (30 s, foreground only); push covers
  /// the rest (GAP-099).
  static const Duration pollEvery = Duration(seconds: 30);

  final _api = Get.find<VendorApi>();
  final _session = Get.find<SessionService>();

  final board = Rxn<LiveBoard>();
  final error = RxnString();
  final column = LiveColumn.waiting.obs;
  final busyOrderId = RxnString();

  late final Poller _poll = Poller(pollEvery, load);
  bool _columnChosen = false;

  // Only the newest request may fill the screen.
  int _requestId = 0;

  @override
  void onInit() {
    super.onInit();
    final main = Get.find<MainController>();
    _setPolling(main.selectedIndex.value == MainController.liveTab);
    keep(ever(_session.branchId, (_) {
      board.value = null;
      load();
    }));
    keep(ever(_session.orderChanges, (_) => load()));
    keep(ever(main.selectedIndex, (index) {
      _setPolling(index == MainController.liveTab);
    }));
  }

  void _setPolling(bool on) {
    if (!on) {
      _poll.stop();
      return;
    }
    load();
    _poll.start();
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
  bool canRunNext(OrderSummary order) => nextStepAllowed(
        order,
        can: _session.can,
        suspended: _session.suspended,
      );

  /// The server's `allowedActions` decide when the row carries them (GAP-074).
  /// Rows from today's server only carry `nextAction`, which ignores suspended
  /// mode, so the app applies that rule itself: a suspended wash takes no new
  /// car (confirm / check-in answer 423).
  static bool nextStepAllowed(
    OrderSummary order, {
    required bool Function(OwnerPermission?) can,
    required bool suspended,
  }) {
    final next = order.nextAction;
    if (next == null || order.locked || !can(next.permission)) return false;
    final allowed = order.allowedActions;
    if (allowed != null) return allowed.contains(next);
    return !(suspended && (next == OrderAction.confirm || next == OrderAction.checkIn));
  }

  Future<void> runNext(OrderSummary order) async {
    final next = order.nextAction;
    if (next == null || busyOrderId.value != null) return;
    // Check-in needs the customer's code, so it opens the order like the steps that ask something.
    const direct = [OrderAction.confirm, OrderAction.complete];
    if (!direct.contains(next)) {
      Get.toNamed(Routes.orderRoute, arguments: order.id);
      return;
    }
    busyOrderId.value = order.id;
    try {
      final outcome = await _api.runAction(order.id, next);
      _session.notifyOrderChanged();
      Utils.getSnakBar(message: outcome ?? 'action.done'.tr, type: TosterTypes.sucsses);
    } catch (e) {
      Utils.getSnakBar(message: e.toString(), type: TosterTypes.failed);
    } finally {
      busyOrderId.value = null;
    }
  }

  @override
  void onClose() {
    _poll.dispose();
    super.onClose();
  }
}
