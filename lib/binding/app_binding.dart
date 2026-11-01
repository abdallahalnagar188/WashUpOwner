import 'package:get/get.dart';

import '../core/data/vendor_api.dart';
import '../core/local/lang_controller.dart';
import '../core/network/api_client.dart';
import '../core/network/token_store.dart';
import '../core/services/session_service.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';
import '../features/home/presentation/controllers/home_controller.dart';
import '../features/live/presentation/controllers/live_controller.dart';
import '../features/main/presentation/controllers/main_controller.dart';
import '../features/more/presentation/controllers/more_controller.dart';
import '../features/orders/presentation/controllers/orders_controller.dart';

class AppBinding extends Bindings {
  /// Tests pass a client that talks to a fake server.
  final ApiClient? client;

  AppBinding({this.client});

  @override
  void dependencies() {
    final tokens = TokenStore();
    final api = client ?? ApiClient(tokens: tokens);
    Get.put(VendorApi(api, tokens), permanent: true);
    Get.put(LanguageGetxController(), permanent: true);
    final session = Get.put(SessionService(Get.find<VendorApi>()), permanent: true);

    api.onSessionExpired = () async {
      if (session.account.value == null) return;
      await tokens.clear();
      await session.clearLocal();
      await MoreController.leaveToLogin();
    };

    Get.lazyPut(() => AuthController(), fenix: true);
    Get.lazyPut(() => MainController(), fenix: true);
    Get.lazyPut(() => HomeController(), fenix: true);
    Get.lazyPut(() => LiveController(), fenix: true);
    Get.lazyPut(() => OrdersController(), fenix: true);
    Get.lazyPut(() => MoreController(), fenix: true);
  }
}
