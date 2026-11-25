import 'package:flutter_test/flutter_test.dart';
import 'package:washup_owner/commons/models/order.dart';
import 'package:washup_owner/commons/models/owner_account.dart';
import 'package:washup_owner/core/data/vendor_api.dart';
import 'package:washup_owner/core/enums/enums.dart';
import 'package:washup_owner/core/network/api_client.dart';
import 'package:washup_owner/features/live/presentation/controllers/live_controller.dart';

import 'helpers/fake_server.dart';

OrderSummary row({String next = 'confirm', List<String>? allowed, bool locked = false}) => OrderSummary.fromJson({
      'id': 'ord_1',
      'scheduledAt': '2026-11-01T10:00:00.000Z',
      'status': 'pending',
      'nextAction': next,
      if (allowed != null) 'allowedActions': allowed,
      'locked': locked,
    });

bool everything(OwnerPermission? _) => true;

void main() {
  group('server outcome text (GAP-081)', () {
    test('a plain "OK" says nothing', () {
      expect(ApiClient.outcome({'message': 'OK'}), isNull);
      expect(ApiClient.outcome({'message': ''}), isNull);
      expect(ApiClient.outcome({}), isNull);
      expect(ApiClient.outcome({'message': ' تم التحصيل — الباقي للعميل 20 ج.م '}), 'تم التحصيل — الباقي للعميل 20 ج.م');
    });

    test('an order action returns what the server said', () async {
      final server = FakeServer((_) => const FakeReply(200, {
            'status': true,
            'message': 'تم التحصيل — الباقي للعميل 20 ج.م',
            'data': {'id': 'ord_1'},
          }));
      final api = VendorApi(fakeClient(server, MemoryTokens()), MemoryTokens());

      final outcome = await api.runAction('ord_1', OrderAction.collectPayment, {'method': 'cash', 'amountReceived': 200});

      expect(outcome, 'تم التحصيل — الباقي للعميل 20 ج.م');
    });

    test('a new order returns its id and the expected wait', () async {
      final server = FakeServer((_) => const FakeReply(200, {
            'status': true,
            'message': 'تم إنشاء الطلب CZ-20001 — كل الأماكن مشغولة، الانتظار المتوقع ~20 دقيقة',
            'data': {'id': 'ord_9', 'number': 'CZ-20001'},
          }));
      final api = VendorApi(fakeClient(server, MemoryTokens()), MemoryTokens());

      final created = await api.createOrder(
        branchId: 'br_1',
        source: OrderSource.walkIn,
        plate: 'ABC 123',
        serviceIds: const ['sv_1'],
      );

      expect(created.id, 'ord_9');
      expect(created.message, contains('الانتظار المتوقع'));
    });

    test('bulk confirm sends the ids', () async {
      final server = FakeServer((_) => const FakeReply(200, {'status': true, 'message': 'تم تأكيد 2 حجز', 'data': {'confirmed': 2}}));
      final api = VendorApi(fakeClient(server, MemoryTokens()), MemoryTokens());

      expect(await api.bulkConfirm(['ord_1', 'ord_2']), 'تم تأكيد 2 حجز');
      final request = server.requests.single;
      expect(request.path, '/vendor/orders/bulk-confirm');
      expect(request.body, {
        'ids': ['ord_1', 'ord_2'],
      });
    });
  });

  test('the orders list sends a source filter and leaves out "all" (GAP-084)', () async {
    final server = FakeServer((_) => FakeReply.ok([], pagination: {'total': 0, 'has_next': false}));
    final api = VendorApi(fakeClient(server, MemoryTokens()), MemoryTokens());

    await api.orders(view: 'bookings', tab: 'today', branchId: 'br_1', source: 'phone');
    await api.orders(view: 'bookings', tab: 'today', branchId: 'br_1');

    expect(server.requests.first.query['source'], 'phone');
    expect(server.requests.last.query.containsKey('source'), isFalse);
  });

  group('actions follow the server (GAP-074)', () {
    test('list rows read allowedActions when the server sends them', () {
      expect(row().allowedActions, isNull);
      expect(row(allowed: ['note', 'cancel', 'something_new']).allowedActions, [OrderAction.note, OrderAction.cancel]);
    });

    test('no-show is not hidden behind a permission the server does not ask for', () {
      expect(OrderAction.noShow.permission, isNull);
    });

    test('the card step uses the row actions when present', () {
      expect(LiveController.nextStepAllowed(row(allowed: ['confirm']), can: everything, suspended: false), isTrue);
      expect(LiveController.nextStepAllowed(row(allowed: ['note']), can: everything, suspended: false), isFalse);
    });

    test('without row actions a suspended wash gets no confirm or check-in', () {
      expect(LiveController.nextStepAllowed(row(), can: everything, suspended: false), isTrue);
      expect(LiveController.nextStepAllowed(row(), can: everything, suspended: true), isFalse);
      expect(LiveController.nextStepAllowed(row(next: 'check_in'), can: everything, suspended: true), isFalse);
      expect(LiveController.nextStepAllowed(row(next: 'complete'), can: everything, suspended: true), isTrue);
    });

    test('locked rows and missing permissions still hide the step', () {
      expect(LiveController.nextStepAllowed(row(locked: true), can: everything, suspended: false), isFalse);
      expect(LiveController.nextStepAllowed(row(), can: (p) => p == null, suspended: false), isFalse);
    });
  });
}
