import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Thin wrapper around [FlutterLocalNotificationsPlugin] for on-device
/// (local) notifications. This does NOT use Firebase — it talks directly to
/// the OS, so it works offline and is independent of FCM.
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _orderChannel =
      AndroidNotificationChannel(
    'order_status',
    'Order updates',
    description: 'Notifications about your payment and order status',
    importance: Importance.high,
  );

  static bool _initialized = false;

  /// Call once at app start (after Firebase is initialised in `main`).
  static Future<void> init() async {
    if (_initialized) return;

    const androidInit =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    // iOS / macOS: ask for permission at init time.
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
    );

    await _plugin.initialize(initSettings);

    // Android: create the channel up-front and request POST_NOTIFICATIONS
    // (Android 13+). Safe even if already granted via FirebaseMessaging.
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(_orderChannel);
    await androidImpl?.requestNotificationsPermission();

    // iOS: request the notification permission explicitly as well.
    final iosImpl = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await iosImpl?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'order_status',
      'Order updates',
      channelDescription:
          'Notifications about your payment and order status',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  /// Fire an immediate notification confirming the order is complete.
  static Future<void> showOrderCompleted({
    required String title,
    required String body,
  }) async {
    await _show(title: title, body: body);
  }

  /// Displays an incoming push while the app is in the foreground. Android does
  /// NOT show notification-payload pushes automatically when the app is open, so
  /// we surface them through the local-notifications plugin. [payload] carries
  /// the message's `data` (as JSON) so a tap can later be routed.
  static Future<void> showRemote({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _show(title: title, body: body, payload: payload);
  }

  static Future<void> _show({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      await init();
      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title.isEmpty ? null : title,
        body.isEmpty ? null : body,
        _details,
        payload: payload,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[NotificationService] show failed: $e');
    }
  }
}
