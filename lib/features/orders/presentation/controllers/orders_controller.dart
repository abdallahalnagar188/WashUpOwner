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

  // Last list of each tab, so going back to a tab is instant while it refreshes.
  final Map<String, List<OrderSummary>> _cache = {};

  int _page = 1;
  bool _hasNext = false;
  int _requestId = 0;

  String get _cacheKey => '${_session.branchId.value}/${view.value}/${tab.value}';

  /// Changes when the list on screen changes, for its transition.
  String get listKey => '${view.value}/${tab.value}';

  @override
  void onInit() {
    super.onInit();
    load();
    ever(_session.branchId, (_) {
      _cache.clear();
      load();
    });
    ever(_session.orderChanges, (_) {
      _cache.clear();
      load(silent: true);
    });
    ever(Get.find<MainController>().selectedIndex, (index) {
      if (index == MainController.ordersTab) load(silent: true);
    });
  }

  void selectView(String value) {
    if (view.value == value) return;
    view.value = value;
    tab.value = tabs[value]!.first;
    _showTab();
  }

  void selectTab(String value) {
    if (tab.value == value) return;
    tab.value = value;
    _showTab();
  }

  /// Jumps to a tab from elsewhere, like a number on Home.
  void open({required String view, required String tab}) {
    this.view.value = view;
    this.tab.value = tab;
    _showTab();
  }

  void _showTab() {
    final cached = _cache[_cacheKey];
    if (cached == null) {
      load();
    } else {
      orders.assignAll(cached);
      load(silent: true);
    }
  }

  Future<void> load({bool silent = false}) async {
    final id = ++_requestId;
    final key = _cacheKey;
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
      _cache[key] = page.items;
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
