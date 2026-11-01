import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/session_service.dart';
import '../../../orders/presentation/controllers/orders_controller.dart';

class MainController extends GetxController with WidgetsBindingObserver {
  static const int homeTab = 0;
  static const int liveTab = 1;
  static const int ordersTab = 2;

  final selectedIndex = homeTab.obs;

  /// A tab is built the first time it opens, so start-up only loads Home.
  final openedTabs = <int>{homeTab}.obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onReady() {
    super.onReady();
    // Covers both a fresh sign-in and a session restored at launch.
    if (Get.isRegistered<NotificationService>()) {
      Get.find<NotificationService>().registerDevice();
    }
  }

  /// Numbers may be old after the app sat in the background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) Get.find<SessionService>().notifyOrderChanged();
  }

  void changeTab(int index) {
    openedTabs.add(index);
    selectedIndex.value = index;
  }

  void openOrders({required String view, required String tab}) {
    Get.find<OrdersController>().open(view: view, tab: tab);
    changeTab(ordersTab);
  }

  void openNewOrder() => Get.toNamed(Routes.newOrderRoute);

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }
}
