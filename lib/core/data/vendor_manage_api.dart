import '../../commons/models/app_notification.dart';
import '../../commons/models/audit_entry.dart';
import '../../commons/models/business_settings.dart';
import '../../commons/models/customer.dart';
import '../../commons/models/day_closing.dart';
import '../../commons/models/finance_summary.dart';
import '../../commons/models/json_read.dart';
import '../../commons/models/managed_branch.dart';
import '../../commons/models/managed_service.dart';
import '../../commons/models/offer.dart';
import '../../commons/models/review.dart';
import '../../commons/models/schedule_day.dart';
import '../../commons/models/shift.dart';
import '../../commons/models/staff_member.dart';
import '../../commons/models/vendor_report.dart';
import '../network/api_client.dart';

/// The management half of `/api/v1/vendor/*`. Write bodies match what the
/// dashboard's forms send.
class VendorManageApi {
  final ApiClient _client;

  VendorManageApi(this._client);

  // Notifications

  Future<ApiPage<AppNotification>> notifications({String filter = 'all', int page = 1}) =>
      _client.getPage(
        '/vendor/notifications',
        query: {'filter': filter, 'page': page},
        parse: AppNotification.fromJson,
      );

  Future<void> markNotificationRead(String id) => _client.post('/vendor/notifications/$id/read');

  Future<void> markAllNotificationsRead() => _client.post('/vendor/notifications/read-all');

  // Schedule

  Future<ScheduleDay> schedule({required String branchId, required String date}) async =>
      ScheduleDay.fromJson(
        readMap(await _client.get('/vendor/schedule', query: {'branchId': branchId, 'date': date})),
      );

  Future<void> blockSlot({
    required String branchId,
    required String start,
    required String end,
    required String reason,
  }) =>
      _client.post('/vendor/schedule/blocks', body: {
        'branchId': branchId,
        'start': start,
        'end': end,
        'reason': reason,
      });

  Future<void> removeBlock(String id) => _client.delete('/vendor/schedule/blocks/$id');

  // Services

  Future<ServiceList> services({required String branchId}) async => ServiceList.fromReply(
        await _client.getRaw('/vendor/services', query: {'branchId': branchId}),
      );

  /// Creates the service when [id] is null.
  Future<void> saveService({String? id, required Map<String, dynamic> payload}) => id == null
      ? _client.post('/vendor/services', body: payload)
      : _client.patch('/vendor/services/$id', body: payload);

  /// The body of a service form. [reason] goes along only with a price change.
  static Map<String, dynamic> servicePayload({
    required String branchId,
    required String nameAr,
    required String nameEn,
    required String descriptionAr,
    required String descriptionEn,
    required String category,
    required String type,
    required num price,
    required num durationMin,
    required bool active,
    String? reason,
  }) =>
      {
        'branchId': branchId,
        'name': {'ar': nameAr, 'en': nameEn},
        'description': {'ar': descriptionAr, 'en': descriptionEn},
        'category': category,
        'type': type,
        'price': price,
        'durationMin': durationMin,
        'active': active,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      };

  // Offers

  Future<OfferList> offers({required String branchId}) async => OfferList.fromReply(
        await _client.getRaw('/vendor/offers', query: {'branchId': branchId}),
      );

  /// Creates the offer when [id] is null.
  Future<void> saveOffer({String? id, required Map<String, dynamic> payload}) => id == null
      ? _client.post('/vendor/offers', body: payload)
      : _client.patch('/vendor/offers/$id', body: payload);

  /// The body of an offer form. English falls back to Arabic, as on the
  /// dashboard. [publish] false keeps a new offer as a draft.
  static Map<String, dynamic> offerPayload({
    required String titleAr,
    required String titleEn,
    required String descriptionAr,
    required String descriptionEn,
    required String discountType,
    required num discountValue,
    required DateTime startAt,
    required DateTime endAt,
    required List<String> branchIds,
    required List<String> serviceCategories,
    required bool publish,
  }) =>
      {
        'title': {'ar': titleAr, 'en': titleEn.isEmpty ? titleAr : titleEn},
        'description': {'ar': descriptionAr, 'en': descriptionEn},
        'discountType': discountType,
        'discountValue': discountValue,
        'startAt': startAt.toUtc().toIso8601String(),
        'endAt': endAt.toUtc().toIso8601String(),
        'branchIds': branchIds,
        'serviceCategories': serviceCategories,
        'publish': publish,
      };

  Future<void> setOfferEnabled(String id, bool enabled) =>
      _client.post('/vendor/offers/$id/status', body: {'enabled': enabled});

  // Staff

  Future<StaffList> staff({required String branchId, String period = '30d'}) async =>
      StaffList.fromReply(
        await _client.getRaw('/vendor/staff', query: {'branchId': branchId, 'period': period}),
      );

  /// Returns the new account's temporary password. The server only gives it
  /// inside the reply's `message`, and only this once.
  Future<String?> createStaff({
    required String name,
    required String phone,
    required String role,
    required String branchId,
    required num maxDiscountPct,
    required Map<String, bool> permissions,
  }) async {
    final reply = await _client.postRaw('/vendor/staff', body: {
      'name': name,
      'phone': phone,
      'role': role,
      'branchId': branchId,
      'maxDiscountPct': maxDiscountPct,
      'permissions': permissions,
    });
    final data = reply['data'];
    final given = data is Map ? data['tempPassword']?.toString() : null;
    if (given != null && given.isNotEmpty) return given;
    // Older servers only put it in the message: "كلمة المرور المؤقتة: XXXX (…)".
    return RegExp(r'المؤقتة\s*:?\s*([^\s(]+)').firstMatch(reply['message']?.toString() ?? '')?.group(1);
  }

  Future<void> updateStaff(
    String id, {
    required String role,
    required String branchId,
    required num maxDiscountPct,
    required Map<String, bool> permissions,
    required String reason,
  }) =>
      _client.patch('/vendor/staff/$id', body: {
        'role': role,
        'branchId': branchId,
        'maxDiscountPct': maxDiscountPct,
        'permissions': permissions,
        'reason': reason,
      });

  Future<void> setStaffActive(String id, {required bool active, required String reason}) =>
      _client.post('/vendor/staff/$id/status', body: {'active': active, 'reason': reason});

  Future<void> updateStaffSchedule(String id, List<ShiftPattern> shifts) => _client.put(
        '/vendor/staff/$id/schedule',
        body: {'shifts': shifts.map((shift) => shift.toJson()).toList()},
      );

  // Shifts and day closing

  Future<ApiPage<Shift>> shifts({
    required String branchId,
    required String filter,
    int page = 1,
  }) =>
      _client.getPage(
        '/vendor/shifts',
        query: {'branchId': branchId, 'filter': filter, 'page': page},
        parse: Shift.fromJson,
      );

  Future<ShiftDetails> shift(String id) async =>
      ShiftDetails.fromJson(readMap(await _client.get('/vendor/shifts/$id')));

  /// [status] is `reviewed` or `flagged`.
  Future<void> reviewShift(String id, {required String status, required String note}) =>
      _client.post('/vendor/shifts/$id/review', body: {'status': status, 'note': note});

  Future<DayClosing> dayClosing({required String branchId, required String date}) async =>
      DayClosing.fromJson(
        readMap(await _client.get('/vendor/day-closing', query: {'branchId': branchId, 'date': date})),
      );

  Future<void> closeDay({
    required String branchId,
    required String date,
    required num cash,
    required num card,
    required num online,
    String? reason,
  }) =>
      _client.post('/vendor/day-closing', body: {
        'branchId': branchId,
        'date': date,
        'actual': {'cash': cash, 'card': card, 'online': online},
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });

  // Customers

  Future<ApiPage<Customer>> customers({
    required String branchId,
    required String segment,
    int page = 1,
  }) =>
      _client.getPage(
        '/vendor/customers',
        query: {'branchId': branchId, 'segment': segment, 'page': page},
        parse: Customer.fromJson,
      );

  Future<CustomerDetails> customer(String id) async =>
      CustomerDetails.fromJson(readMap(await _client.get('/vendor/customers/$id')));

  // Reviews

  Future<ApiPage<Review>> reviews({required String branchId, int page = 1}) => _client.getPage(
        '/vendor/reviews',
        query: {'branchId': branchId, 'page': page},
        parse: Review.fromJson,
      );

  Future<void> replyToReview(String id, String text) =>
      _client.post('/vendor/reviews/$id/reply', body: {'text': text});

  Future<void> reportReview(String id, String reason) =>
      _client.post('/vendor/reviews/$id/report', body: {'reason': reason});

  // Reports and finance

  /// [type] is the server's own value: `source` and `employees` are the
  /// sources and staff reports. Any other value silently returns `orders`.
  Future<VendorReport> report({
    required String type,
    required String branchId,
    required String from,
    required String to,
  }) async =>
      VendorReport.fromJson(readMap(await _client.get(
        '/vendor/reports',
        query: {'type': type, 'branchId': branchId, 'from': from, 'to': to},
      )));

  Future<FinanceSummary> finance({required String branchId, required String period}) async =>
      FinanceSummary.fromJson(
        readMap(await _client.get('/vendor/finance', query: {'branchId': branchId, 'period': period})),
      );

  // Branches

  Future<List<ManagedBranch>> branches() async {
    final data = await _client.get('/vendor/branches');
    return readMaps(data).map(ManagedBranch.fromJson).toList();
  }

  Future<void> updateBranch(
    String id, {
    required String nameAr,
    required String nameEn,
    required String addressAr,
    required String addressEn,
    required String phone,
    required num capacity,
    required List<String> amenities,
    required List<WorkingDay> workingHours,
    required bool active,
    required String reason,
  }) =>
      _client.patch('/vendor/branches/$id', body: {
        'name': {'ar': nameAr, 'en': nameEn},
        'address': {'ar': addressAr, 'en': addressEn},
        'phone': phone,
        'capacity': capacity,
        'amenities': amenities,
        'workingHours': workingHours.map((day) => day.toJson()).toList(),
        'active': active,
        'reason': reason,
      });

  Future<void> updateBranchRules(String id, {required BranchRules rules, required String reason}) =>
      _client.put('/vendor/branches/$id/settings', body: {
        'settings': rules.toJson(),
        'reason': reason,
      });

  // Audit

  Future<ApiPage<AuditEntry>> audit({required String branchId, int page = 1}) => _client.getPage(
        '/vendor/audit',
        query: {'branchId': branchId, 'page': page},
        parse: AuditEntry.fromJson,
      );

  // Settings. Each section saves on its own, always with a reason.

  Future<BusinessSettings> settings() async =>
      BusinessSettings.fromJson(readMap(await _client.get('/vendor/settings')));

  Future<void> saveBusinessDetails({
    required String nameAr,
    required String nameEn,
    required String phone,
    required String email,
    required String reason,
  }) =>
      _client.put('/vendor/settings', body: {
        'business': {
          'name': {'ar': nameAr, 'en': nameEn},
          'phone': phone,
          'email': email,
        },
        'reason': reason,
      });

  Future<void> saveManagerCanEditServices(bool value, {required String reason}) =>
      _client.put('/vendor/settings', body: {'managerCanEditServices': value, 'reason': reason});

  Future<void> saveNotificationPrefs(Map<String, bool> prefs, {required String reason}) =>
      _client.put('/vendor/settings', body: {
        'notificationPrefs': {...prefs, BusinessSettings.alwaysOnPref: true},
        'reason': reason,
      });
}
