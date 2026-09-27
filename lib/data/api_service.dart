import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final bool requiresEmailVerification;
  final String? unverifiedEmail;
  final Map<String, dynamic>? errors;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.requiresEmailVerification = false,
    this.unverifiedEmail,
    this.errors,
  });
}

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  /// Default API base URL.
  /// On Web or Desktop: 127.0.0.1:8000
  /// On Android Emulator: 10.0.2.2:8000
  /// Physical devices can configure this IP.
  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    }
    return 'http://10.0.2.2:8000/api';
  }

  String baseUrl = defaultBaseUrl;

  String? _authToken;
  String? get authToken => _authToken;
  void setAuthToken(String? token) => _authToken = token;

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

  // =========================================================================
  // AUTHENTICATION & GMAIL VERIFICATION
  // =========================================================================

  /// Register student and trigger verification code email.
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
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: _headers(withAuth: false),
        body: jsonEncode({
          'first_name': firstName,
          'middle_name': middleName,
          'last_name': lastName,
          'username': username,
          'email': email,
          'contact_number': contactNumber,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      final body = _parseJson(res.body);

      if (res.statusCode == 201 || res.statusCode == 200) {
        return ApiResponse(
          success: true,
          data: body,
          message: body['message'] ?? 'Registration successful. Verification code sent!',
          requiresEmailVerification: true,
          unverifiedEmail: email,
        );
      } else {
        return ApiResponse(
          success: false,
          message: _extractErrorMessage(body, 'Registration failed. Please check your inputs.'),
          errors: body['errors'] as Map<String, dynamic>?,
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Could not connect to server ($e). Please check if backend is running.',
      );
    }
  }

  /// Verify email using the 6-digit code sent via Gmail.
  Future<ApiResponse<Map<String, dynamic>>> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/verify-email'),
        headers: _headers(withAuth: false),
        body: jsonEncode({
          'email': email,
          'code': code.trim(),
        }),
      );

      final body = _parseJson(res.body);

      if (res.statusCode == 200) {
        return ApiResponse(
          success: true,
          data: body,
          message: body['message'] ?? 'Email verified successfully!',
        );
      } else {
        return ApiResponse(
          success: false,
          message: body['message'] ?? 'Verification failed. Please check the code.',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Could not connect to server ($e).',
      );
    }
  }

  /// Resend a fresh 6-digit verification code to the user's Gmail.
  Future<ApiResponse<Map<String, dynamic>>> resendVerification({
    required String email,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/resend-verification'),
        headers: _headers(withAuth: false),
        body: jsonEncode({
          'email': email,
        }),
      );

      final body = _parseJson(res.body);

      if (res.statusCode == 200) {
        return ApiResponse(
          success: true,
          data: body,
          message: body['message'] ?? 'A new verification code has been sent to your email.',
        );
      } else {
        return ApiResponse(
          success: false,
          message: body['message'] ?? 'Could not resend verification code.',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Could not connect to server ($e).',
      );
    }
  }

  /// Request password reset code sent to Gmail.
  Future<ApiResponse<Map<String, dynamic>>> forgotPassword({
    required String email,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: _headers(withAuth: false),
        body: jsonEncode({
          'email': email.trim(),
        }),
      );

      final body = _parseJson(res.body);

      if (res.statusCode == 200) {
        return ApiResponse(
          success: true,
          data: body,
          message: body['message'] ?? 'Reset code sent if the email is registered.',
        );
      } else {
        return ApiResponse(
          success: false,
          message: body['message'] ?? 'Could not process password reset.',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Could not connect to server ($e).',
      );
    }
  }

  /// Reset password using 6-digit code received via Gmail.
  Future<ApiResponse<Map<String, dynamic>>> resetPassword({
    required String email,
    required String code,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: _headers(withAuth: false),
        body: jsonEncode({
          'email': email.trim(),
          'code': code.trim(),
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      final body = _parseJson(res.body);

      if (res.statusCode == 200) {
        return ApiResponse(
          success: true,
          data: body,
          message: body['message'] ?? 'Password reset successfully! You can now log in.',
        );
      } else {
        return ApiResponse(
          success: false,
          message: _extractErrorMessage(body, 'Failed to reset password.'),
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Could not connect to server ($e).',
      );
    }
  }

  /// Student Mobile Login.
  Future<ApiResponse<Map<String, dynamic>>> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/mobile/login'),
        headers: _headers(withAuth: false),
        body: jsonEncode({
          'username': identifier.trim(),
          'password': password,
        }),
      );

      final body = _parseJson(res.body);

      if (res.statusCode == 200) {
        final token = body['token'] as String?;
        if (token != null) {
          setAuthToken(token);
        }
        return ApiResponse(
          success: true,
          data: body,
          message: body['message'] ?? 'Login successful',
        );
      } else if (res.statusCode == 403 && body['requires_email_verification'] == true) {
        return ApiResponse(
          success: false,
          message: body['message'] ?? 'Please verify your email address first.',
          requiresEmailVerification: true,
          unverifiedEmail: body['email'] ?? identifier,
        );
      } else {
        return ApiResponse(
          success: false,
          message: body['message'] ?? 'Invalid credentials.',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Connection failed ($e).',
      );
    }
  }

  // =========================================================================
  // UTILITY HELPERS
  // =========================================================================

  Map<String, dynamic> _parseJson(String source) {
    try {
      return jsonDecode(source) as Map<String, dynamic>;
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  String _extractErrorMessage(Map<String, dynamic> body, String fallback) {
    if (body['message'] is String && (body['message'] as String).isNotEmpty) {
      final msg = body['message'] as String;
      if (body['errors'] is Map) {
        final errorsMap = body['errors'] as Map;
        if (errorsMap.isNotEmpty) {
          final firstKey = errorsMap.keys.first;
          final firstVal = errorsMap[firstKey];
          if (firstVal is List && firstVal.isNotEmpty) {
            return firstVal.first.toString();
          }
        }
      }
      return msg;
    }
    return fallback;
  }
}
