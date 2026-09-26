import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'supabase_service.dart';

class BackendException implements Exception {
  final int status;
  final Map<String, dynamic> data;
  BackendException(this.status, this.data);
  @override
  String toString() => data['error']?.toString() ?? 'Request failed ($status)';
}

class BackendService {
  static String? sessionId;
  static http.Client transport = http.Client();
  static Uri? baseUriOverride;

  static Uri uri(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Uri.parse(path);
    }
    if (baseUriOverride != null) return baseUriOverride!.resolve(path);
    const base = String.fromEnvironment('BACKEND_URL');
    if (base.isNotEmpty) return Uri.parse(base).resolve(path);

    // If running in browser:
    if (Uri.base.scheme.startsWith('http')) {
      // If we are served directly from port 8082, use same origin
      if (Uri.base.port == 8082) {
        return Uri.base.resolve(path);
      }
      // If served from Flutter dev server (e.g. localhost:50000+), point to backend at port 8082
      final host = Uri.base.host.isNotEmpty ? Uri.base.host : '127.0.0.1';
      return Uri.parse('http://$host:8082').resolve(path);
    }
    return Uri.parse('http://127.0.0.1:8082').resolve(path);
  }

  static Future<Map<String, dynamic>> request(
    String path, [
    Map<String, dynamic>? body,
    Duration timeout = const Duration(seconds: 35),
  ]) async {
    final token =
        SupabaseService.instance.client?.auth.currentSession?.accessToken;
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    late final http.Response response;
    try {
      response =
          await (body == null
                  ? transport.get(uri(path), headers: headers)
                  : transport.post(
                      uri(path),
                      headers: headers,
                      body: jsonEncode(body),
                    ))
              .timeout(timeout);
    } on TimeoutException {
      throw BackendException(0, {
        'error': 'The server took too long to respond. Please retry.',
      });
    } on http.ClientException {
      throw BackendException(0, {
        'error': 'Could not reach the server. Check your connection and retry.',
      });
    }

    final raw = response.body.trim();
    if (raw.isEmpty) {
      if (response.statusCode >= 400) {
        throw BackendException(response.statusCode, {
          'error': 'Request failed (${response.statusCode}).',
        });
      }
      return <String, dynamic>{};
    }
    if (raw.startsWith('<')) {
      throw BackendException(response.statusCode, {
        'error':
            'Server returned HTML instead of JSON. Ensure local backend is running on port 8082.',
      });
    }

    try {
      final decoded = jsonDecode(raw);
      final value = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'data': decoded};
      if (response.statusCode >= 400) {
        throw BackendException(response.statusCode, value);
      }
      return value;
    } on FormatException {
      throw BackendException(response.statusCode, {
        'error': 'Invalid JSON response from server.',
      });
    }
  }
}
