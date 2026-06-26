import 'package:intl/intl.dart';

class AppUtils {
  /// Formats seconds (as double) into h:mm:ss.ms
  static String formatTime(double? seconds) {
    if (seconds == null || seconds == 0) return '--';
    final totalMs = (seconds * 1000).round();
    final ms = totalMs % 1000;
    final totalSec = totalMs ~/ 1000;
    final sec = totalSec % 60;
    final totalMin = totalSec ~/ 60;
    final min = totalMin % 60;
    final hours = totalMin ~/ 60;

    if (hours > 0) {
      return '$hours:${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}.${ms.toString().padLeft(3, '0')}';
    } else if (min > 0) {
      return '$min:${sec.toString().padLeft(2, '0')}.${ms.toString().padLeft(3, '0')}';
    } else {
      return '$sec.${ms.toString().padLeft(3, '0')}s';
    }
  }

  /// Format a date string yyyy-MM-dd
  static String formatDate(String? dateStr, {String locale = 'en'}) {
    if (dateStr == null) return '--';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat.yMMMd(locale).format(date);
    } catch (_) {
      return dateStr;
    }
  }

  /// Rank badge color
  static int rankColor(int rank) {
    switch (rank) {
      case 1:
        return 0xFFFFD700; // Gold
      case 2:
        return 0xFFC0C0C0; // Silver
      case 3:
        return 0xFFCD7F32; // Bronze
      default:
        return 0xFF9E9E9E;
    }
  }

  /// Rank emoji
  static String rankEmoji(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '#$rank';
    }
  }
}
