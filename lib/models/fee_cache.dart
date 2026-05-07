import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FeeCache {
  static const String _feesKey = 'cachedFees';
  static const String _timestampKey = 'feesCacheTimestamp';
  static const Duration cacheDuration = Duration(days: 1);

  Future<Map<String, dynamic>?> get cachedFees async {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedFeesJson = prefs.getString(_feesKey);
    if (cachedFeesJson != null && await isCacheValid) {
      return jsonDecode(cachedFeesJson) as Map<String, dynamic>;
    }
    return null;
  }

  Future<void> setCachedFees(Map<String, dynamic>? fees) async {
    final prefs = await SharedPreferences.getInstance();
    if (fees != null) {
      prefs.setString(_feesKey, jsonEncode(fees));
      prefs.setString(_timestampKey, DateTime.now().toIso8601String());
    } else {
      prefs.remove(_feesKey);
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

final feeCache = FeeCache();
