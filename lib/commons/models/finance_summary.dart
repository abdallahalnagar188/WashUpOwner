import 'json_read.dart';
import 'localized_text.dart';

class MethodRevenue {
  final String method;
  final num amount;
  final int count;

  const MethodRevenue({required this.method, required this.amount, required this.count});

  factory MethodRevenue.fromJson(Map<String, dynamic> json) => MethodRevenue(
        method: readStr(json['method']),
        amount: readNum(json['amount']),
        count: readInt(json['count']),
      );
}

class BranchRevenue {
  final String branchId;
  final LocalizedText name;
  final num revenue;
  final int orders;

  const BranchRevenue({
    required this.branchId,
    required this.name,
    required this.revenue,
    required this.orders,
  });

  factory BranchRevenue.fromJson(Map<String, dynamic> json) => BranchRevenue(
        branchId: readStr(json['branchId']),
        name: LocalizedText.fromJson(json['name']),
        revenue: readNum(json['revenue']),
        orders: readInt(json['orders']),
      );
}

class DayRevenue {
  final String date;
  final String label;
  final num revenue;

  const DayRevenue({required this.date, required this.label, required this.revenue});

  factory DayRevenue.fromJson(Map<String, dynamic> json) => DayRevenue(
        date: readStr(json['date']),
        label: readStr(json['label']),
        revenue: readNum(json['revenue']),
      );
}

class PendingPayment {
  final String id;
  final String number;
  final String plate;
  final String? customerName;
  final LocalizedText serviceName;
  final num total;

  const PendingPayment({
    required this.id,
    required this.number,
    required this.plate,
    required this.customerName,
    required this.serviceName,
    required this.total,
  });

  factory PendingPayment.fromJson(Map<String, dynamic> json) => PendingPayment(
        id: readStr(json['id']),
        number: readStr(json['number']),
        plate: readStr(json['plate']),
        customerName: readStrOrNull(json['customerName']),
        serviceName: LocalizedText.fromJson(json['serviceName']),
        total: readNum(json['total']),
      );
}

class Payout {
  final String id;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final num amountDue;
  final num? amountPaid;
  final String status;
  final String? reference;
  final DateTime? paidAt;

  const Payout({
    required this.id,
    required this.periodStart,
    required this.periodEnd,
    required this.amountDue,
    required this.amountPaid,
    required this.status,
    required this.reference,
    required this.paidAt,
  });

  factory Payout.fromJson(Map<String, dynamic> json) => Payout(
        id: readStr(json['id']),
        periodStart: readDate(json['periodStart']),
        periodEnd: readDate(json['periodEnd']),
        amountDue: readNum(json['amountDue']),
        amountPaid: readNumOrNull(json['amountPaid']),
        status: readStr(json['status']),
        reference: readStrOrNull(json['reference']),
        paidAt: readDate(json['paidAt']),
      );
}

class FinanceSummary {
  final num revenue;
  final num commission;

  /// A percentage: 10 means 10%.
  final num commissionRate;
  final num net;
  final num refunds;
  final num discounts;
  final int paidOrders;
  final List<MethodRevenue> byMethod;
  final List<BranchRevenue> byBranch;
  final List<DayRevenue> byDay;
  final num pendingAmount;
  final int pendingCount;
  final List<PendingPayment> pendingOrders;
  final List<Payout> payouts;

  const FinanceSummary({
    required this.revenue,
    required this.commission,
    required this.commissionRate,
    required this.net,
    required this.refunds,
    required this.discounts,
    required this.paidOrders,
    required this.byMethod,
    required this.byBranch,
    required this.byDay,
    required this.pendingAmount,
    required this.pendingCount,
    required this.pendingOrders,
    required this.payouts,
  });

  factory FinanceSummary.fromJson(Map<String, dynamic> json) {
    final pending = readMap(json['pendingPayments']);
    return FinanceSummary(
      revenue: readNum(json['revenue']),
      commission: readNum(json['commission']),
      commissionRate: readNum(json['commissionRate']),
      net: readNum(json['net']),
      refunds: readNum(json['refunds']),
      discounts: readNum(json['discounts']),
      paidOrders: readInt(json['paidOrders']),
      byMethod: readMaps(json['byMethod']).map(MethodRevenue.fromJson).toList(),
      byBranch: readMaps(json['byBranch']).map(BranchRevenue.fromJson).toList(),
      byDay: readMaps(json['byDay']).map(DayRevenue.fromJson).toList(),
      pendingAmount: readNum(pending['amount']),
      pendingCount: readInt(pending['count']),
      pendingOrders: readMaps(pending['orders']).map(PendingPayment.fromJson).toList(),
      payouts: readMaps(json['payouts']).map(Payout.fromJson).toList(),
    );
  }
}
