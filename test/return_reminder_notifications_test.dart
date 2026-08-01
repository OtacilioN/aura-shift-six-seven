import 'package:aura_shift_six_seven/core/return_reminder_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  AndroidFlutterLocalNotificationsPlugin.registerWith();

  const notificationsChannel =
      MethodChannel('dexterous.com/flutter/local_notifications');
  const timezoneChannel = MethodChannel('flutter_timezone');
  final calls = <MethodCall>[];

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(timezoneChannel, (call) async => 'UTC');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(notificationsChannel, (call) async {
      calls.add(call);
      if (call.method == 'initialize') return true;
      return null;
    });
  });

  tearDown(() {
    calls.clear();
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(timezoneChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(notificationsChannel, null);
  });

  test('registers the replacement reminder in one platform round-trip',
      () async {
    final notifications = await ReturnReminderNotifications.create();

    await notifications.schedule(
      scheduledAt: DateTime.now().add(const Duration(hours: 1)),
      title: 'Aura pronta',
      body: 'Volte para resgatar.',
    );

    expect(calls.map((call) => call.method), ['initialize', 'zonedSchedule']);
    expect(calls.last.arguments, isA<Map<Object?, Object?>>());
    expect(
      (calls.last.arguments as Map<Object?, Object?>)['id'],
      6701,
    );
  });
}
