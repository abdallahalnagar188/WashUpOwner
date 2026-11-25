import 'dart:io';

import '../../commons/models/dashboard_summary.dart';
import '../../commons/models/live_board.dart';
import '../../commons/models/order.dart';
import '../../commons/models/owner_account.dart';
import '../../commons/models/search_result.dart';
import '../../commons/models/service_item.dart';
import '../enums/enums.dart';
import '../network/api_client.dart';
import '../network/token_store.dart';

/// Typed access to `/api/v1/vendor/*`. See docs/api-notes.md.
class VendorApi {
  /// Sent with the push token so the server can tell app builds apart.
  static const String appVersion = '1.0.0';

  final ApiClient _client;
  final TokenStore _tokens;

  VendorApi(this._client, this._tokens);

  ApiClient get client => _client;

  Future<OwnerAccount> login({required String phone, required String password}) async {
    final data = await _client.post('/vendor/auth/login', body: {'phone': phone, 'password': password})
        as Map<String, dynamic>;
    await _tokens.save(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
    );
    return OwnerAccount.fromJson(data['account'] as Map<String, dynamic>);
  }

  Future<OwnerAccount> me() async =>
      OwnerAccount.fromJson(await _client.get('/vendor/auth/me') as Map<String, dynamic>);

  /// Ends the session here even when the server cannot be reached.
  Future<void> logout() async {
    try {
      await _client.post('/vendor/auth/logout');
    } on ApiException {
      // Tokens below are what actually signs this device out.
    } finally {
      await _tokens.clear();
    }
  }

  /// Changes the signed-in account's password (GAP-044). The server wants at
  /// least 8 characters and checks the current one. Returns its outcome text.
  Future<String?> changePassword({required String currentPassword, required String newPassword}) async {
    // Renews an expired access token first (auth/me refreshes on 401), because
    // change-password answers 401 for a wrong current password as well.
    await _client.get('/vendor/auth/me');
    return ApiClient.outcome(await _client.postRaw('/vendor/auth/change-password', body: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    }));
  }

  /// Asks for a reset link (GAP-044). The server gives the same answer whether
  /// or not the number has an account; the link opens the partner web portal.
  Future<String?> forgotPassword({required String phone}) async =>
      ApiClient.outcome(await _client.postRaw('/vendor/auth/forgot-password', body: {'phone': phone}));

  Future<DashboardSummary> dashboard({required DashboardPeriod period, required String branchId}) async =>
      DashboardSummary.fromJson(
        await _client.get('/vendor/dashboard', query: {'period': period.apiValue, 'branchId': branchId})
            as Map<String, dynamic>,
      );

  Future<LiveBoard> live({required String branchId}) async => LiveBoard.fromJson(
        await _client.get('/vendor/live', query: {'branchId': branchId}) as Map<String, dynamic>,
      );

  Future<ApiPage<OrderSummary>> orders({
    required String view,
    required String tab,
    required String branchId,
    String source = 'all',
    int page = 1,
  }) =>
      _client.getPage(
        '/vendor/orders',
        query: {
          'view': view,
          'tab': tab,
          'branchId': branchId,
          // GAP-084; "all" is left out by the client.
          'source': source,
          'sort': 'scheduledAt',
          'order': view == 'bookings' ? 'asc' : 'desc',
          'page': page,
        },
        parse: OrderSummary.fromJson,
      );

  Future<OrderDetails> order(String id) async =>
      OrderDetails.fromJson(await _client.get('/vendor/orders/$id') as Map<String, dynamic>);

  /// Returns the server's outcome text, like the change due after a cash payment.
  Future<String?> runAction(String orderId, OrderAction action, [Map<String, dynamic> fields = const {}]) async =>
      ApiClient.outcome(
        await _client.postRaw('/vendor/orders/$orderId/actions', body: {'action': action.key, ...fields}),
      );

  /// Confirms several pending bookings at once. Returns the server's outcome text.
  Future<String?> bulkConfirm(List<String> ids) async =>
      ApiClient.outcome(await _client.postRaw('/vendor/orders/bulk-confirm', body: {'ids': ids}));

  Future<List<ServiceItem>> services({required String branchId}) async {
    final data = await _client.get('/vendor/services', query: {'branchId': branchId}) as List;
    return data.map((s) => ServiceItem.fromJson(s as Map<String, dynamic>)).toList();
  }

  Future<num?> pricePreview({required String branchId, required List<String> serviceIds}) async {
    final data = await _client.get(
      '/vendor/price-preview',
      query: {'branchId': branchId, 'serviceIds': serviceIds.join(',')},
    ) as Map<String, dynamic>;
    return data['total'] as num?;
  }

  /// Start times a phone booking can use.
  Future<List<DateTime>> availability({
    required String branchId,
    required String date,
    required List<String> serviceIds,
  }) async {
    final data = await _client.get(
      '/vendor/availability',
      query: {'branchId': branchId, 'date': date, 'serviceIds': serviceIds.join(',')},
    );
    // The reply lists every slot of the day, so keep the ones that can be booked.
    return (data as List)
        .cast<Map<String, dynamic>>()
        .where((slot) => slot['past'] != true && slot['blocked'] != true && (slot['free'] as num? ?? 0) > 0)
        .map((slot) => DateTime.parse(slot['start'] as String))
        .toList();
  }

  /// A known customer for this plate or phone, to fill the form.
  Future<Map<String, dynamic>?> recognize({required String plate, required String phone}) async =>
      await _client.get('/vendor/recognize', query: {'plate': plate, 'phone': phone})
          as Map<String, dynamic>?;

  /// Returns the new order's id and the server's outcome text (it adds the
  /// expected wait when every bay is busy).
  Future<({String id, String? message})> createOrder({
    required String branchId,
    required OrderSource source,
    required String plate,
    String? customerPhone,
    String? customerName,
    required List<String> serviceIds,
    DateTime? scheduledAt,
    String? notes,
  }) async {
    final reply = await _client.postRaw('/vendor/orders', body: {
      'branchId': branchId,
      'source': source.key,
      'plate': plate,
      if (customerPhone != null && customerPhone.isNotEmpty) 'customerPhone': customerPhone,
      if (customerName != null && customerName.isNotEmpty) 'customerName': customerName,
      'serviceIds': serviceIds,
      if (scheduledAt != null) 'scheduledAt': scheduledAt.toUtc().toIso8601String(),
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    final data = reply['data'] as Map<String, dynamic>;
    return (id: data['id'] as String, message: ApiClient.outcome(reply));
  }

  Future<void> registerPush({required String token}) => _client.post('/vendor/push/register', body: {
        'token': token,
        'appVersion': appVersion,
        'platform': Platform.isIOS ? 'ios' : 'android',
      });

  Future<void> unregisterPush({required String token}) =>
      _client.post('/vendor/push/unregister', body: {'token': token});

  /// Finds orders and customers by plate, phone, name or order number.
  Future<List<SearchResult>> search(String query) async {
    final data = await _client.get('/vendor/search', query: {'q': query}) as Map<String, dynamic>;
    return (data['results'] as List? ?? const [])
        .map((result) => SearchResult.fromJson(result as Map<String, dynamic>))
        .toList();
  }

  Future<int> unreadNotifications() async {
    // One row is enough: the count is in `meta` (GAP-099).
    final reply = await _client.getRaw('/vendor/notifications', query: {'page': 1, 'per_page': 1});
    return ((reply['meta'] as Map?)?['unread'] as num?)?.toInt() ?? 0;
  }
}
