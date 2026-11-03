import '../../core/enums/enums.dart';
import 'branch_locale.dart';
import 'localized_text.dart';
import 'owner_account.dart';

/// Keys match the `action` the vendor API takes. [permission] hides what the
/// account cannot do; the server still has the final say.
enum OrderAction {
  confirm('confirm', OwnerPermission.confirmBooking),
  checkIn('check_in', OwnerPermission.runService),
  start('start', OwnerPermission.runService),
  complete('complete', OwnerPermission.runService),
  collectPayment('collect_payment', OwnerPermission.collectPayment),
  cancel('cancel', OwnerPermission.cancelOrder),
  noShow('no_show', OwnerPermission.runService),
  assign('assign', null),
  addService('add_service', null),
  discount('discount', null),
  note('note', null),
  refund('refund', OwnerPermission.refund);

  final String key;
  final OwnerPermission? permission;

  const OrderAction(this.key, this.permission);

  static OrderAction? fromKey(String? key) {
    for (final action in values) {
      if (action.key == key) return action;
    }
    return null;
  }
}

/// A row in the orders lists and on the live board.
class OrderSummary {
  final String id;
  final String number;
  final String plate;
  final String vehicleLabel;
  final String customerName;
  final LocalizedText serviceName;
  final String? staffName;
  final String? branchId;
  final LocalizedText? branchName;
  final BranchLocale? locale;
  final DateTime scheduledAt;
  final num total;
  final OrderSource source;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final OrderAction? nextAction;
  final bool locked;
  final int overdueMin;

  const OrderSummary({
    required this.id,
    required this.number,
    required this.plate,
    required this.vehicleLabel,
    required this.customerName,
    required this.serviceName,
    this.staffName,
    this.branchId,
    this.branchName,
    this.locale,
    required this.scheduledAt,
    required this.total,
    required this.source,
    required this.status,
    required this.paymentStatus,
    this.nextAction,
    this.locked = false,
    this.overdueMin = 0,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) => OrderSummary(
        id: json['id'] as String,
        number: json['number']?.toString() ?? '',
        plate: json['plate']?.toString() ?? '',
        vehicleLabel: json['vehicleLabel']?.toString() ?? '',
        customerName: json['customerName']?.toString() ?? '',
        serviceName: LocalizedText.fromJson(json['serviceName']),
        staffName: json['staffName'] as String?,
        branchId: json['branchId'] as String?,
        branchName: json['branchName'] == null ? null : LocalizedText.fromJson(json['branchName']),
        locale: BranchLocale.fromJson(json['branchLocale']),
        scheduledAt: DateTime.parse(json['scheduledAt'] as String),
        total: json['total'] as num? ?? 0,
        source: OrderSource.fromKey(json['source'] as String?),
        status: OrderStatus.fromKey(json['status'] as String?),
        paymentStatus: PaymentStatus.fromKey(json['paymentStatus'] as String?),
        nextAction: OrderAction.fromKey(json['nextAction'] as String?),
        locked: json['locked'] == true,
        overdueMin: (json['overdueMin'] as num?)?.toInt() ?? 0,
      );
}

class OrderItem {
  final String serviceId;
  final LocalizedText name;
  final num price;
  final int durationMin;
  final bool isAddon;

  const OrderItem({
    required this.serviceId,
    required this.name,
    required this.price,
    required this.durationMin,
    required this.isAddon,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        serviceId: json['serviceId']?.toString() ?? '',
        name: LocalizedText.fromJson(json['name']),
        price: json['price'] as num? ?? 0,
        durationMin: (json['durationMin'] as num?)?.toInt() ?? 0,
        isAddon: json['type'] == 'addon',
      );
}

class NamedRef {
  final String id;
  final String name;

  const NamedRef({required this.id, required this.name});

  factory NamedRef.fromJson(Map<String, dynamic> json) =>
      NamedRef(id: json['id']?.toString() ?? '', name: json['name']?.toString() ?? '');
}

class OrderTimelineEntry {
  final OrderStatus status;
  final DateTime at;

  const OrderTimelineEntry({required this.status, required this.at});

  factory OrderTimelineEntry.fromJson(Map<String, dynamic> json) => OrderTimelineEntry(
        status: OrderStatus.fromKey(json['status'] as String?),
        at: DateTime.parse(json['at'] as String),
      );
}

class OrderNote {
  final String text;
  final DateTime? at;

  const OrderNote({required this.text, this.at});

  factory OrderNote.fromJson(dynamic json) {
    if (json is Map) {
      final at = json['at'] as String?;
      return OrderNote(
        text: json['text']?.toString() ?? '',
        at: at == null ? null : DateTime.tryParse(at),
      );
    }
    return OrderNote(text: json?.toString() ?? '');
  }
}

class AddonOption {
  final String id;
  final LocalizedText name;
  final num price;

  const AddonOption({required this.id, required this.name, required this.price});

  factory AddonOption.fromJson(Map<String, dynamic> json) => AddonOption(
        id: json['id']?.toString() ?? '',
        name: LocalizedText.fromJson(json['name']),
        price: json['price'] as num? ?? 0,
      );
}

/// Everything `GET /vendor/orders/:id` returns that the app shows.
class OrderDetails {
  final String id;
  final String number;
  final String plate;
  final String? vehicleLabel;
  final String? customerName;
  final String? customerPhone;
  final String? staffName;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final OrderSource source;
  final String? branchId;
  final BranchLocale? locale;
  final DateTime scheduledAt;
  final num subtotal;
  final num discountAmount;
  final num total;
  final String? paymentMethod;
  final String? code;
  final String? cancelReason;
  final List<OrderItem> items;
  final List<OrderTimelineEntry> timeline;
  final List<OrderNote> notes;
  final List<OrderAction> allowedActions;
  final OrderAction? nextAction;
  final List<NamedRef> assignableStaff;
  final List<AddonOption> availableAddons;
  final num maxDiscountPct;
  final bool locked;

  /// Minutes after the slot before "no-show" is allowed (branch rule).
  final int noShowGraceMin;

  const OrderDetails({
    required this.id,
    required this.number,
    required this.plate,
    this.vehicleLabel,
    this.customerName,
    this.customerPhone,
    this.staffName,
    required this.status,
    required this.paymentStatus,
    required this.source,
    this.branchId,
    this.locale,
    required this.scheduledAt,
    required this.subtotal,
    required this.discountAmount,
    required this.total,
    this.paymentMethod,
    this.code,
    this.cancelReason,
    required this.items,
    required this.timeline,
    required this.notes,
    required this.allowedActions,
    this.nextAction,
    required this.assignableStaff,
    required this.availableAddons,
    required this.maxDiscountPct,
    required this.locked,
    this.noShowGraceMin = 15,
  });

  factory OrderDetails.fromJson(Map<String, dynamic> json) {
    final order = json['order'] as Map<String, dynamic>;
    final customer = json['customer'] as Map<String, dynamic>?;
    final vehicle = json['vehicle'] as Map<String, dynamic>?;
    final staff = json['staff'] as Map<String, dynamic>?;
    final discount = order['discount'] as Map<String, dynamic>?;
    final cancel = order['cancel'] as Map<String, dynamic>?;
    final make = vehicle?['make']?.toString();
    final model = vehicle?['model']?.toString();
    return OrderDetails(
      id: order['id'] as String,
      number: order['number']?.toString() ?? '',
      plate: order['plate']?.toString() ?? '',
      vehicleLabel: make == null ? null : '$make ${model ?? ''}'.trim(),
      customerName: customer?['name']?.toString(),
      customerPhone: customer?['phone']?.toString(),
      staffName: staff?['name']?.toString(),
      status: OrderStatus.fromKey(order['status'] as String?),
      paymentStatus: PaymentStatus.fromKey(order['paymentStatus'] as String?),
      source: OrderSource.fromKey(order['source'] as String?),
      branchId: (order['branchId'] ?? json['branchId']) as String?,
      locale: BranchLocale.fromJson(order['branchLocale'] ?? json['branchLocale']),
      scheduledAt: DateTime.parse(order['scheduledAt'] as String),
      subtotal: order['subtotal'] as num? ?? 0,
      discountAmount: discount?['amount'] as num? ?? 0,
      total: order['total'] as num? ?? 0,
      paymentMethod: order['paymentMethod'] as String?,
      code: order['code'] as String?,
      cancelReason: cancel?['reason']?.toString(),
      items: (order['items'] as List? ?? const [])
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      timeline: (order['timeline'] as List? ?? const [])
          .map((entry) => OrderTimelineEntry.fromJson(entry as Map<String, dynamic>))
          .toList(),
      notes: (order['notes'] as List? ?? const []).map(OrderNote.fromJson).toList(),
      allowedActions: (json['allowedActions'] as List? ?? const [])
          .map((key) => OrderAction.fromKey(key as String?))
          .whereType<OrderAction>()
          .toList(),
      nextAction: OrderAction.fromKey(json['nextAction'] as String?),
      assignableStaff: (json['assignableStaff'] as List? ?? const [])
          .map((staff) => NamedRef.fromJson(staff as Map<String, dynamic>))
          .toList(),
      availableAddons: (json['availableAddons'] as List? ?? const [])
          .map((addon) => AddonOption.fromJson(addon as Map<String, dynamic>))
          .toList(),
      maxDiscountPct: json['maxDiscountPct'] as num? ?? 0,
      locked: json['locked'] == true,
      noShowGraceMin: (json['noShowGraceMin'] ?? order['noShowGraceMin']) as int? ?? 15,
    );
  }

  /// The wash may mark a no-show only once the customer is this late.
  DateTime get noShowFrom => scheduledAt.add(Duration(minutes: noShowGraceMin));

  bool get noShowOpen => !DateTime.now().isBefore(noShowFrom);
}
