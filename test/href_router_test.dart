import 'package:flutter_test/flutter_test.dart';
import 'package:washup_owner/commons/models/dashboard_summary.dart';
import 'package:washup_owner/commons/models/owner_account.dart';
import 'package:washup_owner/core/routing/app_routes.dart';
import 'package:washup_owner/core/routing/href_router.dart';

void main() {
  group('portal links (GAP-084, GAP-051)', () {
    test('an order and a customer open their details', () {
      final order = HrefRouter.parse('/orders/ord_1')!;
      expect(order.kind, HrefKind.order);
      expect(order.id, 'ord_1');
      expect(HrefRouter.parse('/customers/cus_1')!.kind, HrefKind.customer);
    });

    test('lists keep their tab, and an unknown tab falls back to the first', () {
      final waiting = HrefRouter.parse('/orders?tab=waiting')!;
      expect([waiting.kind, waiting.view, waiting.tab], [HrefKind.ordersList, 'orders', 'waiting']);
      final cancelled = HrefRouter.parse('/bookings?tab=cancelled')!;
      expect([cancelled.view, cancelled.tab], ['bookings', 'cancelled']);
      expect(HrefRouter.parse('/orders?tab=nope')!.tab, 'active');
      expect(HrefRouter.parse('/bookings')!.tab, 'today');
    });

    test('management pages, with the same permissions as the More menu', () {
      final reviews = HrefRouter.parse('/reviews?replied=no')!;
      expect([reviews.kind, reviews.route], [HrefKind.page, Routes.reviewsRoute]);
      expect(HrefRouter.parse('/shifts?filter=difference')!.permission, OwnerPermission.closeShift);
      expect(HrefRouter.parse('/staff')!.permission, OwnerPermission.manageStaff);
      expect(HrefRouter.parse('/settings')!.permission, isNull);
    });

    test('nothing for links the app has no screen for', () {
      expect(HrefRouter.parse(null), isNull);
      expect(HrefRouter.parse(''), isNull);
      expect(HrefRouter.parse('https://example.com/orders/1'), isNull);
      expect(HrefRouter.parse('/unknown'), isNull);
      expect(HrefRouter.parse('/orders/ord_1/edit'), isNull);
    });
  });

  group('dashboard alerts (GAP-079)', () {
    test('reads description, severity and href as the server sends them', () {
      final alert = DashboardAlert.fromJson({
        'id': 'cash',
        'type': 'cash_difference',
        'severity': 'danger',
        'title': 'فرق نقدية',
        'description': 'وردية أحمد — الفرع الرئيسي',
        'href': '/shifts?filter=difference',
      });
      expect(alert.body!.ar, 'وردية أحمد — الفرع الرئيسي');
      expect(alert.severity, AlertSeverity.danger);
      expect(alert.href, '/shifts?filter=difference');
    });

    test('older replies with body and no severity still read', () {
      final alert = DashboardAlert.fromJson({'id': 'x', 'title': 'T', 'body': 'B'});
      expect(alert.body!.ar, 'B');
      expect(alert.severity, AlertSeverity.warning);
      expect(alert.href, isNull);
      expect(DashboardAlert.fromJson({'id': 'y', 'title': 'T', 'description': ''}).body, isNull);
    });
  });
}
