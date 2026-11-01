import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'app.dart';
import 'core/local/cache_controller.dart';
import 'core/local/cache_helper.dart';
import 'core/local/theme_controller.dart';
import 'core/services/notification_service.dart';
import 'core/utils/system_ui.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await CacheController().initSharedPreferences();
  await CacheHelper.init();
  await initializeDateFormatting();
  // Times use the same digits as the rest of the app and the dashboard.
  DateFormat.useNativeDigitsByDefaultFor('ar', false);
  Get.put(await NotificationService().init(), permanent: true);

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  Get.put(ThemeController(), permanent: true);
  SystemUi.apply();

  runApp(const MyApp());
}
