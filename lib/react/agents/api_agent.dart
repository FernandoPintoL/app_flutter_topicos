import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/env_config.dart';

class ApiAgent {
  static String? _baseUrl;
  static String? _token;

  static const String _authorizationHeader = 'Authorization';
  static const String _contentTypeHeader = 'Content-Type';
  static const Duration _defaultTimeout = Duration(seconds: 30);

  static Future<void> initialize() async {
    _baseUrl ??= EnvConfig.businessApiUrl;
  }

  static Future<Map<String, dynamic>> request(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      await initialize();
      final url = Uri.parse('$_baseUrl$endpoint');
      final headers = <String, String>{
        _contentTypeHeader: 'application/json',
      };

      if (_token != null) {
        headers[_authorizationHeader] = 'Bearer $_token';
      }

      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http
              .get(url, headers: headers)
              .timeout(_defaultTimeout);
          break;
        case 'POST':
          response = await http
              .post(
                url,
                headers: headers,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(_defaultTimeout);
          break;
        case 'PUT':
          response = await http
              .put(
                url,
                headers: headers,
                body: body != null ? jsonEncode(body) : null,
              )
              .timeout(_defaultTimeout);
          break;
        case 'DELETE':
          response = await http
              .delete(url, headers: headers)
              .timeout(_defaultTimeout);
          break;
        default:
          return {
            'success': false,
            'error': 'Método HTTP no soportado: $method',
          };
      }

      if (response.statusCode == 401) {
        clearToken();
        return {
          'success': false,
          'error': 'No autorizado (401)',
        };
      }

      final decoded = jsonDecode(response.body);

      if (response.statusCode >= 400) {
        if (decoded is Map<String, dynamic>) {
          return {
            'success': false,
            'error': decoded['error'] ?? 'Error HTTP ${response.statusCode}',
            ...decoded,
          };
        } else {
          return {
            'success': false,
            'error': 'Error HTTP ${response.statusCode}',
          };
        }
      }

      if (decoded is Map<String, dynamic>) {
        return decoded;
      } else if (decoded is List) {
        return {
          'success': true,
          'data': decoded,
        };
      } else {
        return {
          'success': true,
          'data': decoded,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> login(
    String emailOrUsername,
    String password,
  ) async {
    final response = await request(
      'POST',
      '/auth/login',
      body: {
        'email_or_username': emailOrUsername,
        'password': password,
        'platform': 'mobile',
      },
    );

    if (response['token'] != null) {
      setToken(response['token'] as String);
    }

    return response;
  }

  static void setToken(String token) {
    _token = token;
  }

  static String? getToken() {
    return _token;
  }

  static void clearToken() {
    _token = null;
  }
}
