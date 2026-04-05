import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String dayMonth(DateTime dt) =>
      DateFormat('dd MMM', 'fr').format(dt);

  static String dayMonthYear(DateTime dt) =>
      DateFormat('dd MMMM yyyy', 'fr').format(dt);

  static String timeHHmm(DateTime dt) =>
      DateFormat('HH:mm').format(dt);

  static String dayMonthTime(DateTime dt) =>
      DateFormat('dd MMM à HH:mm', 'fr').format(dt);

  static String dateTime(DateTime dt) =>
      DateFormat('dd/MM/yyyy HH:mm').format(dt);

  static String relative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24)   return 'Il y a ${diff.inHours}h';
    if (diff.inDays == 1)    return 'Hier';
    if (diff.inDays < 7)     return 'Il y a ${diff.inDays} jours';
    return dayMonth(dt);
  }
}
