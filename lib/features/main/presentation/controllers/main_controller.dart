import 'package:get/get.dart';

class MainController extends GetxController {
  static const int homeTab = 0;
  static const int liveTab = 1;

  final selectedIndex = homeTab.obs;

  void changeTab(int index) => selectedIndex.value = index;
}
