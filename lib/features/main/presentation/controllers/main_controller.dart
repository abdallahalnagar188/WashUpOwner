import 'package:get/get.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/notification_service.dart';

class MainController extends GetxController {
  static const int homeTab = 0;
  static const int liveTab = 1;
  static const int ordersTab = 2;

  final selectedIndex = homeTab.obs;

  @override
  void onReady() {
    super.onReady();
    // Covers both a fresh sign-in and a session restored at launch.
    if (Get.isRegistered<NotificationService>()) {
      Get.find<NotificationService>().registerDevice();
    }
  }

  void changeTab(int index) => selectedIndex.value = index;

  void openNewOrder() => Get.toNamed(Routes.newOrderRoute);
}
