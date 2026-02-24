import 'dart:convert';
import 'package:http/http.dart' as http;

class BackendApiException implements Exception {
  final String message;
  final int? statusCode;

  const BackendApiException(this.message, {this.statusCode});

  @override
  String toString() => 'BackendApiException($statusCode): $message';
}

class BackendApiClient {
  final String baseUrl;
  String _bearerToken;
  final http.Client _http;

  BackendApiClient({
    required this.baseUrl,
    required String bearerToken,
    http.Client? httpClient,
  }) : _bearerToken = bearerToken,
       _http = httpClient ?? http.Client();

  String get bearerToken => _bearerToken;

  void setBearerToken(String token) {
    _bearerToken = token.trim();
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Duration timeout = const Duration(seconds: 6),
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _http.get(uri, headers: _headers()).timeout(timeout);
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> putJson(
    String path,
    Map<String, dynamic> body, {
    Duration timeout = const Duration(seconds: 6),
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _http
        .put(uri, headers: _headers(), body: jsonEncode(body))
        .timeout(timeout);
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body, {
    Duration timeout = const Duration(seconds: 6),
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _http
        .post(uri, headers: _headers(), body: jsonEncode(body))
        .timeout(timeout);
    return _decodeResponse(response);
  }

  Map<String, String> _headers() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_bearerToken.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${_bearerToken.trim()}';
    }
    return headers;
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.body.isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return const <String, dynamic>{'success': true, 'data': null};
      }
      throw BackendApiException(
        'Backend returned empty response',
        statusCode: response.statusCode,
      );
    }

    final parsed = jsonDecode(response.body);
    if (parsed is! Map<String, dynamic>) {
      throw BackendApiException(
        'Invalid backend response format',
        statusCode: response.statusCode,
      );
    }

    final ok = response.statusCode >= 200 && response.statusCode < 300;
    final success = parsed['success'] == true;
    if (!ok || !success) {
      throw BackendApiException(
        (parsed['message'] ?? 'Backend request failed').toString(),
        statusCode: response.statusCode,
      );
    }
    return parsed;
  }
}
