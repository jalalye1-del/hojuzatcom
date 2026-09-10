import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'json_parsing.dart';

typedef AccessTokenProvider = Future<String?> Function();

class ApiClient {
  ApiClient({
    required this.baseUri,
    http.Client? httpClient,
    this.accessTokenProvider,
    this.timeout = const Duration(seconds: 20),
  }) : _httpClient = httpClient ?? http.Client(),
       _ownsClient = httpClient == null;

  final Uri baseUri;
  final http.Client _httpClient;
  final bool _ownsClient;
  final AccessTokenProvider? accessTokenProvider;
  final Duration timeout;

  Future<Object?> get(
    String path, {
    Map<String, Object?> query = const {},
    bool authenticated = true,
  }) => request('GET', path, query: query, authenticated: authenticated);

  Future<Object?> post(
    String path, {
    Object? body,
    bool authenticated = true,
  }) => request('POST', path, body: body, authenticated: authenticated);

  Future<Object?> patch(
    String path, {
    Object? body,
    bool authenticated = true,
  }) => request('PATCH', path, body: body, authenticated: authenticated);

  Future<Object?> delete(
    String path, {
    Object? body,
    bool authenticated = true,
  }) => request('DELETE', path, body: body, authenticated: authenticated);

  Future<Object?> request(
    String method,
    String path, {
    Map<String, Object?> query = const {},
    Object? body,
    bool authenticated = true,
  }) async {
    final request = http.Request(method, _resolve(path, query));
    request.headers['Accept'] = 'application/json';

    if (body != null) {
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.body = jsonEncode(body);
    }

    if (authenticated) {
      final token = await accessTokenProvider?.call();
      if (token == null || token.trim().isEmpty) {
        throw const ApiException(
          message: 'انتهت الجلسة. سجل الدخول من جديد.',
          code: 'missing_access_token',
          statusCode: 401,
        );
      }
      request.headers['Authorization'] = 'Bearer ${token.trim()}';
    }

    try {
      final response = await (() async {
        final streamed = await _httpClient.send(request);
        final rawBody = await streamed.stream.bytesToString();
        return (streamed, rawBody);
      })().timeout(timeout);
      final streamed = response.$1;
      final rawBody = response.$2;
      final payload = _decode(rawBody);

      if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
        debugPrint(
          'API HTTP ERROR [$method] ${request.url} STATUS ${streamed.statusCode} BODY: $rawBody',
        );
        throw _errorFromResponse(streamed.statusCode, payload);
      }
      return payload;
    } on ApiException {
      rethrow;
    } on TimeoutException catch (error) {
      debugPrint('API TIMEOUT [$method] ${request.url}: $error');
      throw ApiException.network(error);
    } on http.ClientException catch (error) {
      debugPrint('API CLIENT ERROR [$method] ${request.url}: $error');
      throw ApiException.network(error);
    }
  }

  Uri _resolve(String path, Map<String, Object?> query) {
    final root = baseUri.path.endsWith('/')
        ? baseUri
        : baseUri.replace(path: '${baseUri.path}/');
    final normalizedPath = path.replaceFirst(RegExp(r'^/+'), '');
    final uri = root.resolve(normalizedPath);
    final values = <String, String>{
      for (final entry in query.entries)
        if (entry.value != null) entry.key: entry.value.toString(),
    };
    return values.isEmpty ? uri : uri.replace(queryParameters: values);
  }

  Object? _decode(String value) {
    if (value.trim().isEmpty) return null;
    try {
      return jsonDecode(value);
    } on FormatException {
      return value;
    }
  }

  ApiException _errorFromResponse(int statusCode, Object? payload) {
    var message = 'تعذر إكمال الطلب.';
    var code = 'http_error';
    Object? details = payload;
    if (payload is Map) {
      final json = expectJsonMap(payload);
      message = optionalString(json, 'message') ?? message;
      code = optionalString(json, 'code') ?? code;
      details = json['errors'] ?? json['details'] ?? payload;
    }
    return ApiException(
      message: message,
      code: code,
      statusCode: statusCode,
      details: details,
    );
  }

  void close() {
    if (_ownsClient) _httpClient.close();
  }
}
