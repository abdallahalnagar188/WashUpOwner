import 'package:get/get.dart';

import '../core/data/mock_owner_repo.dart';
import '../core/data/owner_repo.dart';
import '../core/local/lang_controller.dart';
import '../core/services/session_service.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';
import '../features/home/presentation/controllers/home_controller.dart';
import '../features/live/presentation/controllers/live_controller.dart';
import '../features/main/presentation/controllers/main_controller.dart';
import '../features/more/presentation/controllers/more_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<OwnerRepo>(MockOwnerRepo(), permanent: true);
    Get.put(LanguageGetxController(), permanent: true);
    Get.put(SessionService(Get.find<OwnerRepo>()), permanent: true);

    Get.lazyPut(() => AuthController(), fenix: true);
    Get.lazyPut(() => MainController(), fenix: true);
    Get.lazyPut(() => HomeController(), fenix: true);
    Get.lazyPut(() => LiveController(), fenix: true);
    Get.lazyPut(() => MoreController(), fenix: true);
  }
}
