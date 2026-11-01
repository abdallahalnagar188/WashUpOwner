import '../../core/enums/enums.dart';
import 'localized_text.dart';
import 'owner_account.dart';

/// Keys match `columns` in `/api/v1/vendor/live`.
enum LiveColumn {
  upcoming,
  waiting,
  inService,
  paymentPending,
  done;

  String get key => switch (this) {
        LiveColumn.inService => 'in_service',
        LiveColumn.paymentPending => 'payment_pending',
        _ => name,
      };
}

enum LiveAction {
  confirm(OwnerPermission.confirmBooking),
  checkIn(OwnerPermission.runService),
  start(OwnerPermission.runService),
  finish(OwnerPermission.runService),
  collect(OwnerPermission.collectPayment);

  final OwnerPermission permission;

  const LiveAction(this.permission);
}

class StaffOnShift {
  final String id;
  final String name;

  const StaffOnShift({required this.id, required this.name});

  factory StaffOnShift.fromJson(Map<String, dynamic> json) =>
      StaffOnShift(id: json['id'] as String, name: json['name']?.toString() ?? '');
}

/// A car on the live board. Its fields are not confirmed yet: `/live` returned
/// empty columns when checked, so this follows what the dashboard shows and
/// needs matching to the API documentation.
class LiveOrder {
  final String id;
  final String number;
  final String plate;
  final String vehicle;
  final String customerName;
  final LocalizedText serviceName;
  final DateTime scheduledAt;
  final num total;
  final OrderSource source;
  final OrderStatus status;
  final PaymentStatus paymentStatus;

  const LiveOrder({
    required this.id,
    required this.number,
    required this.plate,
    required this.vehicle,
    required this.customerName,
    required this.serviceName,
    required this.scheduledAt,
    required this.total,
    required this.source,
    required this.status,
    required this.paymentStatus,
  });

  LiveAction? get nextAction => switch (status) {
        OrderStatus.pending => LiveAction.confirm,
        OrderStatus.confirmed => LiveAction.checkIn,
        OrderStatus.waiting => LiveAction.start,
        OrderStatus.inService => LiveAction.finish,
        OrderStatus.completed =>
          paymentStatus == PaymentStatus.pending ? LiveAction.collect : null,
        _ => null,
      };

  LiveOrder copyWith({OrderStatus? status, PaymentStatus? paymentStatus}) => LiveOrder(
        id: id,
        number: number,
        plate: plate,
        vehicle: vehicle,
        customerName: customerName,
        serviceName: serviceName,
        scheduledAt: scheduledAt,
        total: total,
        source: source,
        status: status ?? this.status,
        paymentStatus: paymentStatus ?? this.paymentStatus,
      );

  factory LiveOrder.fromJson(Map<String, dynamic> json) => LiveOrder(
        id: json['id'] as String,
        number: json['number']?.toString() ?? '',
        plate: json['plate']?.toString() ?? '',
        vehicle: json['vehicle']?.toString() ?? '',
        customerName: json['customerName']?.toString() ?? '',
        serviceName: LocalizedText.fromJson(json['serviceName']),
        scheduledAt: DateTime.parse(json['scheduledAt'] as String),
        total: json['total'] as num? ?? 0,
        source: OrderSource.fromKey(json['source'] as String?),
        status: OrderStatus.fromKey(json['status'] as String?),
        paymentStatus: PaymentStatus.fromKey(json['paymentStatus'] as String?),
      );
}

class LiveBoard {
  final String branchId;
  final DateTime generatedAt;
  final Map<LiveColumn, List<LiveOrder>> columns;
  final int baysBusy;
  final int capacity;
  final List<StaffOnShift> staffOnShift;

  const LiveBoard({
    required this.branchId,
    required this.generatedAt,
    required this.columns,
    required this.baysBusy,
    required this.capacity,
    required this.staffOnShift,
  });

  List<LiveOrder> ordersIn(LiveColumn column) => columns[column] ?? const [];

  factory LiveBoard.fromJson(Map<String, dynamic> json) {
    final columns = json['columns'] as Map<String, dynamic>? ?? const {};
    final bays = json['bays'] as Map<String, dynamic>? ?? const {};
    return LiveBoard(
      branchId: json['branchId']?.toString() ?? 'all',
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      columns: {
        for (final column in LiveColumn.values)
          column: (columns[column.key] as List? ?? const [])
              .map((o) => LiveOrder.fromJson(o as Map<String, dynamic>))
              .toList(),
      },
      baysBusy: (bays['busy'] as num?)?.toInt() ?? 0,
      capacity: (bays['capacity'] as num?)?.toInt() ?? 0,
      staffOnShift: (json['staffOnShift'] as List? ?? const [])
          .map((s) => StaffOnShift.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}
