import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../shared/constants/app_constants.dart';

/// AI proxy service — communicates with the Furrow AI proxy on OpenClaw VPS.
/// Follows the same constructor pattern as [WeatherService].
class AiService {
  AiService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  // JWT secret shared with the proxy server.
  // MVP trade-off: hardcoded since the proxy only gates cheap AI APIs.
  static const String _jwtSecret = 'furrow-ai-proxy-secret-2026';

  /// Send a chat message and get an AI response.
  ///
  /// Returns the AI response text, or an error string prefixed with 'Error:'.
  Future<String> sendMessage({
    required String message,
    Map<String, dynamic>? context,
    List<Map<String, String>>? history,
  }) async {
    try {
      final token = await _generateToken();

      final response = await _dio.post(
        '${AppConstants.aiProxyBaseUrl}/api/v1/chat',
        data: {
          'message': message,
          if (context != null) 'context': context,
          if (history != null) 'history': history,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          receiveTimeout: const Duration(seconds: 45),
          sendTimeout: const Duration(seconds: 15),
        ),
      );

      final data = response.data as Map<String, dynamic>;
      return data['response'] as String? ?? 'No response from AI.';
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        return 'Error: You\'ve reached the daily chat limit. Try again tomorrow!';
      }
      if (e.response?.statusCode == 403) {
        final body = e.response?.data;
        if (body is Map && body['upgrade'] == true) {
          return 'Error: Pro subscription required for AI features.';
        }
        return 'Error: Access denied.';
      }
      if (e.response?.statusCode == 503) {
        return 'Error: AI features are temporarily unavailable. Please try again later.';
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return 'Error: Request timed out. Check your internet connection.';
      }
      return 'Error: Could not reach the AI service. Check your connection.';
    } catch (_) {
      return 'Error: Something went wrong. Please try again.';
    }
  }

  /// Get daily usage stats for the current user.
  Future<Map<String, dynamic>?> getUsage() async {
    try {
      final token = await _generateToken();

      final response = await _dio.get(
        '${AppConstants.aiProxyBaseUrl}/api/v1/usage',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      return response.data as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Generate a short-lived JWT for proxy authentication.
  Future<String> _generateToken() async {
    String userId;
    bool isPro;

    try {
      final info = await Purchases.getCustomerInfo();
      userId = await Purchases.appUserID;
      isPro = info.entitlements.all['Broccoli Studios Pro']?.isActive ?? false;
    } catch (_) {
      userId = 'anonymous';
      isPro = false;
    }

    // Build JWT manually (HS256)
    final header = {'alg': 'HS256', 'typ': 'JWT'};
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final payload = {
      'userId': userId,
      'isPro': isPro,
      'iat': now,
      'exp': now + 300, // 5 minute expiry
    };

    final headerB64 = _base64UrlEncode(jsonEncode(header));
    final payloadB64 = _base64UrlEncode(jsonEncode(payload));
    final signingInput = '$headerB64.$payloadB64';

    final hmac = Hmac(sha256, utf8.encode(_jwtSecret));
    final signature = hmac.convert(utf8.encode(signingInput));
    final signatureB64 = _base64UrlEncodeBytes(signature.bytes);

    return '$signingInput.$signatureB64';
  }

  String _base64UrlEncode(String input) {
    return _base64UrlEncodeBytes(utf8.encode(input));
  }

  String _base64UrlEncodeBytes(List<int> bytes) {
    return base64Url.encode(bytes).replaceAll('=', '');
  }
}
