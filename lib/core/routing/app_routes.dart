import 'package:get/get.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/main/presentation/pages/main_page.dart';
import '../../features/orders/presentation/controllers/new_order_controller.dart';
import '../../features/orders/presentation/controllers/order_details_controller.dart';
import '../../features/orders/presentation/pages/new_order_page.dart';
import '../../features/orders/presentation/pages/order_details_page.dart';
import '../../features/search/presentation/controllers/search_controller.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import 'manage_pages.dart';

class Routes {
  static const String splashRoute = '/';
  static const String loginRoute = '/login';
  static const String mainRoute = '/main';
  static const String orderRoute = '/order';
  static const String newOrderRoute = '/new_order';
  static const String searchRoute = '/search';
  static const String notificationsRoute = '/notifications';
  static const String scheduleRoute = '/schedule';
  static const String servicesRoute = '/services';
  static const String offersRoute = '/offers';
  static const String staffRoute = '/staff';
  static const String shiftsRoute = '/shifts';
  static const String customersRoute = '/customers';
  static const String reviewsRoute = '/reviews';
  static const String reportsRoute = '/reports';
  static const String financeRoute = '/finance';
  static const String branchesRoute = '/branches';
  static const String auditRoute = '/audit';
  static const String settingsRoute = '/settings';
}

final List<GetPage> appPages = [
  GetPage(name: Routes.splashRoute, page: () => const SplashPage()),
  GetPage(name: Routes.loginRoute, page: () => const LoginPage()),
  GetPage(name: Routes.mainRoute, page: () => const MainPage()),
  GetPage(
    name: Routes.orderRoute,
    page: () => const OrderDetailsPage(),
    binding: BindingsBuilder(() {
      Get.put(OrderDetailsController(Get.arguments as String));
    }),
  ),
  GetPage(
    name: Routes.newOrderRoute,
    page: () => const NewOrderPage(),
    binding: BindingsBuilder(() {
      Get.put(NewOrderController());
    }),
  ),
  GetPage(
    name: Routes.searchRoute,
    page: () => const SearchPage(),
    binding: BindingsBuilder(() {
      Get.put(OwnerSearchController());
    }),
  ),
  ...managePages,
];
