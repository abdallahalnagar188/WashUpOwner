import '../../commons/models/dashboard_summary.dart';
import '../../commons/models/live_board.dart';
import '../../commons/models/order.dart';
import '../../commons/models/owner_account.dart';
import '../../commons/models/service_item.dart';
import '../enums/enums.dart';
import '../network/api_client.dart';
import '../network/token_store.dart';

/// Typed access to `/api/v1/vendor/*`. See docs/api-notes.md.
class VendorApi {
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
    int page = 1,
  }) =>
      _client.getPage(
        '/vendor/orders',
        query: {
          'view': view,
          'tab': tab,
          'branchId': branchId,
          'sort': 'scheduledAt',
          'order': view == 'bookings' ? 'asc' : 'desc',
          'page': page,
        },
        parse: OrderSummary.fromJson,
      );

  Future<OrderDetails> order(String id) async =>
      OrderDetails.fromJson(await _client.get('/vendor/orders/$id') as Map<String, dynamic>);

  Future<void> runAction(String orderId, OrderAction action, [Map<String, dynamic> fields = const {}]) =>
      _client.post('/vendor/orders/$orderId/actions', body: {'action': action.key, ...fields});

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

  /// Slot start times for a phone booking.
  Future<List<DateTime>> availability({
    required String branchId,
    required String date,
    required List<String> serviceIds,
  }) async {
    final data = await _client.get(
      '/vendor/availability',
      query: {'branchId': branchId, 'date': date, 'serviceIds': serviceIds.join(',')},
    );
    final slots = data is Map ? data['slots'] as List? ?? const [] : data as List;
    return slots
        .map((slot) => DateTime.parse((slot is Map ? slot['start'] : slot) as String))
        .toList();
  }

  /// A known customer for this plate or phone, to fill the form.
  Future<Map<String, dynamic>?> recognize({required String plate, required String phone}) async =>
      await _client.get('/vendor/recognize', query: {'plate': plate, 'phone': phone})
          as Map<String, dynamic>?;

  /// Returns the new order's id.
  Future<String> createOrder({
    required String branchId,
    required OrderSource source,
    required String plate,
    String? customerPhone,
    String? customerName,
    required List<String> serviceIds,
    DateTime? scheduledAt,
    String? notes,
  }) async {
    final data = await _client.post('/vendor/orders', body: {
      'branchId': branchId,
      'source': source.key,
      'plate': plate,
      if (customerPhone != null && customerPhone.isNotEmpty) 'customerPhone': customerPhone,
      if (customerName != null && customerName.isNotEmpty) 'customerName': customerName,
      'serviceIds': serviceIds,
      if (scheduledAt != null) 'scheduledAt': scheduledAt.toUtc().toIso8601String(),
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    }) as Map<String, dynamic>;
    return data['id'] as String;
  }

  Future<int> unreadNotifications() async {
    final reply = await _client.getRaw('/vendor/notifications', query: {'page': 1});
    return ((reply['meta'] as Map?)?['unread'] as num?)?.toInt() ?? 0;
  }
}
