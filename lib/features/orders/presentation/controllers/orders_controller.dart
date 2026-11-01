import 'package:get/get.dart';

import '../../../../commons/models/order.dart';
import '../../../../core/data/vendor_api.dart';
import '../../../../core/services/session_service.dart';
import '../../../main/presentation/controllers/main_controller.dart';

class OrdersController extends GetxController {
  static const Map<String, List<String>> tabs = {
    'orders': ['active', 'waiting', 'in_service', 'payment_pending', 'paid'],
    'bookings': ['today', 'upcoming', 'completed', 'cancelled', 'no_show'],
  };

  final _api = Get.find<VendorApi>();
  final _session = Get.find<SessionService>();

  final view = 'orders'.obs;
  final tab = 'active'.obs;
  final orders = <OrderSummary>[].obs;
  final counts = <String, int>{}.obs;
  final loading = true.obs;
  final loadingMore = false.obs;
  final error = RxnString();

  int _page = 1;
  bool _hasNext = false;
  int _requestId = 0;

  @override
  void onInit() {
    super.onInit();
    load();
    ever(_session.branchId, (_) => load());
    ever(_session.orderChanges, (_) => load(silent: true));
    ever(Get.find<MainController>().selectedIndex, (index) {
      if (index == MainController.ordersTab) load(silent: true);
    });
  }

  void selectView(String value) {
    if (view.value == value) return;
    view.value = value;
    tab.value = tabs[value]!.first;
    load();
  }

  void selectTab(String value) {
    if (tab.value == value) return;
    tab.value = value;
    load();
  }

  Future<void> load({bool silent = false}) async {
    final id = ++_requestId;
    error.value = null;
    if (!silent) {
      loading.value = true;
      orders.clear();
    }
    try {
      final page = await _api.orders(
        view: view.value,
        tab: tab.value,
        branchId: _session.branchId.value,
      );
      if (id != _requestId) return;
      _page = 1;
      _hasNext = page.hasNext;
      orders.assignAll(page.items);
      counts.assignAll({
        for (final entry in (page.meta['counts'] as Map? ?? const {}).entries)
          entry.key.toString(): (entry.value as num).toInt(),
      });
    } catch (e) {
      if (id == _requestId) error.value = e.toString();
    } finally {
      if (id == _requestId) loading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (!_hasNext || loadingMore.value) return;
    final id = _requestId;
    loadingMore.value = true;
    try {
      final page = await _api.orders(
        view: view.value,
        tab: tab.value,
        branchId: _session.branchId.value,
        page: _page + 1,
      );
      if (id != _requestId) return;
      _page++;
      _hasNext = page.hasNext;
      orders.addAll(page.items);
    } catch (_) {
      // The list stays as it is; scrolling again retries.
    } finally {
      loadingMore.value = false;
    }
  }
}
