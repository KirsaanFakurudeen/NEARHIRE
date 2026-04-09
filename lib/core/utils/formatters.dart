import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static String currency(double amount, {String symbol = '\$'}) {
    final formatter = NumberFormat.currency(symbol: symbol, decimalDigits: 2);
    return formatter.format(amount);
  }

  static String currencyCompact(double amount, {String symbol = '\$'}) {
    if (amount >= 1000) {
      return '$symbol${(amount / 1000).toStringAsFixed(1)}k';
    }
    return '$symbol${amount.toStringAsFixed(0)}';
  }

  static String date(DateTime date) =>
      DateFormat('MMM d, yyyy').format(date);

  static String dateTime(DateTime date) =>
      DateFormat('MMM d, yyyy • h:mm a').format(date);

  static String relativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(date);
  }

  static String distance(double km) {
    if (km < 1.0) return '${(km * 1000).toStringAsFixed(0)} m away';
    return '${km.toStringAsFixed(1)} km away';
  }

  static String jobType(String type) {
    switch (type.toLowerCase()) {
      case 'full-time': return 'Full-Time';
      case 'part-time': return 'Part-Time';
      case 'freelance': return 'Freelance';
      case 'gig': return 'Gig';
      case 'shift-based': return 'Shift-Based';
      default: return type;
    }
  }
}
