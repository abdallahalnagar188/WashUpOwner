import 'order.dart';

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

class LiveBoard {
  final DateTime generatedAt;
  final Map<LiveColumn, List<OrderSummary>> columns;
  final int baysBusy;
  final int capacity;
  final List<NamedRef> staffOnShift;

  const LiveBoard({
    required this.generatedAt,
    required this.columns,
    required this.baysBusy,
    required this.capacity,
    required this.staffOnShift,
  });

  List<OrderSummary> ordersIn(LiveColumn column) => columns[column] ?? const [];

  factory LiveBoard.fromJson(Map<String, dynamic> json) {
    final columns = json['columns'] as Map<String, dynamic>? ?? const {};
    final bays = json['bays'] as Map<String, dynamic>? ?? const {};
    return LiveBoard(
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      columns: {
        for (final column in LiveColumn.values)
          column: (columns[column.key] as List? ?? const [])
              .map((o) => OrderSummary.fromJson(o as Map<String, dynamic>))
              .toList(),
      },
      baysBusy: (bays['busy'] as num?)?.toInt() ?? 0,
      capacity: (bays['capacity'] as num?)?.toInt() ?? 0,
      staffOnShift: (json['staffOnShift'] as List? ?? const [])
          .map((s) => NamedRef.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}
