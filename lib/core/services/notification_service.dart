import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import '../../firebase_options.dart';
import '../data/vendor_api.dart';
import '../routing/app_routes.dart';
import 'session_service.dart';

/// The vendor server sends data-only messages. Android wakes this handler while
/// the app is closed, so it draws the notification here. iOS only shows a push
/// that carries a `notification` part.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (Platform.isAndroid && message.notification == null) {
    await NotificationService.showLocal(message.data);
  }
}

class NotificationService extends GetxService {
  static const String channelId = 'washup_owner_orders';
  static const String channelName = 'Wash Up Owner';

  static final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  VendorApi get _api => Get.find<VendorApi>();

  String? _registeredToken;

  // A message can arrive through FCM and a retry; each id shows once.
  final Set<String> _shown = {};

  Future<NotificationService> init() async {
    try {
      await _initLocal();
    } catch (e) {
      dev.log('[Notifications] local init failed: $e');
    }
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
      _listen();
    } catch (e) {
      dev.log('[Notifications] Firebase init failed: $e');
    }
    return this;
  }

  static Future<void> _initLocalPlugin(void Function(NotificationResponse)? onTap) async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@drawable/ic_notification'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _local.initialize(settings, onDidReceiveNotificationResponse: onTap);
  }

  Future<void> _initLocal() async {
    await _initLocalPlugin((response) => _openPayload(response.payload));
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            channelId,
            channelName,
            importance: Importance.max,
          ),
        );
    final launch = await _local.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      _openPayload(launch!.notificationResponse?.payload);
    }
  }

  void _listen() {
    final messaging = FirebaseMessaging.instance;
    FirebaseMessaging.onMessage.listen((message) {
      final id = message.data['id']?.toString() ?? message.messageId;
      if (id != null && !_shown.add(id)) return;
      showLocal(message.data, title: message.notification?.title, body: message.notification?.body);
      if (Get.isRegistered<SessionService>()) Get.find<SessionService>().notifyOrderChanged();
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) => openHref(message.data['href']?.toString()));
    messaging.getInitialMessage().then((message) {
      if (message != null) openHref(message.data['href']?.toString());
    });
    // ignore: deprecated_member_use
    messaging.onTokenRefresh.listen(_register);
  }

  static Future<void> showLocal(Map<String, dynamic> data, {String? title, String? body}) async {
    final text = title ?? data['title']?.toString();
    if (text == null || text.isEmpty) return;
    await _initLocalPlugin(null);
    await _local.show(
      (data['id']?.toString() ?? text).hashCode,
      text,
      body ?? data['body']?.toString(),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
      payload: jsonEncode({'href': data['href']}),
    );
  }

  void _openPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      openHref((jsonDecode(payload) as Map)['href']?.toString());
    } catch (_) {
      openHref(null);
    }
  }

  /// [href] is the dashboard path the server sends, like `/orders/ord_1`.
  static void openHref(String? href) {
    final match = RegExp(r'^/orders/([^/?]+)').firstMatch(href ?? '');
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (match != null) {
        Get.toNamed(Routes.orderRoute, arguments: match.group(1));
      } else {
        Get.toNamed(Routes.notificationsRoute);
      }
    });
  }

  /// Asks for permission and registers this device. Runs after sign-in, so the
  /// question appears when the owner understands why.
  Future<void> registerDevice() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      await _local
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      if (Platform.isIOS) {
        await messaging.setForegroundNotificationPresentationOptions(alert: false, sound: false);
        if (await _waitForApnsToken(messaging) == null) return;
      }
      // ignore: deprecated_member_use
      final token = await messaging.getToken();
      if (token != null) await _register(token);
    } catch (e) {
      dev.log('[Notifications] registerDevice failed: $e');
    }
  }

  // Apple can take a few seconds to hand over the APNs token after launch.
  Future<String?> _waitForApnsToken(FirebaseMessaging messaging) async {
    for (var i = 0; i < 10; i++) {
      final token = await messaging.getAPNSToken();
      if (token != null) return token;
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    return null;
  }

  Future<void> _register(String token) async {
    if (!Get.isRegistered<SessionService>() || Get.find<SessionService>().account.value == null) {
      return;
    }
    await _api.registerPush(token: token);
    _registeredToken = token;
  }

  /// Runs before sign-out, while the session is still valid.
  Future<void> unregisterDevice() async {
    final token = _registeredToken;
    if (token == null) return;
    _registeredToken = null;
    try {
      await _api.unregisterPush(token: token).timeout(const Duration(seconds: 4));
    } catch (e) {
      dev.log('[Notifications] unregister failed: $e');
    }
  }
}
