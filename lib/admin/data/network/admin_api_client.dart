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
    final uri = Uri.parse('$baseUrl$path');
    final response = await _http
        .get(uri, headers: _headers())
        .timeout(const Duration(seconds: 8));
    return _decode(response);
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
