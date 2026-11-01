import 'package:get/get.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/utils/utils.dart';
import '../../../home/presentation/controllers/home_controller.dart';
import '../../../live/presentation/controllers/live_controller.dart';
import '../../../main/presentation/controllers/main_controller.dart';

class MoreController extends GetxController {
  Future<void> logout() async {
    final ok = await Utils.confirm(
      title: 'more.logoutTitle'.tr,
      okText: 'more.logout'.tr,
      danger: true,
    );
    if (!ok) return;
    await Get.find<SessionService>().signOut();
    await Get.offAllNamed(Routes.loginRoute);
    // The next account must not see this one's screens.
    Get.delete<HomeController>(force: true);
    Get.delete<LiveController>(force: true);
    Get.delete<MainController>(force: true);
  }
}
