import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PaidInvoicesCache {
  static const String _provincesKey = 'cachedPaidInvoices';
  static const String _timestampKey = 'cacheTimestamp';
  static const Duration cacheDuration = Duration(days: 1);

  Future<List<dynamic>?> get cachedPaidInvoices async {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedPaidInvoicesJson = prefs.getString(_provincesKey);
    if (cachedPaidInvoicesJson != null && await isCacheValid) {
      return jsonDecode(cachedPaidInvoicesJson) as List<dynamic>;
    }
    return null;
  }

  Future<void> setcachedPaidInvoices(List<dynamic>? provinces) async {
    final prefs = await SharedPreferences.getInstance();
    if (provinces != null) {
      prefs.setString(_provincesKey, jsonEncode(provinces));
      prefs.setString(_timestampKey, DateTime.now().toIso8601String());
    } else {
      prefs.remove(_provincesKey);
      prefs.remove(_timestampKey);
    }
  }

  Future<DateTime?> get cacheTimestamp async {
    final prefs = await SharedPreferences.getInstance();
    final String? timestampString = prefs.getString(_timestampKey);
    if (timestampString != null) {
      return DateTime.parse(timestampString);
    }
    return null;
  }

  Future<bool> get isCacheValid async {
    final DateTime? timestamp = await cacheTimestamp;
    if (timestamp != null) {
      final DateTime now = DateTime.now();
      return now.isBefore(timestamp.add(cacheDuration));
    }
    return false;
  }
}

final paidInvoicesCache = PaidInvoicesCache();
