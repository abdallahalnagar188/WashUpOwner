import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../home/presentation/pages/home_page.dart';
import '../../../live/presentation/pages/live_page.dart';
import '../../../more/presentation/pages/more_page.dart';
import '../../../orders/presentation/pages/orders_page.dart';
import '../controllers/main_controller.dart';
import '../widgets/owner_bottom_nav.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MainController>();
    return Scaffold(
      extendBody: true,
      body: Obx(
        () => IndexedStack(
          index: controller.selectedIndex.value,
          children: const [HomePage(), LivePage(), OrdersPage(), MorePage()],
        ),
      ),
      bottomNavigationBar: const OwnerBottomNav(),
    );
  }
}
