import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Base URL of the Laravel backend, configurable in one place.
///
/// - Physical phone over USB: 127.0.0.1 works via `adb reverse`, which
///   forwards the phone's localhost to the PC. Run once after connecting:
///   `adb reverse tcp:8000 tcp:8000 && adb reverse tcp:8080 tcp:8080`
/// - Android emulator without adb reverse: run with
///   `--dart-define=API_BASE_URL=http://10.0.2.2:8000/api`
///   (10.0.2.2 is the emulator's host-machine loopback alias).
/// - Web (flutter run -d chrome): 127.0.0.1:8000.
class ApiConfig {
  ApiConfig._();

  static String _host = '';

  static Uri? get _apiUri {
    const fromEnv = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    return fromEnv.isEmpty ? null : Uri.tryParse(fromEnv);
  }

  static String get host {
    if (_host.isNotEmpty) return _host;
    const fromEnv = String.fromEnvironment('API_HOST', defaultValue: '');
    if (fromEnv.isNotEmpty) return fromEnv;
    final api = _apiUri;
    if (api != null && api.host.isNotEmpty) return api.host;
    if (kIsWeb) return '127.0.0.1';
    // When phone is connected via laptop Wi-Fi hotspot, 192.168.137.1 connects directly
    // over Wi-Fi without needing an active adb reverse tunnel.
    return '192.168.137.1';
  }

  static set host(String val) => _host = val;

  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (fromEnv.isNotEmpty) return fromEnv;
    return 'http://$host:8000/api';
  }

  /// True when the API is reached over TLS (e.g. an https ngrok tunnel), which
  /// means Reverb must be reached over wss on port 443 by default.
  static bool get _isSecure => baseUrl.startsWith('https://');

  static String get reverbHost {
    const fromEnv = String.fromEnvironment('REVERB_HOST', defaultValue: '');
    if (fromEnv.isNotEmpty) return fromEnv;
    final api = _apiUri;
    if (api != null && api.host.isNotEmpty) return api.host;
    return host;
  }

  static int get reverbPort {
    const fromEnv = int.fromEnvironment('REVERB_PORT', defaultValue: 0);
    if (fromEnv != 0) return fromEnv;
    return _isSecure ? 443 : 8080;
  }

  static String get reverbScheme {
    const fromEnv = String.fromEnvironment('REVERB_SCHEME', defaultValue: '');
    if (fromEnv.isNotEmpty) return fromEnv;
    return _isSecure ? 'wss' : 'ws';
  }

  static const String reverbAppKey = String.fromEnvironment(
    'REVERB_APP_KEY',
    defaultValue: 'tmc-equipment-local',
  );

  /// Headers sent when loading equipment images over HTTP/HTTPS (bypasses the
  /// ngrok free-tier browser interstitial warning).
  static const Map<String, String> mediaHeaders = {
    'ngrok-skip-browser-warning': 'true',
  };

  /// Resolves a stored equipment image path (e.g. `equipment-images/abc.jpg`)
  /// into a full streaming URL on the active backend (`$baseUrl/equipment-media/abc.jpg`).
  static String? equipmentMediaUrl(String? rawPath) {
    if (rawPath == null || rawPath.trim().isEmpty) return null;
    final trimmed = rawPath.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final filename = trimmed.split('/').last;
    if (filename.isEmpty) return null;
    return '$baseUrl/equipment-media/${Uri.encodeComponent(filename)}';
  }

  /// Resolves a stored user avatar path (e.g. `user-avatars/abc.jpg`)
  /// into a full streaming URL on the active backend (`$baseUrl/user-avatar/abc.jpg`).
  static String? userAvatarUrl(String? rawPath) {
    if (rawPath == null || rawPath.trim().isEmpty) return null;
    final trimmed = rawPath.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final filename = trimmed.split('/').last;
    if (filename.isEmpty) return null;
    return '$baseUrl/user-avatar/${Uri.encodeComponent(filename)}';
  }
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

  static String get baseUrl => ApiConfig.baseUrl;

  final http.Client _client = http.Client();
  String? _authToken;
  final StreamController<String?> _tokenController =
      StreamController<String?>.broadcast();

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
      'ngrok-skip-browser-warning': 'true',
    };
    if (withAuth && _authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  Duration get _requestTimeout => (!kIsWeb && ApiConfig.host == '192.168.137.1')
      ? const Duration(seconds: 5)
      : const Duration(seconds: 12);

  Future<ApiResponse<Map<String, dynamic>>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool withAuth = true,
  }) async {
    final uri = Uri.parse('$baseUrl/$path');
    final timeout = _requestTimeout;
    try {
      final res = switch (method.toUpperCase()) {
        'POST' => await _client
            .post(uri,
                headers: _headers(withAuth: withAuth),
                body: jsonEncode(body ?? {}))
            .timeout(timeout),
        'PUT' => await _client
            .put(uri,
                headers: _headers(withAuth: withAuth),
                body: jsonEncode(body ?? {}))
            .timeout(timeout),
        'DELETE' => await _client
            .delete(uri, headers: _headers(withAuth: withAuth))
            .timeout(timeout),
        _ => await _client
            .get(uri, headers: _headers(withAuth: withAuth))
            .timeout(timeout),
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
        message: _extractErrorMessage(
            decoded, 'Request failed (${res.statusCode}).'),
        statusCode: res.statusCode,
        data: decoded.isNotEmpty ? decoded : null,
        errors: decoded['errors'] as Map<String, dynamic>?,
      );
    } on TimeoutException {
      if (!kIsWeb && ApiConfig.host == '192.168.137.1') {
        ApiConfig.host = '127.0.0.1';
        try {
          return await request(method, path, body: body, withAuth: withAuth);
        } catch (_) {}
      }
      return ApiResponse(
          success: false, message: 'The server took too long to respond.');
    } catch (e) {
      if (!kIsWeb && ApiConfig.host == '192.168.137.1') {
        ApiConfig.host = '127.0.0.1';
        try {
          return await request(method, path, body: body, withAuth: withAuth);
        } catch (_) {}
      }
      debugPrint('ApiService $method $path failed: $e');
      return ApiResponse(
          success: false,
          message: 'Could not connect to the server. Is the backend running?');
    }
  }

  /// GET an endpoint that returns a JSON array (equipment, borrowings,
  /// notifications). Kept separate from [request] so the response envelope
  /// is properly typed for list consumers.
  Future<ApiResponse<List<dynamic>>> requestList(String path) async {
    final uri = Uri.parse('$baseUrl/$path');
    try {
      final res =
          await _client.get(uri, headers: _headers()).timeout(_requestTimeout);
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
        message: _extractErrorMessage(
            decoded, 'Request failed (${res.statusCode}).'),
        statusCode: res.statusCode,
      );
    } on TimeoutException {
      if (!kIsWeb && ApiConfig.host == '192.168.137.1') {
        ApiConfig.host = '127.0.0.1';
        try {
          return await requestList(path);
        } catch (_) {}
      }
      return ApiResponse(
          success: false, message: 'The server took too long to respond.');
    } catch (e) {
      if (!kIsWeb && ApiConfig.host == '192.168.137.1') {
        ApiConfig.host = '127.0.0.1';
        try {
          return await requestList(path);
        } catch (_) {}
      }
      debugPrint('ApiService GET $path failed: $e');
      return ApiResponse(
          success: false,
          message: 'Could not connect to the server. Is the backend running?');
    }
  }

  // =========================================================================
  // AUTHENTICATION
  // =========================================================================

  /// Step 3 of registration wizard: sends a 6-digit verification code to the
  /// prospective email address before account creation.
  Future<ApiResponse<Map<String, dynamic>>> sendRegistrationCode({
    required String email,
    String? firstName,
  }) =>
      request('POST', 'register/send-code', withAuth: false, body: {
        'email': email.trim(),
        if (firstName != null && firstName.trim().isNotEmpty)
          'first_name': firstName.trim(),
      });

  /// Step 3 of registration wizard: verifies the 6-digit code sent to the
  /// prospective email address.
  Future<ApiResponse<Map<String, dynamic>>> verifyRegistrationCode({
    required String email,
    required String code,
  }) =>
      request('POST', 'register/verify-code', withAuth: false, body: {
        'email': email.trim(),
        'code': code.trim(),
      });

  /// Register student — backend creates a Pending account. If [emailVerified]
  /// is true (verified during the registration wizard), backend returns a
  /// bearer token and user payload immediately.
  Future<ApiResponse<Map<String, dynamic>>> register({
    required String firstName,
    String? middleName,
    required String lastName,
    String? idNumber,
    String? username,
    required String email,
    String? contactNumber,
    required String password,
    required String passwordConfirmation,
    bool emailVerified = false,
  }) async {
    final resolvedUsername = (username != null && username.trim().isNotEmpty)
        ? username.trim()
        : firstName.trim();
    final res = await request('POST', 'register', withAuth: false, body: {
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      if (idNumber != null && idNumber.isNotEmpty) 'id_number': idNumber,
      'username': resolvedUsername,
      'email': email,
      'contact_number': contactNumber,
      'password': password,
      'password_confirmation': passwordConfirmation,
      if (emailVerified) 'email_verified': true,
    });
    if (res.success) {
      final needsVerify =
          res.data?['requires_email_verification'] as bool? ?? !emailVerified;
      return ApiResponse(
        success: true,
        data: res.data,
        message: res.message ?? 'Registration successful.',
        statusCode: res.statusCode,
        requiresEmailVerification: needsVerify,
        unverifiedEmail: needsVerify ? email : null,
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
  Future<ApiResponse<Map<String, dynamic>>> resendVerification(
          {required String email}) =>
      request('POST', 'resend-verification',
          withAuth: false, body: {'email': email});

  /// Request a 6-digit password reset code.
  Future<ApiResponse<Map<String, dynamic>>> forgotPassword(
          {required String email}) =>
      request('POST', 'forgot-password',
          withAuth: false, body: {'email': email.trim()});

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

  /// Submits a ban appeal. Banned users cannot authenticate (their tokens are
  /// revoked), so the account is identified by username/email instead — this
  /// call is intentionally unauthenticated.
  Future<ApiResponse<Map<String, dynamic>>> submitAppeal({
    required String login,
    required String message,
  }) =>
      request('POST', 'appeals', withAuth: false, body: {
        'login': login.trim(),
        'message': message.trim(),
      });

  // =========================================================================
  // EQUIPMENT
  // =========================================================================

  Future<ApiResponse<List<dynamic>>> equipmentList() =>
      requestList('mobile/equipment');

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

  Future<ApiResponse<List<dynamic>>> myBorrowings() =>
      requestList('mobile/borrowings');

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

  Future<ApiResponse<List<dynamic>>> notifications() =>
      requestList('mobile/notifications');

  Future<ApiResponse<Map<String, dynamic>>> unreadCount() =>
      request('GET', 'mobile/notifications/unread-count');

  Future<ApiResponse<Map<String, dynamic>>> markNotificationRead(int id) =>
      request('PUT', 'mobile/notifications/$id/read');

  Future<ApiResponse<Map<String, dynamic>>> markAllNotificationsRead() =>
      request('PUT', 'mobile/notifications/read-all');

  // =========================================================================
  // ID VERIFICATION
  // =========================================================================

  /// Upload front/back ID photos to the backend (multipart). Photos land on
  /// the server's PRIVATE disk and are reviewed by an administrator — the
  /// submission itself does not verify the account.
  Future<ApiResponse<Map<String, dynamic>>> submitIdVerification({
    required String idFrontPath,
    required String idBackPath,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/id-verification');
      final req = http.MultipartRequest('POST', uri)
        ..headers.addAll(_headers())
        ..files.add(await http.MultipartFile.fromPath('id_front', idFrontPath))
        ..files.add(await http.MultipartFile.fromPath('id_back', idBackPath));

      final streamed = await req.send().timeout(const Duration(seconds: 60));
      final body = await streamed.stream.bytesToString();
      final decoded = _parseJson(body);
      final ok = streamed.statusCode >= 200 && streamed.statusCode < 300;

      return ApiResponse(
        success: ok,
        data: decoded.isNotEmpty ? decoded : null,
        message: ok
            ? (decoded['message'] as String? ?? 'ID photos submitted.')
            : _extractErrorMessage(
                decoded, 'Upload failed (${streamed.statusCode}).'),
        statusCode: streamed.statusCode,
      );
    } on TimeoutException {
      return ApiResponse(
          success: false, message: 'The upload took too long. Try again.');
    } catch (e) {
      debugPrint('ApiService submitIdVerification failed: $e');
      return ApiResponse(
          success: false,
          message: 'Could not upload ID photos. Is the backend running?');
    }
  }

  // =========================================================================
  // PROFILE
  // =========================================================================

  Future<ApiResponse<Map<String, dynamic>>> profile() =>
      request('GET', 'mobile/profile');

  Future<ApiResponse<Map<String, dynamic>>> updateProfile({
    required String firstName,
    required String lastName,
    String? idNumber,
    String? contactNumber,
    String? avatarPath,
    bool removeAvatar = false,
  }) async {
    if (avatarPath != null && avatarPath.isNotEmpty) {
      try {
        final uri = Uri.parse('$baseUrl/mobile/profile');
        final req = http.MultipartRequest('POST', uri)
          ..headers.addAll(_headers())
          ..fields['first_name'] = firstName
          ..fields['last_name'] = lastName
          ..files.add(await http.MultipartFile.fromPath('avatar', avatarPath));
        if (idNumber != null && idNumber.isNotEmpty) {
          req.fields['id_number'] = idNumber;
        }
        if (contactNumber != null) {
          req.fields['contact_number'] = contactNumber;
        }
        final streamed = await req.send().timeout(const Duration(seconds: 40));
        final body = await streamed.stream.bytesToString();
        final decoded = _parseJson(body);
        final ok = streamed.statusCode >= 200 && streamed.statusCode < 300;
        return ApiResponse(
          success: ok,
          data: decoded.isNotEmpty ? decoded : null,
          message: ok
              ? (decoded['message'] as String?)
              : _extractErrorMessage(
                  decoded, 'Profile update failed (${streamed.statusCode}).'),
          statusCode: streamed.statusCode,
        );
      } catch (e) {
        return ApiResponse(
          success: false,
          message: 'Could not upload profile photo.',
        );
      }
    }

    return request('PUT', 'mobile/profile', body: {
      'first_name': firstName,
      'last_name': lastName,
      if (idNumber != null && idNumber.isNotEmpty) 'id_number': idNumber,
      'contact_number': contactNumber,
      if (removeAvatar) 'remove_avatar': true,
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> updateAvatar(
      String avatarPath) async {
    try {
      final uri = Uri.parse('$baseUrl/mobile/profile/avatar');
      final req = http.MultipartRequest('POST', uri)
        ..headers.addAll(_headers())
        ..files.add(await http.MultipartFile.fromPath('avatar', avatarPath));
      final streamed = await req.send().timeout(const Duration(seconds: 40));
      final body = await streamed.stream.bytesToString();
      final decoded = _parseJson(body);
      final ok = streamed.statusCode >= 200 && streamed.statusCode < 300;
      return ApiResponse(
        success: ok,
        data: decoded.isNotEmpty ? decoded : null,
        message: ok
            ? (decoded['message'] as String?)
            : _extractErrorMessage(decoded, 'Could not upload profile photo.'),
        statusCode: streamed.statusCode,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Could not upload profile photo.',
      );
    }
  }

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

  Future<ApiResponse<Map<String, dynamic>>> fetchMobileSettings() =>
      request('GET', 'mobile/settings');

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
