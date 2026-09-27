import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Base URL of the Laravel backend, configurable in one place.
///
/// - Android emulator: 10.0.2.2 is the host machine's loopback alias.
/// - Physical phone on the same Wi-Fi: replace with your PC's LAN IP,
///   e.g. http://192.168.1.20:8000/api
/// - Web (flutter run -d chrome): 127.0.0.1:8000.
class ApiConfig {
  ApiConfig._();
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );

  /// Reverb WebSocket server (same machine as the API).
  static const String reverbHost = String.fromEnvironment(
    'REVERB_HOST',
    defaultValue: '10.0.2.2',
  );
  static const int reverbPort = int.fromEnvironment('REVERB_PORT', defaultValue: 8080);
  static const String reverbAppKey = String.fromEnvironment(
    'REVERB_APP_KEY',
    defaultValue: 'tmc-equipment-local',
  );
}

/// Generic API response envelope.
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;
  final bool requiresEmailVerification;
  final String? unverifiedEmail;
  final Map<String, dynamic>? errors;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
    this.requiresEmailVerification = false,
    this.unverifiedEmail,
    this.errors,
  });
}

/// HTTP client for the TMC backend. All calls funnel through [request] so
/// auth headers, JSON decoding and error extraction stay consistent.
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  static const String baseUrl = ApiConfig.baseUrl;

  String? _authToken;
  final StreamController<String?> _tokenController = StreamController<String?>.broadcast();

  String? get authToken => _authToken;

  /// Emits the token whenever it changes (login / logout / restore), so the
  /// realtime service can (re)authenticate its private channels.
  Stream<String?> get tokenStream => _tokenController.stream;

  Future<void> setAuthToken(String? token) async {
    _authToken = token;
    _tokenController.add(token);
    final prefs = await SharedPreferences.getInstance();
    if (token == null || token.isEmpty) {
      await prefs.remove('tmc_auth_token');
    } else {
      await prefs.setString('tmc_auth_token', token);
    }
  }

  /// Restores the persisted session token at app startup. Returns the token
  /// if a session was restored (the caller then validates it via /mobile/profile).
  Future<String?> restoreToken() async {
    if (_authToken != null) return _authToken;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('tmc_auth_token');
    _authToken = token;
    return token;
  }

  Map<String, String> _headers({bool withAuth = true}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (withAuth && _authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  Future<ApiResponse<Map<String, dynamic>>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool withAuth = true,
  }) async {
    final uri = Uri.parse('$baseUrl/$path');
    try {
      final res = switch (method.toUpperCase()) {
        'POST' => await http
            .post(uri, headers: _headers(withAuth: withAuth), body: jsonEncode(body ?? {}))
            .timeout(const Duration(seconds: 20)),
        'PUT' => await http
            .put(uri, headers: _headers(withAuth: withAuth), body: jsonEncode(body ?? {}))
            .timeout(const Duration(seconds: 20)),
        'DELETE' => await http.delete(uri, headers: _headers(withAuth: withAuth)).timeout(const Duration(seconds: 20)),
        _ => await http.get(uri, headers: _headers(withAuth: withAuth)).timeout(const Duration(seconds: 20)),
      };

      final decoded = _parseJson(res.body);
      final ok = res.statusCode >= 200 && res.statusCode < 300;

      if (ok && decoded.isNotEmpty) {
        return ApiResponse(
          success: true,
          data: decoded,
          message: decoded['message'] as String?,
          statusCode: res.statusCode,
          errors: decoded['errors'] as Map<String, dynamic>?,
        );
      }
      return ApiResponse(
        success: false,
        message: _extractErrorMessage(decoded, 'Request failed (${res.statusCode}).'),
        statusCode: res.statusCode,
        data: decoded.isNotEmpty ? decoded : null,
        errors: decoded['errors'] as Map<String, dynamic>?,
      );
    } on TimeoutException {
      return ApiResponse(success: false, message: 'The server took too long to respond.');
    } catch (e) {
      debugPrint('ApiService $method $path failed: $e');
      return ApiResponse(success: false, message: 'Could not connect to the server. Is the backend running?');
    }
  }

  /// GET an endpoint that returns a JSON array (equipment, borrowings,
  /// notifications). Kept separate from [request] so the response envelope
  /// is properly typed for list consumers.
  Future<ApiResponse<List<dynamic>>> requestList(String path) async {
    final uri = Uri.parse('$baseUrl/$path');
    try {
      final res = await http
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 20));
      final ok = res.statusCode >= 200 && res.statusCode < 300;

      if (ok) {
        final decoded = _parseList(res.body);
        return ApiResponse(
          success: true,
          data: decoded,
          statusCode: res.statusCode,
        );
      }

      final decoded = _parseJson(res.body);
      return ApiResponse(
        success: false,
        message: _extractErrorMessage(decoded, 'Request failed (${res.statusCode}).'),
        statusCode: res.statusCode,
      );
    } on TimeoutException {
      return ApiResponse(success: false, message: 'The server took too long to respond.');
    } catch (e) {
      debugPrint('ApiService GET $path failed: $e');
      return ApiResponse(success: false, message: 'Could not connect to the server. Is the backend running?');
    }
  }

  // =========================================================================
  // AUTHENTICATION
  // =========================================================================

  /// Register student — backend creates a Pending account and emails a
  /// 6-digit verification code.
  Future<ApiResponse<Map<String, dynamic>>> register({
    required String firstName,
    String? middleName,
    required String lastName,
    required String username,
    required String email,
    String? contactNumber,
    required String password,
    required String passwordConfirmation,
  }) async {
    final res = await request('POST', 'register', withAuth: false, body: {
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'username': username,
      'email': email,
      'contact_number': contactNumber,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
    if (res.success) {
      return ApiResponse(
        success: true,
        data: res.data,
        message: res.message ?? 'Registration successful. Verification code sent!',
        statusCode: res.statusCode,
        requiresEmailVerification: true,
        unverifiedEmail: email,
      );
    }
    return res;
  }

  /// Verify email with the 6-digit code.
  Future<ApiResponse<Map<String, dynamic>>> verifyEmail({
    required String email,
    required String code,
  }) =>
      request('POST', 'verify-email', withAuth: false, body: {
        'email': email,
        'code': code.trim(),
      });

  /// Resend a fresh 6-digit verification code.
  Future<ApiResponse<Map<String, dynamic>>> resendVerification({required String email}) =>
      request('POST', 'resend-verification', withAuth: false, body: {'email': email});

  /// Request a 6-digit password reset code.
  Future<ApiResponse<Map<String, dynamic>>> forgotPassword({required String email}) =>
      request('POST', 'forgot-password', withAuth: false, body: {'email': email.trim()});

  /// Reset password using the 6-digit code.
  Future<ApiResponse<Map<String, dynamic>>> resetPassword({
    required String email,
    required String code,
    required String password,
    required String passwordConfirmation,
  }) =>
      request('POST', 'reset-password', withAuth: false, body: {
        'email': email.trim(),
        'code': code.trim(),
        'password': password,
        'password_confirmation': passwordConfirmation,
      });

  /// Mobile login. Accepts username OR email as identifier.
  Future<ApiResponse<Map<String, dynamic>>> login({
    required String identifier,
    required String password,
  }) async {
    final res = await request('POST', 'mobile/login', withAuth: false, body: {
      'login': identifier.trim(),
      'password': password,
    });

    if (res.success) {
      final token = res.data?['token'] as String?;
      if (token != null) await setAuthToken(token);
    } else if (res.statusCode == 403 &&
        res.data?['requires_email_verification'] == true) {
      return ApiResponse(
        success: false,
        message: res.message ?? 'Please verify your email address first.',
        statusCode: res.statusCode,
        requiresEmailVerification: true,
        unverifiedEmail: (res.data?['email'] as String?) ?? identifier,
      );
    }
    return res;
  }

  /// Persisted-session restore: validates the stored token by fetching the
  /// profile. Returns the user payload on success, null if the token is dead.
  Future<Map<String, dynamic>?> restoreSession() async {
    final token = await restoreToken();
    if (token == null || token.isEmpty) return null;
    final res = await request('GET', 'mobile/profile');
    if (res.success && res.data != null) return res.data;
    await setAuthToken(null);
    return null;
  }

  Future<ApiResponse<Map<String, dynamic>>> logout() async {
    final res = await request('POST', 'mobile/logout');
    await setAuthToken(null);
    return res;
  }

  // =========================================================================
  // EQUIPMENT
  // =========================================================================

  Future<ApiResponse<List<dynamic>>> equipmentList() => requestList('mobile/equipment');

  Future<ApiResponse<Map<String, dynamic>>> equipmentShow(int id) =>
      request('GET', 'mobile/equipment/$id');

  // =========================================================================
  // BORROWING
  // =========================================================================

  Future<ApiResponse<Map<String, dynamic>>> submitBorrowRequest({
    required int equipmentId,
    required int quantity,
    required String borrowingDate,
    required String expectedReturnDate,
    required String purpose,
    String? notes,
  }) =>
      request('POST', 'mobile/borrow', body: {
        'equipment_id': equipmentId,
        'quantity': quantity,
        'borrowing_date': borrowingDate,
        'expected_return_date': expectedReturnDate,
        'purpose': purpose,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      });

  Future<ApiResponse<List<dynamic>>> myBorrowings() => requestList('mobile/borrowings');

  Future<ApiResponse<Map<String, dynamic>>> cancelBorrowing(int id) =>
      request('PUT', 'mobile/borrowings/$id/cancel');

  // =========================================================================
  // RETURNS
  // =========================================================================

  Future<ApiResponse<Map<String, dynamic>>> submitReturn({
    required int borrowingId,
    String? remarks,
  }) =>
      request('POST', 'mobile/borrowings/$borrowingId/return', body: {
        if (remarks != null && remarks.isNotEmpty) 'remarks': remarks,
      });

  // =========================================================================
  // NOTIFICATIONS
  // =========================================================================

  Future<ApiResponse<List<dynamic>>> notifications() => requestList('mobile/notifications');

  Future<ApiResponse<Map<String, dynamic>>> unreadCount() =>
      request('GET', 'mobile/notifications/unread-count');

  Future<ApiResponse<Map<String, dynamic>>> markNotificationRead(int id) =>
      request('PUT', 'mobile/notifications/$id/read');

  Future<ApiResponse<Map<String, dynamic>>> markAllNotificationsRead() =>
      request('PUT', 'mobile/notifications/read-all');

  // =========================================================================
  // PROFILE
  // =========================================================================

  Future<ApiResponse<Map<String, dynamic>>> profile() => request('GET', 'mobile/profile');

  Future<ApiResponse<Map<String, dynamic>>> updateProfile({
    required String firstName,
    required String lastName,
    String? contactNumber,
  }) =>
      request('PUT', 'mobile/profile', body: {
        'first_name': firstName,
        'last_name': lastName,
        'contact_number': contactNumber,
      });

  Future<ApiResponse<Map<String, dynamic>>> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) =>
      request('PUT', 'mobile/profile/password', body: {
        'current_password': currentPassword,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });

  // =========================================================================
  // HELPERS
  // =========================================================================

  Map<String, dynamic> _parseJson(String source) {
    try {
      final decoded = jsonDecode(source);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  /// Parses a JSON array body (list endpoints). Returns an empty list when
  /// the body is not an array.
  List<dynamic> _parseList(String source) {
    try {
      final decoded = jsonDecode(source);
      return decoded is List ? decoded : <dynamic>[];
    } catch (_) {
      return <dynamic>[];
    }
  }

  String _extractErrorMessage(Map<String, dynamic> body, String fallback) {
    final msg = body['message'];
    if (msg is String && msg.isNotEmpty) {
      final errors = body['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
      }
      return msg;
    }
    return fallback;
  }
}
