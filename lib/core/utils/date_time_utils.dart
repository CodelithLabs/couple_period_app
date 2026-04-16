class DateTimeUtils {
  const DateTimeUtils._();

  static DateTime toUtcDate(DateTime value) {
    final localDate = DateTime(value.year, value.month, value.day);
    return DateTime.utc(localDate.year, localDate.month, localDate.day);
  }

  static int timezoneOffsetMinutesNow() {
    return DateTime.now().timeZoneOffset.inMinutes;
  }
}
