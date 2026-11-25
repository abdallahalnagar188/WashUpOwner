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
import '../routing/href_router.dart';
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

  /// How often a running app re-sends its token, in case another app removed it (GAP-094).
  static const Duration refreshEvery = Duration(minutes: 30);

  static final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  /// The plugin was initialised in this isolate with the tap handler. Initialising
  /// it again (as [showLocal] did for every foreground push) drops that handler,
  /// so later taps did nothing (GAP-051).
  static bool _localReady = false;

  /// A tapped notification that arrived before the app could show it: cold
  /// start, the splash, or the login page. Opened once the main page is up (GAP-051).
  static String? _pendingHref;
  static bool _hasPending = false;
  static bool _routerReady = false;

  VendorApi get _api => Get.find<VendorApi>();

  String? _registeredToken;
  DateTime? _registeredAt;

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
    _localReady = true;
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
    // Only the background isolate (no tap handler there anyway) initialises here.
    if (!_localReady) await _initLocalPlugin(null);
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
  /// Before the main page is up it waits, so the splash's route change does not
  /// throw it away.
  static void openHref(String? href) {
    if (!_routerReady) {
      _pendingHref = href;
      _hasPending = true;
      return;
    }
    _navigate(href);
  }

  /// The main page is on screen with a signed-in account: open a waiting tap.
  static void routerReady() {
    _routerReady = true;
    if (!_hasPending) return;
    final href = _pendingHref;
    _pendingHref = null;
    _hasPending = false;
    _navigate(href);
  }

  /// The main page is gone (sign-out): taps wait again for the next sign-in.
  static void routerGone() => _routerReady = false;

  static void _navigate(String? href) {
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (!HrefRouter.open(href)) Get.toNamed(Routes.notificationsRoute);
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

  /// Sends the token again when the app comes back, without asking for
  /// permission: signing out of the customer app on this phone could remove
  /// the owner app's row too (GAP-094).
  Future<void> refreshRegistration() async {
    final at = _registeredAt;
    if (_registeredToken == null || (at != null && DateTime.now().difference(at) < refreshEvery)) return;
    try {
      // ignore: deprecated_member_use
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _register(token);
    } catch (e) {
      dev.log('[Notifications] refreshRegistration failed: $e');
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
    _registeredAt = DateTime.now();
  }

  /// Runs before sign-out, while the session is still valid. After a restart
  /// the token is not in memory, so it is read again.
  Future<void> unregisterDevice() async {
    final known = _registeredToken;
    _registeredToken = null;
    _registeredAt = null;
    try {
      // ignore: deprecated_member_use
      final token = known ?? await FirebaseMessaging.instance.getToken().timeout(const Duration(seconds: 4));
      if (token == null) return;
      await _api.unregisterPush(token: token).timeout(const Duration(seconds: 4));
    } catch (e) {
      dev.log('[Notifications] unregister failed: $e');
    }
  }

  /// For any end of the session, including an expired one that can no longer
  /// call the server (GAP-049): the FCM token is deleted, so the server's next
  /// send to it fails as UNREGISTERED and the row is dropped. The next sign-in
  /// registers a fresh token for the new account.
  Future<void> forgetDevice() async {
    _registeredToken = null;
    _registeredAt = null;
    try {
      // deleteToken is deprecated in favour of unregister(), which belongs to the newer
      // installation-ID (FID) direct-send model. This app registers FCM *tokens* (getToken), and
      // deleting that token is what makes the server's next send fail as UNREGISTERED. Switch only
      // together with a move to FID registration.
      // ignore: deprecated_member_use
      await FirebaseMessaging.instance.deleteToken().timeout(const Duration(seconds: 6));
    } catch (e) {
      dev.log('[Notifications] deleteToken failed: $e');
    }
  }
}
