/// Business rules for the optional Aura return reminder.
///
/// The reminder is deliberately inexact: the operating system may deliver it
/// a little later to preserve battery. The quiet period itself is calculated
/// before it is handed to the platform scheduler.
abstract final class ReturnReminderSchedule {
  static const delay = Duration(hours: 4);
  static const quietEndsAtMinute = 8 * 60 + 1;
  static const quietStartsAtMinute = 22 * 60;

  static DateTime afterLeaving(DateTime leftAt) {
    final due = leftAt.add(delay);
    final minuteOfDay = due.hour * 60 + due.minute;
    final duringQuietHours =
        minuteOfDay >= quietStartsAtMinute || minuteOfDay < quietEndsAtMinute;
    if (!duringQuietHours) return due;

    final nextAllowedDay = minuteOfDay >= quietStartsAtMinute
        ? due.add(const Duration(days: 1))
        : due;
    return DateTime(
      nextAllowedDay.year,
      nextAllowedDay.month,
      nextAllowedDay.day,
      8,
      1,
    );
  }
}
