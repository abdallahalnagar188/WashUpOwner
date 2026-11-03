import 'dart:async';

import 'package:get/get.dart';

import '../../../../commons/models/order.dart';
import '../../../../core/data/vendor_api.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/utils/utils.dart';

class OrderDetailsController extends GetxController {
  static const Duration pollEvery = Duration(seconds: 15);

  final String orderId;

  OrderDetailsController(this.orderId);

  final _api = Get.find<VendorApi>();
  final _session = Get.find<SessionService>();

  final order = Rxn<OrderDetails>();
  final error = RxnString();
  final busy = false.obs;

  Timer? _poll;
  int _requestId = 0;

  /// What the server allows, minus what this account may not do.
  List<OrderAction> get actions {
    final current = order.value;
    if (current == null) return const [];
    return current.allowedActions
        .where((a) => _session.can(a.permission))
        // The server refuses a no-show before the customer is late enough.
        .where((a) => a != OrderAction.noShow || current.noShowOpen)
        .toList();
  }

  /// "No-show" exists but opens later: shown greyed with its time.
  bool get noShowLater {
    final current = order.value;
    return current != null &&
        current.allowedActions.contains(OrderAction.noShow) &&
        _session.can(OrderAction.noShow.permission) &&
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
    _poll = Timer.periodic(pollEvery, (_) => load());
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
      await _api.runAction(orderId, action, fields);
      await load();
      _session.notifyOrderChanged();
      Utils.getSnakBar(message: 'action.done'.tr, type: TosterTypes.sucsses);
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
    _poll?.cancel();
    super.onClose();
  }
}
