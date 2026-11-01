import 'package:get/get.dart';

import '../../features/manage/audit/controllers/audit_controller.dart';
import '../../features/manage/audit/pages/audit_page.dart';
import '../../features/manage/branches/controllers/branches_controller.dart';
import '../../features/manage/branches/pages/branches_page.dart';
import '../../features/manage/customers/controllers/customers_controller.dart';
import '../../features/manage/customers/pages/customer_details_page.dart';
import '../../features/manage/customers/pages/customers_page.dart';
import '../../features/manage/finance/controllers/finance_controller.dart';
import '../../features/manage/finance/pages/finance_page.dart';
import '../../features/manage/notifications/controllers/notifications_controller.dart';
import '../../features/manage/notifications/pages/notifications_page.dart';
import '../../features/manage/offers/controllers/offers_controller.dart';
import '../../features/manage/offers/pages/offers_page.dart';
import '../../features/manage/reports/controllers/reports_controller.dart';
import '../../features/manage/reports/pages/reports_page.dart';
import '../../features/manage/reviews/controllers/reviews_controller.dart';
import '../../features/manage/reviews/pages/reviews_page.dart';
import '../../features/manage/schedule/controllers/schedule_controller.dart';
import '../../features/manage/schedule/pages/schedule_page.dart';
import '../../features/manage/services/controllers/services_controller.dart';
import '../../features/manage/services/pages/services_page.dart';
import '../../features/manage/settings/controllers/settings_controller.dart';
import '../../features/manage/settings/pages/settings_page.dart';
import '../../features/manage/shifts/controllers/day_closing_controller.dart';
import '../../features/manage/shifts/controllers/shift_details_controller.dart';
import '../../features/manage/shifts/controllers/shifts_controller.dart';
import '../../features/manage/shifts/pages/day_closing_page.dart';
import '../../features/manage/shifts/pages/shift_details_page.dart';
import '../../features/manage/shifts/pages/shifts_page.dart';
import '../../features/manage/staff/controllers/staff_controller.dart';
import '../../features/manage/staff/pages/staff_page.dart';
import 'app_routes.dart';

/// Routes reached from inside a management screen.
class ManageRoutes {
  static const String shiftRoute = '/shift';
  static const String dayClosingRoute = '/day_closing';
  static const String customerRoute = '/customer';
}

/// Pages opened from the More tab.
final List<GetPage> managePages = [
  GetPage(
    name: Routes.notificationsRoute,
    page: () => const NotificationsPage(),
    binding: BindingsBuilder(() {
      Get.put(NotificationsController());
    }),
  ),
  GetPage(
    name: Routes.scheduleRoute,
    page: () => const SchedulePage(),
    binding: BindingsBuilder(() {
      Get.put(ScheduleController());
    }),
  ),
  GetPage(
    name: Routes.servicesRoute,
    page: () => const ServicesPage(),
    binding: BindingsBuilder(() {
      Get.put(ServicesController());
    }),
  ),
  GetPage(
    name: Routes.offersRoute,
    page: () => const OffersPage(),
    binding: BindingsBuilder(() {
      Get.put(OffersController());
    }),
  ),
  GetPage(
    name: Routes.staffRoute,
    page: () => const StaffPage(),
    binding: BindingsBuilder(() {
      Get.put(StaffController());
    }),
  ),
  GetPage(
    name: Routes.shiftsRoute,
    page: () => const ShiftsPage(),
    binding: BindingsBuilder(() {
      Get.put(ShiftsController());
    }),
  ),
  GetPage(
    name: ManageRoutes.shiftRoute,
    page: () => const ShiftDetailsPage(),
    binding: BindingsBuilder(() {
      Get.put(ShiftDetailsController(Get.arguments as String));
    }),
  ),
  GetPage(
    name: ManageRoutes.dayClosingRoute,
    page: () => const DayClosingPage(),
    binding: BindingsBuilder(() {
      Get.put(DayClosingController());
    }),
  ),
  GetPage(
    name: Routes.customersRoute,
    page: () => const CustomersPage(),
    binding: BindingsBuilder(() {
      Get.put(CustomersController());
    }),
  ),
  GetPage(
    name: ManageRoutes.customerRoute,
    page: () => const CustomerDetailsPage(),
    binding: BindingsBuilder(() {
      Get.put(CustomerDetailsController(Get.arguments as String));
    }),
  ),
  GetPage(
    name: Routes.reviewsRoute,
    page: () => const ReviewsPage(),
    binding: BindingsBuilder(() {
      Get.put(ReviewsController());
    }),
  ),
  GetPage(
    name: Routes.reportsRoute,
    page: () => const ReportsPage(),
    binding: BindingsBuilder(() {
      Get.put(ReportsController());
    }),
  ),
  GetPage(
    name: Routes.financeRoute,
    page: () => const FinancePage(),
    binding: BindingsBuilder(() {
      Get.put(FinanceController());
    }),
  ),
  GetPage(
    name: Routes.branchesRoute,
    page: () => const BranchesPage(),
    binding: BindingsBuilder(() {
      Get.put(BranchesController());
    }),
  ),
  GetPage(
    name: Routes.auditRoute,
    page: () => const AuditPage(),
    binding: BindingsBuilder(() {
      Get.put(AuditController());
    }),
  ),
  GetPage(
    name: Routes.settingsRoute,
    page: () => const SettingsPage(),
    binding: BindingsBuilder(() {
      Get.put(SettingsController());
    }),
  ),
];
