import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../commons/models/owner_account.dart';
import '../../features/main/presentation/controllers/main_controller.dart';
import '../../features/orders/presentation/controllers/orders_controller.dart';
import '../services/session_service.dart';
import 'app_routes.dart';
import 'manage_pages.dart';

enum HrefKind { order, customer, ordersList, live, page }

/// Where a dashboard link (`href` on notifications, alerts and pushes) leads in the app.
class HrefTarget {
  final HrefKind kind;

  /// The order or customer id.
  final String? id;

  /// The page route of [HrefKind.page].
  final String? route;

  /// The orders list view and tab of [HrefKind.ordersList].
  final String? view;
  final String? tab;

  /// What the account needs to open the page.
  final OwnerPermission? permission;

  const HrefTarget(this.kind, {this.id, this.route, this.view, this.tab, this.permission});
}

/// Opens the portal's links inside the app (GAP-084, GAP-079, GAP-051): orders,
/// customers, order lists with their tab, the live board and management pages.
class HrefRouter {
  HrefRouter._();

  static const Map<String, String> _pages = {
    'notifications': Routes.notificationsRoute,
    'schedule': Routes.scheduleRoute,
    'services': Routes.servicesRoute,
    'offers': Routes.offersRoute,
    'staff': Routes.staffRoute,
    'shifts': Routes.shiftsRoute,
    'customers': Routes.customersRoute,
    'reviews': Routes.reviewsRoute,
    'reports': Routes.reportsRoute,
    'finance': Routes.financeRoute,
    'branches': Routes.branchesRoute,
    'audit': Routes.auditRoute,
    'settings': Routes.settingsRoute,
  };

  /// Same rules as the More menu.
  static const Map<String, OwnerPermission> _permissions = {
    'staff': OwnerPermission.manageStaff,
    'shifts': OwnerPermission.closeShift,
  };

  /// Null when the app has no screen for [href].
  static HrefTarget? parse(String? href) {
    final text = href?.trim() ?? '';
    if (!text.startsWith('/')) return null;
    final uri = Uri.tryParse(text);
    if (uri == null) return null;
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return null;
    final first = segments.first;

    if (segments.length == 2 && first == 'orders') return HrefTarget(HrefKind.order, id: segments[1]);
    if (segments.length == 2 && first == 'customers') return HrefTarget(HrefKind.customer, id: segments[1]);
    if (segments.length != 1) return null;

    if (first == 'orders' || first == 'bookings') {
      final tabs = OrdersController.tabs[first]!;
      final tab = uri.queryParameters['tab'];
      return HrefTarget(HrefKind.ordersList, view: first, tab: tabs.contains(tab) ? tab : tabs.first);
    }
    if (first == 'live') return const HrefTarget(HrefKind.live);
    final route = _pages[first];
    if (route == null) return null;
    return HrefTarget(HrefKind.page, route: route, permission: _permissions[first]);
  }

  /// Opens [href] for the signed-in account. False when there is no screen for
  /// it, nobody is signed in, or the account may not open it.
  static bool open(String? href) {
    final target = parse(href);
    if (target == null || !Get.isRegistered<SessionService>()) return false;
    final session = Get.find<SessionService>();
    if (session.account.value == null) return false;
    switch (target.kind) {
      case HrefKind.order:
        Get.toNamed(Routes.orderRoute, arguments: target.id);
        return true;
      case HrefKind.customer:
        Get.toNamed(ManageRoutes.customerRoute, arguments: target.id);
        return true;
      case HrefKind.page:
        if (!session.can(target.permission)) return false;
        Get.toNamed(target.route!);
        return true;
      case HrefKind.ordersList:
      case HrefKind.live:
        if (!Get.isRegistered<MainController>()) return false;
        // The lists are tabs of the main page: go back to it first.
        Get.until((Route<dynamic> route) => route.settings.name == Routes.mainRoute || route.isFirst);
        final main = Get.find<MainController>();
        if (target.kind == HrefKind.live) {
          main.changeTab(MainController.liveTab);
        } else {
          main.openOrders(view: target.view!, tab: target.tab!);
        }
        return true;
    }
  }
}
