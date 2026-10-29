import 'package:intl/intl.dart';

/// True when [date] falls on today's date in the device's local time zone.
bool isToday(DateTime? date) {
  if (date == null) return false;
  final local = date.toLocal();
  final now = DateTime.now();
  return local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
}

/// Example output: 2026-10-26T10:30:00+05:30 (same format as the API sample).
String toIsoWithOffset(DateTime date) {
  final local = date.toLocal();
  final offset = local.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final hours = offset.inHours.abs().toString().padLeft(2, '0');
  final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
  final base = DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(local);
  return '$base$sign$hours:$minutes';
}

String formatDateTime(DateTime date) {
  return DateFormat('dd MMM yyyy, hh:mm a').format(date.toLocal());
}
