import 'package:intl/intl.dart';

/// Utility functions for dates
class DateTimeUtils {
  static String formatDate(DateTime date, {String format = 'dd/MM/yyyy'}) {
    try {
      return DateFormat(format, 'fr_FR').format(date);
    } catch (e) {
      return date.toString();
    }
  }

  static String formatTime(DateTime dateTime, {String format = 'HH:mm'}) {
    try {
      return DateFormat(format, 'fr_FR').format(dateTime);
    } catch (e) {
      return dateTime.toString();
    }
  }

  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} · ${formatTime(dateTime)}';
  }

  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) {
      return 'à l\'instant';
    } else if (diff.inMinutes < 60) {
      return 'il y a ${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return 'il y a ${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return 'il y a ${diff.inDays}j';
    } else {
      return formatDate(dateTime);
    }
  }

  static String getDayName(DateTime date) {
    const days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    return days[date.weekday - 1];
  }

  static String getMonthName(DateTime date) {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return months[date.month - 1];
  }

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day;
  }

  static String getWeekRange(DateTime date) {
    final startOfWeek = date.subtract(Duration(days: date.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return '${formatDate(startOfWeek)} au ${formatDate(endOfWeek)}';
  }
}

/// Utility functions for currency formatting
class CurrencyUtils {
  static final _currencyFormat = NumberFormat('#,##0', 'fr_FR');

  static String format(num amount, {String symbol = ' FCFA'}) {
    return '${_currencyFormat.format(amount)}$symbol';
  }

  static String formatWithDecimals(num amount, {String symbol = ' FCFA'}) {
    return '${NumberFormat('#,##0.00', 'fr_FR').format(amount)}$symbol';
  }

  static num parse(String amount) {
    try {
      return _currencyFormat.parse(amount);
    } catch (e) {
      return 0;
    }
  }
}

/// Utility functions for string operations
class StringUtils {
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  static String capitalizeWords(String text) {
    return text.split(' ').map(capitalize).join(' ');
  }

  static String truncate(String text, int maxLength, {String ellipsis = '...'}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  static bool isValidEmail(String email) {
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(email);
  }

  static bool isValidPhone(String phone) {
    final regex = RegExp(r'^\+?[0-9]{7,}$');
    return regex.hasMatch(phone);
  }

  static String formatPhone(String phone) {
    if (phone.length < 8) return phone;
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length == 8) {
      return '+225 ${cleaned.substring(0, 2)} ${cleaned.substring(2, 5)} ${cleaned.substring(5)}';
    }
    return phone;
  }

  static String getInitials(String name) {
    final parts = name.split(' ');
    return parts.map((p) => p.isNotEmpty ? p[0].toUpperCase() : '').join().substring(0, 2);
  }
}

/// Validation utilities
class ValidationUtils {
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email est requis';
    }
    if (!StringUtils.isValidEmail(email)) {
      return 'Email invalide';
    }
    return null;
  }

  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Mot de passe est requis';
    }
    if (password.length < 6) {
      return 'Mot de passe doit contenir au moins 6 caractères';
    }
    return null;
  }

  static String? validatePhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) {
      return 'Numéro de téléphone est requis';
    }
    if (!StringUtils.isValidPhone(phone)) {
      return 'Numéro de téléphone invalide';
    }
    return null;
  }

  static String? validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName est requis';
    }
    return null;
  }

  static String? validateMinLength(String? value, int length, String fieldName) {
    if (value == null || value.length < length) {
      return '$fieldName doit contenir au moins $length caractères';
    }
    return null;
  }

  static String? validateMaxLength(String? value, int length, String fieldName) {
    if (value == null || value.length > length) {
      return '$fieldName ne doit pas dépasser $length caractères';
    }
    return null;
  }

  static String? validatePositiveNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName est requis';
    }
    final number = num.tryParse(value);
    if (number == null || number <= 0) {
      return '$fieldName doit être un nombre positif';
    }
    return null;
  }
}

/// File utilities
class FileUtils {
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  static String getFileExtension(String fileName) {
    final parts = fileName.split('.');
    return parts.isNotEmpty ? parts.last.toLowerCase() : '';
  }

  static bool isImageFile(String fileName) {
    final ext = getFileExtension(fileName).toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
  }

  static bool isPdfFile(String fileName) {
    return getFileExtension(fileName).toLowerCase() == 'pdf';
  }
}
