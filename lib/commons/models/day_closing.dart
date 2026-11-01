import 'json_read.dart';
import 'localized_text.dart';

class MethodAmounts {
  final num cash;
  final num card;
  final num online;
  final num total;

  const MethodAmounts({
    required this.cash,
    required this.card,
    required this.online,
    required this.total,
  });

  num of(String method) => switch (method) {
        'cash' => cash,
        'card' => card,
        'online' => online,
        _ => 0,
      };

  factory MethodAmounts.fromJson(Map<String, dynamic> json) {
    final cash = readNum(json['cash']);
    final card = readNum(json['card']);
    final online = readNum(json['online']);
    return MethodAmounts(
      cash: cash,
      card: card,
      online: online,
      total: readNum(json['total'], cash + card + online),
    );
  }
}

class ClosingRecord {
  final String id;
  final String date;
  final MethodAmounts expected;
  final MethodAmounts actual;
  final num difference;
  final String? reason;
  final String closedByName;
  final DateTime? closedAt;
  final int ordersLocked;

  const ClosingRecord({
    required this.id,
    required this.date,
    required this.expected,
    required this.actual,
    required this.difference,
    required this.reason,
    required this.closedByName,
    required this.closedAt,
    required this.ordersLocked,
  });

  factory ClosingRecord.fromJson(Map<String, dynamic> json) => ClosingRecord(
        id: readStr(json['id']),
        date: readStr(json['date']),
        expected: MethodAmounts.fromJson(readMap(json['expected'])),
        actual: MethodAmounts.fromJson(readMap(json['actual'])),
        difference: readNum(json['difference']),
        reason: readStrOrNull(json['reason']),
        closedByName: readStr(json['closedByName']),
        closedAt: readDate(json['closedAt']),
        ordersLocked: readInt(json['ordersLocked']),
      );
}

class ClosingOrder {
  final String id;
  final String number;
  final String plate;
  final String? method;
  final bool paid;
  final num total;

  const ClosingOrder({
    required this.id,
    required this.number,
    required this.plate,
    required this.method,
    required this.paid,
    required this.total,
  });

  factory ClosingOrder.fromJson(Map<String, dynamic> json) => ClosingOrder(
        id: readStr(json['id']),
        number: readStr(json['number']),
        plate: readStr(json['plate']),
        method: readStrOrNull(json['method']),
        paid: readBool(json['paid']),
        total: readNum(json['total']),
      );
}

class DayClosing {
  final String branchId;
  final LocalizedText branchName;
  final String date;
  final int completedOrders;
  final int inServiceOrders;
  final int unpaidOrders;
  final MethodAmounts expected;
  final ClosingRecord? closing;
  final List<ClosingOrder> orders;
  final List<ClosingRecord> history;

  const DayClosing({
    required this.branchId,
    required this.branchName,
    required this.date,
    required this.completedOrders,
    required this.inServiceOrders,
    required this.unpaidOrders,
    required this.expected,
    required this.closing,
    required this.orders,
    required this.history,
  });

  bool get hasOpenOrders => inServiceOrders + unpaidOrders > 0;

  int get paidOrders => orders.where((order) => order.paid).length;

  factory DayClosing.fromJson(Map<String, dynamic> json) => DayClosing(
        branchId: readStr(json['branchId']),
        branchName: LocalizedText.fromJson(json['branchName']),
        date: readStr(json['date']),
        completedOrders: readInt(json['completedOrders']),
        inServiceOrders: readInt(json['inServiceOrders']),
        unpaidOrders: readInt(json['unpaidOrders']),
        expected: MethodAmounts.fromJson(readMap(json['expected'])),
        closing: json['closing'] is Map ? ClosingRecord.fromJson(readMap(json['closing'])) : null,
        orders: readMaps(json['orders']).map(ClosingOrder.fromJson).toList(),
        history: readMaps(json['history']).map(ClosingRecord.fromJson).toList(),
      );
}
