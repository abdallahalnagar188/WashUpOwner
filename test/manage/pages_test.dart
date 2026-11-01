import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:washup_owner/commons/models/owner_account.dart';
import 'package:washup_owner/commons/styles/themes/app_theme.dart';
import 'package:washup_owner/core/data/vendor_api.dart';
import 'package:washup_owner/core/local/app_translation.dart';
import 'package:washup_owner/core/routing/app_routes.dart';
import 'package:washup_owner/core/routing/manage_pages.dart';
import 'package:washup_owner/core/services/session_service.dart';
import 'package:washup_owner/core/utils/responsive_helper.dart';
import 'package:washup_owner/features/manage/settings/widgets/settings_sections.dart';

import '../helpers/fake_server.dart';
import 'fixtures.dart';

const Size _smallPhone = Size(960, 1920);

final Map<String, dynamic> _pagination = {'total': 1, 'has_next': false};

/// Answers the whole management API from the fixtures.
FakeServer _server({Map<String, dynamic>? closing, Map<String, FakeReply>? overrides}) {
  return FakeServer((request) {
    final override = overrides?[request.path];
    if (override != null) return override;
    if (request.method != 'GET') return FakeReply.ok(null);
    return switch (request.path) {
      '/vendor/notifications' => FakeReply.ok(
          [
            notificationRow,
            {...notificationRow, 'id': 'ntf_2', 'href': '/reviews', 'read': true},
          ],
          meta: {'unread': 1},
          pagination: _pagination,
        ),
      '/vendor/schedule' => FakeReply.ok(scheduleDay),
      '/vendor/services' => FakeReply.ok([serviceRow, addonRow], meta: {'canEdit': true}),
      '/vendor/offers' => FakeReply.ok(
          [offerRow, platformOffer, draftOffer],
          meta: {
            'counts': {'active': 1, 'scheduled': 1, 'draft': 1, 'disabled': 0, 'expired': 0},
          },
        ),
      '/vendor/staff' => FakeReply.ok(
          [staffRow(), staffRow(id: 'st_3', role: 'manager', status: 'suspended'), staffRow(id: 'st_1', role: 'owner')],
          meta: {
            'counts': {'all': 3, 'owner': 1, 'manager': 1, 'employee': 1},
            'onShift': 2,
          },
        ),
      '/vendor/shifts' => FakeReply.ok(
          [shiftRow],
          meta: {
            'counts': {'all': 1, 'submitted': 1, 'difference': 1, 'open': 0, 'flagged': 0, 'reviewed': 0},
            'totals': {'expected': 900, 'difference': -19.5},
          },
          pagination: _pagination,
        ),
      '/vendor/shifts/shf_1' => FakeReply.ok(shiftDetails),
      '/vendor/day-closing' => FakeReply.ok(dayClosing(closing: closing)),
      '/vendor/customers' => FakeReply.ok(
          [customerRow],
          meta: {
            'counts': {'all': 1, 'new': 0, 'returning': 1, 'lost': 0},
          },
          pagination: _pagination,
        ),
      '/vendor/customers/cus_1' => FakeReply.ok(customerDetails),
      '/vendor/reviews' => FakeReply.ok(
          [reviewRow(), reviewRow(reply: 'شكرًا لك', reported: true)],
          meta: reviewsMeta,
          pagination: _pagination,
        ),
      '/vendor/reports' => FakeReply.ok(ordersReport),
      '/vendor/finance' => FakeReply.ok(finance),
      '/vendor/branches' => FakeReply.ok([branchRow]),
      '/vendor/audit' => FakeReply.ok([auditRow], pagination: _pagination),
      '/vendor/settings' => FakeReply.ok(settings),
      _ => FakeReply.error(404, 'not found: ${request.path}'),
    };
  });
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

Future<void> _open(
  WidgetTester tester,
  FakeServer server,
  String route, {
  Object? arguments,
  String locale = 'ar',
  Map<String, dynamic>? owner,
  Size size = const Size(1170, 2532),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await initializeDateFormatting();
  Get.reset();

  final tokens = MemoryTokens(access: 'a');
  final api = Get.put(VendorApi(fakeClient(server, tokens), tokens), permanent: true);
  final session = Get.put(SessionService(api), permanent: true);
  session.account.value = OwnerAccount.fromJson(owner ?? account());

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: ResponsiveHelper.designSize,
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, __) {
        ResponsiveHelper.configureClampedScreenUtil(context);
        return GetMaterialApp(
          theme: MyAppTheme.lightTheme,
          translations: AppTranslations(),
          locale: Locale(locale),
          fallbackLocale: const Locale('ar'),
          getPages: appPages,
          home: const Scaffold(),
        );
      },
    ),
  );
  await tester.pump();
  Get.toNamed(route, arguments: arguments);
  await _settle(tester);
}

Future<void> _finish(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
  Get.reset();
}

/// Brings a widget into view inside the open sheet or page, then taps it.
Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(finder);
  await _settle(tester);
}

List<FakeRequest> _writes(FakeServer server) => server.requests.where((r) => r.method != 'GET').toList();

/// The real font, so a text that overflows here overflows on a phone too.
Future<void> _loadFont() async {
  final loader = FontLoader('IPM');
  for (final weight in const ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    final bytes = File('assets/fonts/IBMPlexSansArabic-$weight.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

void main() {
  setUpAll(_loadFont);

  const pages = <String, Object?>{
    Routes.notificationsRoute: null,
    Routes.scheduleRoute: null,
    Routes.servicesRoute: null,
    Routes.offersRoute: null,
    Routes.staffRoute: null,
    Routes.shiftsRoute: null,
    ManageRoutes.shiftRoute: 'shf_1',
    ManageRoutes.dayClosingRoute: null,
    Routes.customersRoute: null,
    ManageRoutes.customerRoute: 'cus_1',
    Routes.reviewsRoute: null,
    Routes.reportsRoute: null,
    Routes.financeRoute: null,
    Routes.branchesRoute: null,
    Routes.auditRoute: null,
    Routes.settingsRoute: null,
  };

  for (final locale in const ['ar', 'en']) {
    group('in $locale', () {
      for (final entry in pages.entries) {
        testWidgets('${entry.key} draws with a back button', (tester) async {
          await _open(tester, _server(), entry.key, arguments: entry.value, locale: locale);

          expect(
            find.byIcon(locale == 'ar' ? Iconsax.arrow_right_3 : Iconsax.arrow_left_2),
            findsWidgets,
          );
          expect(find.textContaining('error.'), findsNothing);

          await _finish(tester);
        });
      }
    });
  }

  for (final entry in pages.entries) {
    testWidgets('${entry.key} fits a small phone', (tester) async {
      await _open(tester, _server(), entry.key, arguments: entry.value, size: _smallPhone);
      await _finish(tester);
    });
  }

  group('sheets fit a small phone in Arabic', () {
    Future<void> sheet(WidgetTester tester, String route, List<Finder> steps) async {
      await _open(tester, _server(), route, size: _smallPhone);
      for (final step in steps) {
        await _tap(tester, step);
      }
      await _finish(tester);
    }

    testWidgets('block a slot', (tester) => sheet(tester, Routes.scheduleRoute, [find.byIcon(Iconsax.lock_1).at(2)]));

    testWidgets('new service', (tester) => sheet(tester, Routes.servicesRoute, [find.byIcon(Iconsax.add)]));

    testWidgets('edit service', (tester) => sheet(tester, Routes.servicesRoute, [find.text('غسيل خارجي')]));

    testWidgets('new offer', (tester) => sheet(tester, Routes.offersRoute, [find.byIcon(Iconsax.add)]));

    testWidgets('edit offer', (tester) => sheet(tester, Routes.offersRoute, [find.byIcon(Iconsax.edit_2).first]));

    testWidgets('new staff', (tester) => sheet(tester, Routes.staffRoute, [find.byIcon(Iconsax.add)]));

    testWidgets('staff file', (tester) => sheet(tester, Routes.staffRoute, [find.text('Test Worker').first]));

    testWidgets('edit staff',
        (tester) => sheet(tester, Routes.staffRoute, [find.text('Test Worker').first, find.text('تعديل')]));

    testWidgets('edit shifts',
        (tester) => sheet(tester, Routes.staffRoute, [find.text('Test Worker').first, find.text('تعديل الورديات')]));

    testWidgets('deactivate',
        (tester) => sheet(tester, Routes.staffRoute, [find.text('Test Worker').first, find.text('إيقاف الحساب')]));

    testWidgets('branch file', (tester) => sheet(tester, Routes.branchesRoute, [find.text('فرع 1')]));

    testWidgets(
        'edit branch', (tester) => sheet(tester, Routes.branchesRoute, [find.text('فرع 1'), find.text('تعديل الفرع')]));

    testWidgets('edit rules',
        (tester) => sheet(tester, Routes.branchesRoute, [find.text('فرع 1'), find.text('تعديل قواعد الحجز')]));

    testWidgets('reply', (tester) => sheet(tester, Routes.reviewsRoute, [find.text('رد')]));

    testWidgets('report', (tester) => sheet(tester, Routes.reviewsRoute, [find.text('إبلاغ')]));
  });

  for (final entry in pages.entries) {
    testWidgets('${entry.key} survives a failed load', (tester) async {
      final server = FakeServer((_) => FakeReply.error(500, 'تعذر'));
      await _open(tester, server, entry.key, arguments: entry.value);

      expect(find.text('تعذر'), findsOneWidget);
      expect(find.text('إعادة المحاولة'), findsOneWidget);

      await _finish(tester);
    });
  }

  testWidgets('the date picker opens in Arabic', (tester) async {
    await _open(tester, _server(), Routes.scheduleRoute);

    await tester.tap(find.byIcon(Iconsax.calendar_1));
    await _settle(tester);

    expect(find.byType(DatePickerDialog), findsOneWidget);

    await _finish(tester);
  });

  testWidgets('the time picker opens in Arabic', (tester) async {
    await _open(tester, _server(), Routes.staffRoute);

    await tester.tap(find.text('Test Worker').first);
    await _settle(tester);
    await _tap(tester, find.text('تعديل الورديات'));
    await tester.tap(find.text('09:00'));
    await _settle(tester);

    expect(find.byType(TimePickerDialog), findsOneWidget);

    await _finish(tester);
  });

  testWidgets('a form scrolled away keeps what was typed', (tester) async {
    await _open(tester, _server(), Routes.settingsRoute, locale: 'en');

    await tester.enterText(find.byType(TextField).first, 'اسم جديد');
    await tester.pump();
    await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -3000));
    await _settle(tester);
    await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, 3000));
    await _settle(tester);

    expect(find.text('اسم جديد'), findsOneWidget);

    await _finish(tester);
  });

  testWidgets('a closed day shows its report instead of the form', (tester) async {
    await _open(tester, _server(closing: closingRecord), ManageRoutes.dayClosingRoute, locale: 'en');

    expect(find.text('Closing report'), findsOneWidget);
    expect(find.text('Close the day'), findsNothing);

    await _finish(tester);
  });

  testWidgets('tapping a notification marks it read and opens the order', (tester) async {
    final server = _server(overrides: {'/vendor/orders/ord_1': FakeReply.error(404, 'x')});
    await _open(tester, server, Routes.notificationsRoute, locale: 'en');

    await tester.tap(find.text('New booking').first);
    await _settle(tester);

    expect(_writes(server).single.path, '/vendor/notifications/ntf_1/read');
    expect(Get.currentRoute, Routes.orderRoute);
    expect(Get.arguments, 'ord_1');

    await _finish(tester);
  });

  testWidgets('a notification without an order only marks read state', (tester) async {
    final server = _server();
    await _open(tester, server, Routes.notificationsRoute, locale: 'en');

    await tester.tap(find.text('New booking').last);
    await _settle(tester);

    expect(_writes(server), isEmpty, reason: 'it was already read');
    expect(Get.currentRoute, Routes.notificationsRoute);

    await _finish(tester);
  });

  testWidgets('read all posts once', (tester) async {
    final server = _server();
    await _open(tester, server, Routes.notificationsRoute, locale: 'en');

    await tester.tap(find.byIcon(Iconsax.tick_square));
    await _settle(tester);

    expect(_writes(server).single.path, '/vendor/notifications/read-all');

    await _finish(tester);
  });

  testWidgets('blocks a slot from the schedule', (tester) async {
    final server = _server();
    await _open(tester, server, Routes.scheduleRoute, locale: 'en');

    await tester.tap(find.byIcon(Iconsax.lock_1).at(2));
    await _settle(tester);
    await tester.enterText(find.byType(TextField).last, 'Broken pump');
    await tester.pump();
    await _tap(tester, find.text('Block a slot').last);

    final request = _writes(server).single;
    expect(request.path, '/vendor/schedule/blocks');
    expect(request.body, {
      'branchId': 'br_1',
      'start': '2099-11-01T11:00:00.000Z',
      'end': '2099-11-01T11:30:00.000Z',
      'reason': 'Broken pump',
    });

    await _finish(tester);
  });

  testWidgets('removes a block after asking', (tester) async {
    final server = _server();
    await _open(tester, server, Routes.scheduleRoute, locale: 'en');

    await tester.tap(find.text('Remove block').first);
    await _settle(tester);
    await tester.tap(find.text('Remove block').last);
    await _settle(tester);

    final request = _writes(server).single;
    expect(request.method, 'DELETE');
    expect(request.path, '/vendor/schedule/blocks/blk_1');

    await _finish(tester);
  });

  testWidgets('adds a service with a decimal price', (tester) async {
    final server = _server();
    await _open(tester, server, Routes.servicesRoute, locale: 'en');

    await tester.tap(find.byIcon(Iconsax.add));
    await _settle(tester);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'غسيل');
    await tester.enterText(fields.at(1), 'Wash');
    await tester.enterText(fields.at(4), '99.5');
    await tester.pump();
    await _tap(tester, find.text('common.save'.tr).last);

    final request = _writes(server).single;
    expect(request.method, 'POST');
    expect(request.path, '/vendor/services');
    expect(request.body?['price'], 99.5);
    expect(request.body?['durationMin'], 30);
    expect(request.body?['branchId'], 'br_1');
    expect(request.body?.containsKey('reason'), isFalse);

    await _finish(tester);
  });

  testWidgets('a price the server refuses keeps the form open', (tester) async {
    final server = _server(overrides: {
      '/vendor/services/svc_1': FakeReply.error(422, 'السعر غير مقبول'),
    });
    await _open(tester, server, Routes.servicesRoute, locale: 'en');

    await tester.tap(find.text('Exterior wash'));
    await _settle(tester);
    await tester.enterText(find.byType(TextField).at(4), '130');
    await tester.pump();
    expect(find.text('Reason for the price change (optional)'), findsOneWidget);

    await _tap(tester, find.text('common.save'.tr).last);

    expect(find.text('Edit service'), findsOneWidget);
    expect(_writes(server).single.method, 'PATCH');

    await _finish(tester);
  });

  testWidgets('without canEdit services are view only', (tester) async {
    final server = _server(overrides: {
      '/vendor/services': FakeReply.ok([serviceRow], meta: {'canEdit': false}),
    });
    await _open(tester, server, Routes.servicesRoute, locale: 'en');

    expect(find.byIcon(Iconsax.add), findsNothing);
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);

    await _finish(tester);
  });

  testWidgets('the service switch sends the whole service', (tester) async {
    final server = _server();
    await _open(tester, server, Routes.servicesRoute, locale: 'en');

    await tester.tap(find.byType(Switch).first);
    await _settle(tester);

    final request = _writes(server).single;
    expect(request.path, '/vendor/services/svc_1');
    expect(request.body?['active'], isFalse);
    expect(request.body?['price'], 120);

    await _finish(tester);
  });

  testWidgets('the offer switch shows only on live editable offers', (tester) async {
    final server = _server();
    await _open(tester, server, Routes.offersRoute, locale: 'en');

    expect(find.byType(Switch), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await _settle(tester);

    final request = _writes(server).single;
    expect(request.path, '/vendor/offers/ofr_1/status');
    expect(request.body, {'enabled': false});

    await _finish(tester);
  });

  testWidgets('a manager cannot edit offers', (tester) async {
    await _open(tester, _server(), Routes.offersRoute, locale: 'en', owner: account(role: 'manager'));

    expect(find.byType(Switch), findsNothing);
    expect(find.byIcon(Iconsax.add), findsNothing);
    expect(find.text('Edit'), findsNothing);

    await _finish(tester);
  });

  testWidgets('the offer form opens for a new offer and a draft', (tester) async {
    await _open(tester, _server(), Routes.offersRoute, locale: 'en');

    await tester.tap(find.byIcon(Iconsax.add));
    await _settle(tester);
    expect(find.text('Publish offer'), findsOneWidget);
    expect(find.text('Save as draft'), findsOneWidget);

    await _finish(tester);
  });

  testWidgets('offer chips filter by status', (tester) async {
    await _open(tester, _server(), Routes.offersRoute, locale: 'en');

    await tester.tap(find.text('Draft (1)'));
    await _settle(tester);

    expect(find.text('Review and publish'), findsOneWidget);
    expect(find.byType(Switch), findsNothing);

    await _finish(tester);
  });

  testWidgets('deactivating staff asks for a reason', (tester) async {
    final server = _server();
    await _open(tester, server, Routes.staffRoute, locale: 'en');

    await tester.tap(find.text('Test Worker').first);
    await _settle(tester);

    await _tap(tester, find.text('Deactivate account'));
    await tester.tap(find.text('Long leave'));
    await tester.pump();
    await _tap(tester, find.text('Deactivate account').last);

    final request = _writes(server).single;
    expect(request.path, '/vendor/staff/st_2/status');
    expect(request.body, {'active': false, 'reason': 'Long leave'});

    await _finish(tester);
  });

  testWidgets('the staff edit needs a change and a reason', (tester) async {
    final server = _server();
    await _open(tester, server, Routes.staffRoute, locale: 'en');

    await tester.tap(find.text('Test Worker').first);
    await _settle(tester);
    await _tap(tester, find.text('Edit'));

    await tester.enterText(find.byType(TextField).first, '12.5');
    await tester.enterText(find.byType(TextField).last, 'Promoted');
    await tester.pump();
    await _tap(tester, find.text('common.save'.tr).last);

    final request = _writes(server).single;
    expect(request.method, 'PATCH');
    expect(request.path, '/vendor/staff/st_2');
    expect(request.body?['maxDiscountPct'], 12.5);
    expect(request.body?['reason'], 'Promoted');
    expect(request.body?.containsKey('name'), isFalse);
    expect((request.body?['permissions'] as Map).length, 8);

    await _finish(tester);
  });

  testWidgets('the staff add form warns about the password', (tester) async {
    await _open(tester, _server(), Routes.staffRoute, locale: 'en');

    await tester.tap(find.byIcon(Iconsax.add));
    await _settle(tester);

    expect(find.textContaining('temporary password'), findsOneWidget);

    await _finish(tester);
  });

  testWidgets('the staff schedule sheet saves its shifts', (tester) async {
    final server = _server();
    await _open(tester, server, Routes.staffRoute, locale: 'en');

    await tester.tap(find.text('Test Worker').first);
    await _settle(tester);
    await _tap(tester, find.text('Edit shifts'));
    await _tap(tester, find.text('common.save'.tr).last);

    final request = _writes(server).single;
    expect(request.method, 'PUT');
    expect(request.path, '/vendor/staff/st_2/schedule');
    expect(request.body, {
      'shifts': [
        {
          'start': '09:00',
          'end': '17:00',
          'days': [0, 1, 2, 3, 4],
        },
      ],
    });

    await _finish(tester);
  });

  testWidgets('a shift review posts its status and note', (tester) async {
    final server = _server();
    await _open(tester, server, ManageRoutes.shiftRoute, arguments: 'shf_1', locale: 'en');

    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'Counted twice');
    await tester.pump();
    await _tap(tester, find.text('Mark reviewed'));

    final request = _writes(server).single;
    expect(request.path, '/vendor/shifts/shf_1/review');
    expect(request.body, {'status': 'reviewed', 'note': 'Counted twice'});

    await _finish(tester);
  });

  testWidgets('day closing needs a reason for a difference, then confirms', (tester) async {
    final server = _server();
    await _open(tester, server, ManageRoutes.dayClosingRoute, locale: 'en');

    final fields = find.byType(TextField);
    await tester.ensureVisible(fields.first);
    await tester.enterText(fields.first, '880.5');
    await tester.pump();
    expect(find.text('Difference: -19.5 ${'common.egp'.tr}'), findsOneWidget);

    await tester.ensureVisible(find.byType(TextField).last);
    await tester.enterText(find.byType(TextField).last, 'Short change');
    await tester.pump();
    await _tap(tester, find.text('Close the day'));
    await tester.tap(find.text('Confirm closing'));
    await _settle(tester);

    final request = _writes(server).single;
    expect(request.path, '/vendor/day-closing');
    expect(request.body, {
      'branchId': 'br_1',
      'date': '2026-11-01',
      'actual': {'cash': 880.5, 'card': 300, 'online': 0},
      'reason': 'Short change',
    });

    await _finish(tester);
  });

  testWidgets('open orders stop the day closing', (tester) async {
    final server = _server(overrides: {'/vendor/day-closing': FakeReply.ok(dayClosing(unpaid: 2))});
    await _open(tester, server, ManageRoutes.dayClosingRoute, locale: 'en');

    await tester.ensureVisible(find.byType(TextField).first);
    await tester.enterText(find.byType(TextField).first, '900');
    await tester.pump();
    await _tap(tester, find.text('Close the day'));

    expect(find.text('Confirm closing'), findsNothing);
    expect(_writes(server), isEmpty);

    await _finish(tester);
  });

  testWidgets('a review can be replied to and reported once', (tester) async {
    final server = _server();
    await _open(tester, server, Routes.reviewsRoute, locale: 'en');

    expect(find.text('Reply'), findsOneWidget);
    expect(find.text('Report'), findsOneWidget);

    await tester.tap(find.text('Reply'));
    await _settle(tester);
    await tester.enterText(find.byType(TextField), 'Sorry about that');
    await tester.pump();
    await _tap(tester, find.text('Reply').last);

    final request = _writes(server).single;
    expect(request.path, '/vendor/reviews/rvw_1/reply');
    expect(request.body, {'text': 'Sorry about that'});

    await _finish(tester);
  });

  testWidgets('report chips ask for the server type', (tester) async {
    final server = _server();
    await _open(tester, server, Routes.reportsRoute, locale: 'en');

    await tester.tap(find.text('Sources'));
    await _settle(tester);
    await tester.ensureVisible(find.text('Staff'));
    await tester.tap(find.text('Staff'));
    await _settle(tester);

    final types = server.requests.where((r) => r.path == '/vendor/reports').map((r) => r.query['type']);
    expect(types, ['orders', 'source', 'employees']);

    await _finish(tester);
  });

  testWidgets('a single branch hides the branch column of a report', (tester) async {
    await _open(tester, _server(), Routes.reportsRoute, locale: 'en');
    expect(find.text('Branch'), findsOneWidget);

    Get.find<SessionService>().branchId.value = 'br_1';
    await _settle(tester);
    expect(find.text('Branch'), findsNothing);

    await _finish(tester);
  });

  testWidgets('finance period chips reload', (tester) async {
    final server = _server();
    await _open(tester, server, Routes.financeRoute, locale: 'en');

    await tester.tap(find.text('Today'));
    await _settle(tester);

    expect(server.requests.where((r) => r.path == '/vendor/finance').map((r) => r.query['period']), ['30d', 'today']);

    await _finish(tester);
  });

  testWidgets('booking rules save with a reason', (tester) async {
    final server = _server();
    await _open(tester, server, Routes.branchesRoute, locale: 'en');

    await tester.tap(find.text('Branch 1'));
    await _settle(tester);
    await _tap(tester, find.text('Edit booking rules'));
    await tester.enterText(find.byType(TextField).last, 'Fewer late cancels');
    await tester.pump();
    await _tap(tester, find.text('common.save'.tr).last);

    final request = _writes(server).single;
    expect(request.method, 'PUT');
    expect(request.path, '/vendor/branches/br_1/settings');
    expect(request.body?['reason'], 'Fewer late cancels');
    expect((request.body?['settings'] as Map)['slotIntervalMin'], 30);

    await _finish(tester);
  });

  testWidgets('a branch edit keeps an unknown amenity and sends seven days', (tester) async {
    final server = _server();
    await _open(tester, server, Routes.branchesRoute, locale: 'en');

    await tester.tap(find.text('Branch 1'));
    await _settle(tester);
    await _tap(tester, find.text('Edit branch'));
    await tester.ensureVisible(find.byType(TextField).last);
    await tester.enterText(find.byType(TextField).last, 'Summer hours');
    await tester.pump();
    await _tap(tester, find.text('common.save'.tr).last);

    final request = _writes(server).single;
    expect(request.method, 'PATCH');
    expect(request.path, '/vendor/branches/br_1');
    expect((request.body?['workingHours'] as List).length, 7);
    expect(request.body?['amenities'], contains('pool'));
    expect(request.body?.containsKey('lat'), isFalse);
    expect(request.body?['reason'], 'Summer hours');

    await _finish(tester);
  });

  testWidgets('a manager sees branches and settings as read only', (tester) async {
    await _open(tester, _server(), Routes.settingsRoute, locale: 'en', owner: account(role: 'manager'));
    expect(find.text('common.save'.tr), findsNothing);
    expect(find.textContaining('Only the owner'), findsOneWidget);
    await _finish(tester);
  });

  testWidgets('settings save one section with a reason', (tester) async {
    final server = _server();
    await _open(tester, server, Routes.settingsRoute, locale: 'en');

    await _tap(tester, find.text('Let branch managers edit services and prices'));
    await _tap(tester, find.descendant(of: find.byType(ManagerEditsSection), matching: find.text('Save')));
    await tester.enterText(find.byType(TextField).last, 'Delegating');
    await tester.pump();
    await _tap(tester, find.text('common.save'.tr).last);

    final request = _writes(server).single;
    expect(request.method, 'PUT');
    expect(request.path, '/vendor/settings');
    expect(request.body, {'managerCanEditServices': true, 'reason': 'Delegating'});

    await _finish(tester);
  });

  testWidgets('the platform preference cannot be turned off', (tester) async {
    await _open(tester, _server(), Routes.settingsRoute, locale: 'en');

    final tile = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'From Wash Up'),
    );
    expect(tile.onChanged, isNull);
    expect(tile.value, isTrue);

    await _finish(tester);
  });
}
