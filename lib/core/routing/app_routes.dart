import 'package:get/get.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/main/presentation/pages/main_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';

class Routes {
  static const String splashRoute = '/';
  static const String loginRoute = '/login';
  static const String mainRoute = '/main';
}

final List<GetPage> appPages = [
  GetPage(name: Routes.splashRoute, page: () => const SplashPage()),
  GetPage(name: Routes.loginRoute, page: () => const LoginPage()),
  GetPage(name: Routes.mainRoute, page: () => const MainPage()),
];
