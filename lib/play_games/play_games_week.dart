/// Google Play Games leaderboard weeks begin Sunday 00:00 in UTC-7.
abstract final class PlayGamesWeek {
  static const offset = Duration(hours: 7);

  static String keyFor(DateTime instant) {
    final playLocal = instant.toUtc().subtract(offset);
    final daysSinceSunday = playLocal.weekday % DateTime.daysPerWeek;
    final sunday = DateTime.utc(
      playLocal.year,
      playLocal.month,
      playLocal.day,
    ).subtract(Duration(days: daysSinceSunday));
    return '${sunday.year.toString().padLeft(4, '0')}-'
        '${sunday.month.toString().padLeft(2, '0')}-'
        '${sunday.day.toString().padLeft(2, '0')}';
  }
}
