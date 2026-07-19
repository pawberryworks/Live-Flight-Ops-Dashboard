String timestamp_to_string(int? secondsSinceEpoch) {
  if (secondsSinceEpoch == null) return '—';

  final localTime = DateTime.fromMillisecondsSinceEpoch(
    secondsSinceEpoch * Duration.millisecondsPerSecond,
    isUtc: true,
  ).toLocal();
  final year = localTime.year.toString().padLeft(4, '0');
  final month = localTime.month.toString().padLeft(2, '0');
  final day = localTime.day.toString().padLeft(2, '0');
  final hour = localTime.hour.toString().padLeft(2, '0');
  final minute = localTime.minute.toString().padLeft(2, '0');
  final second = localTime.second.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute:$second';
}