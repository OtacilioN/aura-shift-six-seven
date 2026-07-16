import 'package:aura_shift_six_seven/core/return_reminder_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps a four-hour reminder outside quiet hours', () {
    expect(
      ReturnReminderSchedule.afterLeaving(DateTime(2026, 7, 16, 13, 30)),
      DateTime(2026, 7, 16, 17, 30),
    );
  });

  test('delays a reminder at the start of quiet hours to 08:01', () {
    expect(
      ReturnReminderSchedule.afterLeaving(DateTime(2026, 7, 16, 18)),
      DateTime(2026, 7, 17, 8, 1),
    );
  });

  test('delays an overnight reminder to 08:01 on the same day', () {
    expect(
      ReturnReminderSchedule.afterLeaving(DateTime(2026, 7, 16, 2)),
      DateTime(2026, 7, 16, 8, 1),
    );
  });

  test('treats 08:00 as quiet and allows 08:01', () {
    expect(
      ReturnReminderSchedule.afterLeaving(DateTime(2026, 7, 16, 4)),
      DateTime(2026, 7, 16, 8, 1),
    );
    expect(
      ReturnReminderSchedule.afterLeaving(DateTime(2026, 7, 16, 4, 1)),
      DateTime(2026, 7, 16, 8, 1),
    );
  });

  test('carries a late-evening reminder across a month boundary', () {
    expect(
      ReturnReminderSchedule.afterLeaving(DateTime(2026, 7, 31, 20)),
      DateTime(2026, 8, 1, 8, 1),
    );
  });
}
