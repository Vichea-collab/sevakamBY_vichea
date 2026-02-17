import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class AdminApiException implements Exception {
  final String message;
  final int? statusCode;

  const AdminApiException(this.message, {this.statusCode});

  @override
  String toString() => 'AdminApiException($statusCode): $message';
}

class AdminApiClient {
  static const Duration _requestTimeout = Duration(seconds: 25);

  final String baseUrl;
  String _bearerToken;
  final http.Client _http;

  AdminApiClient({
    required this.baseUrl,
    required String bearerToken,
    http.Client? httpClient,
  }) : _bearerToken = bearerToken.trim(),
       _http = httpClient ?? http.Client();

  void setBearerToken(String token) {
    _bearerToken = token.trim();
  }

  Future<Map<String, dynamic>> getJson(String path) async {
    return _requestJson('GET', path);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    return _requestJson('POST', path, body: body);
  }

  Future<Map<String, dynamic>> patchJson(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    return _requestJson('PATCH', path, body: body);
  }

  Future<Map<String, dynamic>> _requestJson(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = _headers();
    final upper = method.toUpperCase();
    final response = switch (upper) {
      'GET' => await _sendWithTimeout(_http.get(uri, headers: headers)),
      'POST' => await _sendWithTimeout(
        _http.post(
          uri,
          headers: headers,
          body: jsonEncode(body ?? const <String, dynamic>{}),
        ),
      ),
      'PATCH' => await _sendWithTimeout(
        _http.patch(
          uri,
          headers: headers,
          body: jsonEncode(body ?? const <String, dynamic>{}),
        ),
      ),
      _ => throw const AdminApiException('Unsupported HTTP method'),
    };
    return _decode(response);
  }

  Future<http.Response> _sendWithTimeout(Future<http.Response> request) async {
    try {
      return await request.timeout(_requestTimeout);
    } on TimeoutException {
      throw const AdminApiException(
        'Request timed out. Please retry.',
        statusCode: 408,
      );
    } on http.ClientException catch (error) {
      throw AdminApiException('Network error: ${error.message}');
    }
  }

  Map<String, String> _headers() {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (_bearerToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_bearerToken';
    }
    return headers;
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.body.isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const <String, dynamic>{'success': true, 'data': null};
      }
      throw AdminApiException(
        'Backend returned empty response',
        statusCode: response.statusCode,
      );
    }
    final parsed = jsonDecode(response.body);
    if (parsed is! Map<String, dynamic>) {
      throw AdminApiException(
        'Invalid backend response format',
        statusCode: response.statusCode,
      );
    }
    final ok = response.statusCode >= 200 && response.statusCode < 300;
    final success = parsed['success'] == true;
    if (!ok || !success) {
      throw AdminApiException(
        (parsed['message'] ?? 'Request failed').toString(),
        statusCode: response.statusCode,
      );
    }
    return parsed;
  }
}
