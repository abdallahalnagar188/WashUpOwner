import 'package:get/get.dart';

import '../../../../commons/models/order.dart';
import '../../../../core/data/vendor_api.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/utils/poller.dart';
import '../../../../core/utils/utils.dart';

class OrderDetailsController extends GetxController {
  /// 30 s like the partner-app contract, and only in the foreground (GAP-099).
  static const Duration pollEvery = Duration(seconds: 30);

  final String orderId;

  OrderDetailsController(this.orderId);

  final _api = Get.find<VendorApi>();
  final _session = Get.find<SessionService>();

  final order = Rxn<OrderDetails>();
  final error = RxnString();
  final busy = false.obs;

  /// Coming back from the background reloads at once: nothing else refreshes this page.
  late final Poller _poll = Poller(pollEvery, load, tickOnResume: true);
  int _requestId = 0;

  /// What the server allows, minus what this account may not do. The server
  /// list already applies the state machine, the no-show grace (only before
  /// check-in) and suspended mode, so the app adds no rules of its own (GAP-074).
  List<OrderAction> get actions {
    final current = order.value;
    if (current == null) return const [];
    return current.allowedActions.where((a) => _session.can(a.permission)).toList();
  }

  /// A confirmed booking whose no-show opens later: shown greyed with its
  /// time. The server leaves `no_show` out of the list until the grace is over.
  bool get noShowLater {
    final current = order.value;
    return current != null &&
        current.status == OrderStatus.confirmed &&
        !current.locked &&
        !current.allowedActions.contains(OrderAction.noShow) &&
        current.allowedActions.any((a) => a != OrderAction.note) &&
        !current.noShowOpen;
  }

  /// Owners and branch managers may check in a customer who has no phone.
  bool get canWaiveCheckIn {
    final role = _session.account.value?.role;
    return role == 'owner' || role == 'manager';
  }

  OrderAction? get primaryAction {
    final next = order.value?.nextAction;
    return next != null && actions.contains(next) ? next : null;
  }

  List<OrderAction> get otherActions =>
      actions.where((action) => action != primaryAction).toList();

  @override
  void onInit() {
    super.onInit();
    load();
    _poll.start();
  }

  Future<void> load() async {
    final id = ++_requestId;
    error.value = null;
    try {
      final result = await _api.order(orderId);
      if (id == _requestId) order.value = result;
    } catch (e) {
      if (id == _requestId) error.value = e.toString();
    }
  }

  /// Runs an action and reports the outcome. True means it went through.
  Future<bool> run(OrderAction action, [Map<String, dynamic> fields = const {}]) async {
    if (busy.value) return false;
    busy.value = true;
    try {
      final outcome = await _api.runAction(orderId, action, fields);
      await load();
      _session.notifyOrderChanged();
      // The server's text carries what staff must act on, like the change due (GAP-081).
      Utils.getSnakBar(message: outcome ?? 'action.done'.tr, type: TosterTypes.sucsses);
      return true;
    } catch (e) {
      Utils.getSnakBar(message: e.toString(), type: TosterTypes.failed);
      await load();
      return false;
    } finally {
      busy.value = false;
    }
  }

  @override
  void onClose() {
    _poll.dispose();
    super.onClose();
  }
}
