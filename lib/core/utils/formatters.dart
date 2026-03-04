import 'package:intl/intl.dart';

class Formatters {
  static String formatCurrency(double amount, {String symbol = 'RWF'}) {
    final formatter = NumberFormat('#,##0', 'en_US');
    return '${formatter.format(amount)} $symbol';
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} ${(difference.inDays / 365).floor() == 1 ? 'umwaka' : 'imyaka'} ishize';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} ${(difference.inDays / 30).floor() == 1 ? 'ukwezi' : 'amezi'} ashize';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'umunsi' : 'iminsi'} ishize';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'isaha' : 'amasaha'} ashize';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'umunota' : 'iminota'} ishize';
    } else {
      return 'Ubu';
    }
  }

  static String formatPhone(String phone) {
    if (phone.length == 10) {
      return '${phone.substring(0, 3)} ${phone.substring(3, 6)} ${phone.substring(6)}';
    }
    return phone;
  }

  static String formatPercentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }

  static String formatCompactNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toStringAsFixed(0);
  }

  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} ${duration.inDays == 1 ? 'umunsi' : 'iminsi'}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} ${duration.inHours == 1 ? 'isaha' : 'amasaha'}';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} ${duration.inMinutes == 1 ? 'umunota' : 'iminota'}';
    } else {
      return '${duration.inSeconds} ${duration.inSeconds == 1 ? 'isegonda' : 'amasegonda'}';
    }
  }

  static String maskPhone(String phone) {
    if (phone.length >= 10) {
      return '${phone.substring(0, 3)}***${phone.substring(phone.length - 3)}';
    }
    return phone;
  }

  static String formatNationalId(String id) {
    if (id.length == 16) {
      return '${id.substring(0, 1)} ${id.substring(1, 5)} ${id.substring(5, 9)} ${id.substring(9, 13)} ${id.substring(13)}';
    }
    return id;
  }
}
