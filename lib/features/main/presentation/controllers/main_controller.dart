import 'package:get/get.dart';

import '../../../../core/routing/app_routes.dart';

class MainController extends GetxController {
  static const int homeTab = 0;
  static const int liveTab = 1;
  static const int ordersTab = 2;

  final selectedIndex = homeTab.obs;

  void changeTab(int index) => selectedIndex.value = index;

  void openNewOrder() => Get.toNamed(Routes.newOrderRoute);
}
