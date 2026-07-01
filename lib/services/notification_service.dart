import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification.dart';

class NotificationService {
  static final NotificationService _i = NotificationService._();
  NotificationService._();
  factory NotificationService() => _i;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _channelId = 'pace_speedrun';
  static const _channelName = 'Pace — speedrun.com';
  static const _channelDesc = 'Notifications de votre compte speedrun.com';
  static const _seenKey = 'seen_notif_ids';

  Future<void> initialize() async {
    if (_ready) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Android 13+ explicit permission request
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _ready = true;
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  /// Compares fetched notifications against seen IDs,
  /// shows a local notification for each new one.
  Future<int> checkAndNotify(List<AppNotification> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    final seen = Set<String>.from(prefs.getStringList(_seenKey) ?? []);

    final newOnes = notifications.where((n) => !seen.contains(n.id)).toList();

    for (int i = 0; i < newOnes.length && i < 5; i++) {
      final n = newOnes[i];
      await show(
        id: n.id.hashCode.abs(),
        title: 'Pace · speedrun.com',
        body: n.text,
        payload: n.itemUrl,
      );
    }

    // Persist seen IDs
    await prefs.setStringList(
      _seenKey,
      notifications.map((n) => n.id).toList(),
    );

    return newOnes.length;
  }
}
