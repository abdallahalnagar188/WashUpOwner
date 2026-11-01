import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:washup_owner/app.dart';
import 'package:washup_owner/binding/app_binding.dart';
import 'package:washup_owner/core/local/cache_controller.dart';
import 'package:washup_owner/core/local/cache_helper.dart';
import 'package:washup_owner/core/local/theme_controller.dart';
import 'package:washup_owner/core/network/token_store.dart';

import 'helpers/fake_server.dart';

Map<String, dynamic> _account(Map<String, bool> permissions) => {
      'id': 'st_1',
      'name': 'Owner Test',
      'role': 'owner',
      'phone': '01000000000',
      'businessName': {'ar': 'مغسلة', 'en': 'Wash'},
      'branches': [
        {
          'id': 'br_1',
          'name': {'ar': 'فرع', 'en': 'Branch'},
          'active': true,
          'capacity': 4,
        },
      ],
      'homeBranchId': 'br_1',
      'permissions': permissions,
      'maxDiscountPct': 100,
    };

final Map<String, dynamic> _row = {
  'id': 'ord_1',
  'number': 'WU-1',
  'plate': 'ABC 123',
  'vehicleLabel': 'Kia Cerato',
  'customerName': 'Customer',
  'serviceName': {'ar': 'غسيل', 'en': 'Wash'},
  'scheduledAt': '2026-11-01T10:00:00.000Z',
  'total': 180,
  'source': 'walk_in',
  'status': 'waiting',
  'paymentStatus': 'pending',
  'nextAction': 'start',
};

FakeServer _server({required Map<String, bool> permissions, required List<Map<String, dynamic>> actions}) {
  return FakeServer((request) {
    final path = request.path;
    if (path == '/vendor/auth/login') {
      return FakeReply.ok({'access_token': 'a', 'refresh_token': 'r', 'account': _account(permissions)});
    }
    if (path == '/vendor/dashboard') {
      return FakeReply.ok({
        'generatedAt': '2026-11-01T10:40:01.781Z',
        'kpis': [
          {'key': 'revenue', 'value': 356, 'delta': 12},
          {'key': 'totalOrders', 'value': 4, 'delta': null},
        ],
        'liveBranches': [],
        'carsInside': [_row],
        'alerts': [],
        'charts': {'revenueByHour': []},
      });
    }
    if (path == '/vendor/notifications') return FakeReply.ok([], meta: {'unread': 2});
    if (path == '/vendor/live') {
      return FakeReply.ok({
        'generatedAt': '2026-11-01T10:40:01.781Z',
        'columns': {
          'upcoming': [],
          'waiting': [_row],
          'in_service': [],
          'payment_pending': [],
          'done': [],
        },
        'bays': {'busy': 1, 'capacity': 4},
        'staffOnShift': [],
      });
    }
    if (path == '/vendor/orders') {
      return FakeReply.ok([_row], pagination: {'total': 1, 'has_next': false}, meta: {'counts': {'active': 1}});
    }
    if (path == '/vendor/orders/ord_1/actions') {
      actions.add(request.body!);
      return FakeReply.ok(null);
    }
    if (path == '/vendor/orders/ord_1') {
      return FakeReply.ok({
        'allowedActions': ['start', 'cancel', 'note'],
        'nextAction': 'start',
        'assignableStaff': [],
        'availableAddons': [],
        'maxDiscountPct': 100,
        'locked': false,
        'customer': {'name': 'Customer', 'phone': '01000000000'},
        'order': {
          'id': 'ord_1',
          'number': 'WU-1',
          'plate': 'ABC 123',
          'status': 'waiting',
          'paymentStatus': 'pending',
          'source': 'walk_in',
          'scheduledAt': '2026-11-01T10:00:00.000Z',
          'subtotal': 180,
          'total': 180,
          'items': [],
          'timeline': [],
          'notes': [],
        },
      });
    }
    return FakeReply.error(404, 'not found: $path');
  });
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
}

Future<void> _signIn(WidgetTester tester, FakeServer server) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  FlutterSecureStorage.setMockInitialValues({});
  await CacheController().initSharedPreferences();
  await CacheHelper.init();
  await initializeDateFormatting();
  Get.put(ThemeController(), permanent: true);

  final TokenStore tokens = MemoryTokens();
  await tester.pumpWidget(MyApp(binding: AppBinding(client: fakeClient(server, tokens))));
  await tester.pump(const Duration(seconds: 2));
  await _settle(tester);

  await tester.enterText(find.byType(TextField).at(0), '01000000000');
  await tester.enterText(find.byType(TextField).at(1), 'secret');
  await tester.tap(find.text('تسجيل الدخول'));
  await _settle(tester);
}

Future<void> _finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
  Get.reset();
}

void main() {
  testWidgets('signs in, sees the home numbers, opens a car and runs the next step', (tester) async {
    final actions = <Map<String, dynamic>>[];
    final server = _server(
      permissions: {'runService': true, 'cancelOrder': true},
      actions: actions,
    );
    await _signIn(tester, server);

    expect(find.text('الإيراد المحصّل'), findsOneWidget);

    await tester.tap(find.text('التشغيل'));
    await _settle(tester);
    expect(find.text('ABC 123'), findsWidgets);

    await tester.tap(find.text('ABC 123').last);
    await _settle(tester);
    expect(find.text('بدء الخدمة'), findsOneWidget);

    await tester.tap(find.text('بدء الخدمة'));
    await _settle(tester);
    expect(actions, [
      {'action': 'start'},
    ]);

    await _finish(tester);
  });

  testWidgets('an account without the permission does not get the action', (tester) async {
    final server = _server(permissions: {}, actions: []);
    await _signIn(tester, server);

    await tester.tap(find.text('التشغيل'));
    await _settle(tester);
    await tester.tap(find.text('ABC 123').last);
    await _settle(tester);

    expect(find.text('ABC 123'), findsWidgets);
    final startButtons = find.ancestor(of: find.text('بدء الخدمة'), matching: find.byType(GestureDetector));
    expect(startButtons, findsNothing);

    await _finish(tester);
  });
}
