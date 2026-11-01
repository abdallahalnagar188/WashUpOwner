import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:washup_owner/app.dart';
import 'package:washup_owner/core/local/cache_controller.dart';
import 'package:washup_owner/core/local/cache_helper.dart';
import 'package:washup_owner/core/local/theme_controller.dart';
import 'package:washup_owner/features/live/presentation/controllers/live_controller.dart';
import 'package:washup_owner/features/live/presentation/pages/live_page.dart';

void main() {
  Future<void> boot(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await CacheController().initSharedPreferences();
    await CacheHelper.init();
    await initializeDateFormatting();
    Get.put(ThemeController(), permanent: true);

    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  tearDown(Get.reset);

  testWidgets('a new user lands on login, signs in and reaches the live board', (tester) async {
    await boot(tester);

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(2));

    await tester.tap(find.text('تسجيل الدخول'));
    await tester.pump();
    expect(find.text('أدخل بيانات الدخول كاملة'), findsOneWidget);

    await tester.enterText(fields.at(0), 'owner');
    await tester.enterText(fields.at(1), 'secret');
    await tester.tap(find.text('تسجيل الدخول'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('بيانات تجريبية للعرض فقط'), findsOneWidget);
    expect(find.text('الإيراد المحصّل'), findsOneWidget);

    await tester.tap(find.text('التشغيل'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.byType(LivePage), findsOneWidget);
    expect(find.text('التشغيل المباشر'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    Get.delete<LiveController>(force: true);
  });
}
