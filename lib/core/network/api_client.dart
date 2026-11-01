import 'dart:async';

import 'package:dio/dio.dart';
import 'package:get/get.dart';

import 'token_store.dart';

class ApiException implements Exception {
  /// Text from the server, already in Arabic, or a translated fallback.
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiPage<T> {
  final List<T> items;
  final int total;
  final bool hasNext;
  final Map<String, dynamic> meta;

  const ApiPage({
    required this.items,
    required this.total,
    required this.hasNext,
    required this.meta,
  });
}

/// HTTP for `/api/v1`. Sends the access token, refreshes it once on 401 with a
/// single shared refresh, and unwraps `{status, message, data}`.
class ApiClient {
  static const String baseUrl = 'https://washup-vendor.vercel.app/api/v1';

  final Dio _dio;
  final TokenStore _tokens;

  /// Runs when the refresh token is refused: the user has to sign in again.
  void Function()? onSessionExpired;

  Future<String?>? _refreshing;

  ApiClient({required TokenStore tokens, Dio? dio})
      : _tokens = tokens,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 20),
                headers: const {'Accept': 'application/json'},
              ),
            );

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async =>
      (await _send('GET', path, query: query))['data'];

  Future<dynamic> post(String path, {Object? body}) async =>
      (await _send('POST', path, body: body))['data'];

  Future<dynamic> patch(String path, {Object? body}) async =>
      (await _send('PATCH', path, body: body))['data'];

  Future<dynamic> put(String path, {Object? body}) async =>
      (await _send('PUT', path, body: body))['data'];

  Future<dynamic> delete(String path) async => (await _send('DELETE', path))['data'];

  /// The whole reply, for lists that carry `meta` with their `data`.
  Future<Map<String, dynamic>> getRaw(String path, {Map<String, dynamic>? query}) =>
      _send('GET', path, query: query);

  Future<ApiPage<T>> getPage<T>(
    String path, {
    Map<String, dynamic>? query,
    required T Function(Map<String, dynamic>) parse,
  }) async {
    final reply = await _send('GET', path, query: query);
    final pagination = reply['pagination'] as Map<String, dynamic>? ?? const {};
    return ApiPage(
      items: (reply['data'] as List? ?? const [])
          .map((item) => parse(item as Map<String, dynamic>))
          .toList(),
      total: (pagination['total'] as num?)?.toInt() ?? 0,
      hasNext: pagination['has_next'] == true,
      meta: reply['meta'] as Map<String, dynamic>? ?? const {},
    );
  }

  /// Leaves out empty values and `all`, as the dashboard does.
  static Map<String, dynamic> _clean(Map<String, dynamic>? query) => {
        for (final entry in (query ?? const <String, dynamic>{}).entries)
          if (entry.value != null && entry.value != '' && entry.value != 'all')
            entry.key: entry.value,
      };

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
  }) async {
    try {
      return await _request(method, path, query: query, body: body);
    } on DioException catch (error) {
      if (error.response?.statusCode == 401 && !path.contains('/auth/')) {
        final token = await _refresh();
        if (token != null) {
          try {
            return await _request(method, path, query: query, body: body);
          } on DioException catch (retryError) {
            throw _toApiException(retryError);
          }
        }
        throw ApiException('error.session'.tr, statusCode: 401);
      }
      throw _toApiException(error);
    }
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
  }) async {
    final token = await _tokens.accessToken();
    final response = await _dio.request<dynamic>(
      path,
      data: body,
      queryParameters: _clean(query),
      options: Options(
        method: method,
        contentType: 'application/json',
        headers: token == null ? null : {'Authorization': 'Bearer $token'},
      ),
    );
    final reply = response.data;
    if (reply is Map<String, dynamic>) {
      if (reply['status'] == false) {
        throw ApiException(reply['message']?.toString() ?? 'error.body'.tr);
      }
      return reply;
    }
    throw ApiException('error.body'.tr);
  }

  /// Every caller that hits 401 at the same moment waits on the same refresh,
  /// because the server may retire a refresh token once it is used.
  Future<String?> _refresh() => _refreshing ??= _runRefresh().whenComplete(() => _refreshing = null);

  Future<String?> _runRefresh() async {
    final refreshToken = await _tokens.refreshToken();
    if (refreshToken == null) {
      onSessionExpired?.call();
      return null;
    }
    try {
      final reply = await _request('POST', '/vendor/auth/refresh', body: {'refresh_token': refreshToken});
      final data = reply['data'] as Map<String, dynamic>;
      await _tokens.save(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String? ?? refreshToken,
      );
      return data['access_token'] as String;
    } on DioException catch (error) {
      // No answer at all (offline) keeps the session; a refusal ends it.
      if (error.response != null) onSessionExpired?.call();
      return null;
    } on ApiException {
      onSessionExpired?.call();
      return null;
    }
  }

  ApiException _toApiException(DioException error) {
    final reply = error.response?.data;
    final message = reply is Map ? reply['message']?.toString() : null;
    if (message != null && message.isNotEmpty) {
      return ApiException(message, statusCode: error.response?.statusCode);
    }
    final offline = error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout;
    return ApiException(
      (offline ? 'error.offline' : 'error.body').tr,
      statusCode: error.response?.statusCode,
    );
  }
}
