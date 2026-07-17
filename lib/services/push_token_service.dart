import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

/// Sends this device's FCM push token to the backend so it can target the
/// signed‑in user with notifications. Call [register] right after a successful
/// login (it needs the user's `profileId`); token refreshes are re‑sent
/// automatically via [handleRefresh], which `main` wires to
/// `FirebaseMessaging.instance.onTokenRefresh`.
///
/// The backend counterpart is `NotificationsController.RegisterToken` in the
/// Cadaster repo (`POST api/notifications/register-token`, body
/// `{profileId, token, platform}`) — contract CONFIRMED 2026-07-16; a matching
/// `unregister-token` endpoint also exists for logout.
class PushTokenService {
  PushTokenService._();

  static const String _endpoint =
      'https://test-app.lrc.gov.lb/api/notifications/register-token';

  // Remembered so a later token refresh can be re‑registered for the same user.
  static int? _profileId;

  static String get _platform => Platform.isIOS ? 'ios' : 'android';

  /// Registers the current token for [profileId] and remembers it for refreshes.
  static Future<void> register(int profileId) async {
    _profileId = profileId;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await _post(profileId, token);
    } catch (e) {
      if (kDebugMode) debugPrint('[PushTokenService] register failed: $e');
    }
  }

  /// Re‑registers when FCM rotates the token (only if we know the user).
  static Future<void> handleRefresh(String token) async {
    final id = _profileId;
    if (id == null) return;
    try {
      await _post(id, token);
    } catch (e) {
      if (kDebugMode) debugPrint('[PushTokenService] refresh failed: $e');
    }
  }

  /// Clears the remembered user (call on logout).
  static void clear() => _profileId = null;

  static Future<void> _post(int profileId, String token) async {
    await http.post(
      Uri.parse(_endpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'profileId': profileId,
        'token': token,
        'platform': _platform,
      }),
    );
  }
}
