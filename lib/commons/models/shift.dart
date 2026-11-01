import 'audit_entry.dart';
import 'json_read.dart';
import 'localized_text.dart';

class Shift {
  final String id;
  final String staffName;
  final LocalizedText branchName;
  final String status;
  final DateTime? scheduledStart;
  final DateTime? scheduledEnd;
  final DateTime? actualStart;
  final DateTime? actualEnd;
  final int ordersCompleted;
  final num cashPayments;
  final num cardPayments;
  final num expectedCash;
  final num? actualCash;
  final num? difference;
  final String? reason;
  final String? reviewNote;
  final String? reviewedBy;

  const Shift({
    required this.id,
    required this.staffName,
    required this.branchName,
    required this.status,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.actualStart,
    required this.actualEnd,
    required this.ordersCompleted,
    required this.cashPayments,
    required this.cardPayments,
    required this.expectedCash,
    required this.actualCash,
    required this.difference,
    required this.reason,
    required this.reviewNote,
    required this.reviewedBy,
  });

  bool get isOpen => status == 'open';

  factory Shift.fromJson(Map<String, dynamic> json) => Shift(
        id: readStr(json['id']),
        staffName: readStr(json['staffName']),
        branchName: LocalizedText.fromJson(json['branchName']),
        status: readStr(json['status']),
        scheduledStart: readDate(json['scheduledStart']),
        scheduledEnd: readDate(json['scheduledEnd']),
        actualStart: readDate(json['actualStart']),
        actualEnd: readDate(json['actualEnd']),
        ordersCompleted: readInt(json['ordersCompleted']),
        cashPayments: readNum(json['cashPayments']),
        cardPayments: readNum(json['cardPayments']),
        expectedCash: readNum(json['expectedCash']),
        actualCash: readNumOrNull(json['actualCash']),
        difference: readNumOrNull(json['difference']),
        reason: readStrOrNull(json['reason']),
        reviewNote: readStrOrNull(json['reviewNote']),
        reviewedBy: readStrOrNull(json['reviewedBy']),
      );
}

class ShiftOrder {
  final String id;
  final String number;
  final String plate;
  final DateTime? at;
  final String? method;
  final bool paid;
  final num total;

  const ShiftOrder({
    required this.id,
    required this.number,
    required this.plate,
    required this.at,
    required this.method,
    required this.paid,
    required this.total,
  });

  factory ShiftOrder.fromJson(Map<String, dynamic> json) => ShiftOrder(
        id: readStr(json['id']),
        number: readStr(json['number']),
        plate: readStr(json['plate']),
        at: readDate(json['at']),
        method: readStrOrNull(json['method']),
        paid: readBool(json['paid']),
        total: readNum(json['total']),
      );
}

class ShiftDetails {
  final Shift shift;
  final List<ShiftOrder> orders;
  final List<AuditEntry> auditLogs;

  const ShiftDetails({required this.shift, required this.orders, required this.auditLogs});

  factory ShiftDetails.fromJson(Map<String, dynamic> json) => ShiftDetails(
        shift: Shift.fromJson(readMap(json['shift'])),
        orders: readMaps(json['orders']).map(ShiftOrder.fromJson).toList(),
        auditLogs: readMaps(json['auditLogs']).map(AuditEntry.fromJson).toList(),
      );
}

class ShiftTotals {
  final num expected;
  final num difference;

  const ShiftTotals({required this.expected, required this.difference});

  factory ShiftTotals.fromJson(Map<String, dynamic> json) => ShiftTotals(
        expected: readNum(json['expected']),
        difference: readNum(json['difference']),
      );
}
