import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Schedules one optional, device-local reminder for the player's Aura.
///
/// A fixed ID makes a new background session replace the previous reminder.
class ReturnReminderNotifications {
  ReturnReminderNotifications._(this._plugin);

  static const _notificationId = 6701;
  static const _channelId = 'aura-return-reminders';
  static const _channelName = 'Aura pronta';
  static const _channelDescription =
      'Lembretes quando a Aura estiver pronta para resgatar.';

  final FlutterLocalNotificationsPlugin _plugin;

  static Future<ReturnReminderNotifications> create() async {
    tz.initializeTimeZones();
    final timezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezone.identifier));

    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    ));
    return ReturnReminderNotifications._(plugin);
  }

  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: false,
            sound: true,
          ) ??
          false;
    }
    return false;
  }

  Future<void> schedule({
    required DateTime scheduledAt,
    required String title,
    required String body,
  }) async {
    // The fixed notification ID already makes the platform replace an older
    // reminder. Avoid a separate cancel round-trip here: this method is called
    // while the app is moving to the background and the Dart isolate may be
    // suspended before a second platform call can register the new alarm.
    await _plugin.zonedSchedule(
      _notificationId,
      title,
      body,
      tz.TZDateTime.from(scheduledAt, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancel() => _plugin.cancel(_notificationId);
}
