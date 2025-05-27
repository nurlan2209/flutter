import 'package:intl/intl.dart';

class DateUtils {
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Сегодня';
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дней назад';
    } else {
      return DateFormat('d MMMM yyyy', 'ru').format(date);
    }
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('d MMMM yyyy, HH:mm', 'ru').format(dateTime);
  }

  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy', 'ru').format(date);
  }

  static String formatShortDate(DateTime date) {
    return DateFormat('d MMM', 'ru').format(date);
  }
}