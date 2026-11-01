import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:washup_owner/core/network/api_client.dart';
import 'package:washup_owner/core/network/token_store.dart';

class FakeRequest {
  final String method;
  final String path;
  final Map<String, dynamic> query;
  final Map<String, dynamic>? body;
  final String? auth;

  const FakeRequest(this.method, this.path, this.query, this.body, this.auth);
}

class FakeReply {
  final int status;
  final Map<String, dynamic> body;

  const FakeReply(this.status, this.body);

  factory FakeReply.ok(Object? data, {Map<String, dynamic>? meta, Map<String, dynamic>? pagination}) =>
      FakeReply(200, {
        'status': true,
        'message': 'OK',
        'data': data,
        if (meta != null) 'meta': meta,
        if (pagination != null) 'pagination': pagination,
      });

  factory FakeReply.error(int status, String message) =>
      FakeReply(status, {'status': false, 'message': message});
}

/// Answers Dio requests from a handler and remembers them.
class FakeServer implements HttpClientAdapter {
  final FakeReply Function(FakeRequest request) handler;
  final List<FakeRequest> requests = [];

  FakeServer(this.handler);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final data = options.data;
    final request = FakeRequest(
      options.method,
      options.path,
      options.queryParameters,
      data is Map<String, dynamic> ? data : null,
      options.headers['Authorization'] as String?,
    );
    requests.add(request);
    final reply = handler(request);
    return ResponseBody.fromString(
      jsonEncode(reply.body),
      reply.status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class MemoryTokens implements TokenStore {
  String? access;
  String? refresh;

  MemoryTokens({this.access, this.refresh});

  @override
  Future<String?> accessToken() async => access;

  @override
  Future<String?> refreshToken() async => refresh;

  @override
  Future<void> save({required String accessToken, required String refreshToken}) async {
    access = accessToken;
    refresh = refreshToken;
  }

  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
  }
}

ApiClient fakeClient(FakeServer server, TokenStore tokens) {
  final dio = Dio(BaseOptions(baseUrl: ApiClient.baseUrl))..httpClientAdapter = server;
  return ApiClient(tokens: tokens, dio: dio);
}
