import '../../core/enums/enums.dart';
import 'localized_text.dart';
import 'order.dart';

class DashboardKpi {
  final String key;
  final num value;

  /// Change from the previous period in percent; null when there is nothing to
  /// compare with.
  final num? delta;

  const DashboardKpi({required this.key, required this.value, this.delta});

  factory DashboardKpi.fromJson(Map<String, dynamic> json) => DashboardKpi(
        key: json['key'] as String,
        value: json['value'] as num? ?? 0,
        delta: json['delta'] as num?,
      );
}

/// A car currently at a branch (`carsInside` of `/vendor/dashboard`). The server
/// sends its own shape (`CarInside` in the portal's `types/vendor/dashboard.ts`),
/// not an order row: it has `orderId` instead of `id` and no `scheduledAt`.
class CarInside {
  final String orderId;
  final String number;
  final String plate;
  final OrderStatus status;
  final bool paymentPending;
  final LocalizedText serviceName;
  final LocalizedText? branchName;
  final String? staffName;
  final DateTime? since;
  final int overdueMin;

  const CarInside({
    required this.orderId,
    required this.number,
    required this.plate,
    required this.status,
    required this.paymentPending,
    required this.serviceName,
    this.branchName,
    this.staffName,
    this.since,
    this.overdueMin = 0,
  });

  factory CarInside.fromJson(Map<String, dynamic> json) => CarInside(
        orderId: (json['orderId'] ?? json['id'])?.toString() ?? '',
        number: json['number']?.toString() ?? '',
        plate: json['plate']?.toString() ?? '',
        status: OrderStatus.fromKey(json['status'] as String?),
        paymentPending: json['paymentPending'] == true,
        serviceName: LocalizedText.fromJson(json['serviceName']),
        branchName: json['branchName'] == null ? null : LocalizedText.fromJson(json['branchName']),
        staffName: json['staffName'] as String?,
        since: DateTime.tryParse(json['since']?.toString() ?? ''),
        overdueMin: (json['overdueMin'] as num?)?.toInt() ?? 0,
      );
}

class LiveBranch {
  final String id;
  final LocalizedText name;
  final bool isOpen;
  final String opensAt;
  final String closesAt;
  final int waiting;
  final int inService;
  final int paymentPending;
  final int baysBusy;
  final int capacity;
  final List<NamedRef> staffOnShift;
  final num revenueToday;

  const LiveBranch({
    required this.id,
    required this.name,
    required this.isOpen,
    required this.opensAt,
    required this.closesAt,
    required this.waiting,
    required this.inService,
    required this.paymentPending,
    required this.baysBusy,
    required this.capacity,
    required this.staffOnShift,
    required this.revenueToday,
  });

  factory LiveBranch.fromJson(Map<String, dynamic> json) => LiveBranch(
        id: json['id'] as String,
        name: LocalizedText.fromJson(json['name']),
        isOpen: json['isOpen'] == true,
        opensAt: json['opensAt']?.toString() ?? '',
        closesAt: json['closesAt']?.toString() ?? '',
        waiting: (json['waiting'] as num?)?.toInt() ?? 0,
        inService: (json['inService'] as num?)?.toInt() ?? 0,
        paymentPending: (json['paymentPending'] as num?)?.toInt() ?? 0,
        baysBusy: (json['baysBusy'] as num?)?.toInt() ?? 0,
        capacity: (json['capacity'] as num?)?.toInt() ?? 0,
        staffOnShift: (json['staffOnShift'] as List? ?? const [])
            .map((s) => NamedRef.fromJson(s as Map<String, dynamic>))
            .toList(),
        revenueToday: json['revenueToday'] as num? ?? 0,
      );
}

/// `alerts` was empty when checked, so only these common fields are read.
class DashboardAlert {
  final String id;
  final LocalizedText title;
  final LocalizedText? body;

  const DashboardAlert({required this.id, required this.title, this.body});

  factory DashboardAlert.fromJson(Map<String, dynamic> json) => DashboardAlert(
        id: json['id']?.toString() ?? '',
        title: LocalizedText.fromJson(json['title']),
        body: json['body'] == null ? null : LocalizedText.fromJson(json['body']),
      );
}

class ChartPoint {
  final String label;
  final num value;

  const ChartPoint({required this.label, required this.value});

  factory ChartPoint.fromJson(Map<String, dynamic> json) => ChartPoint(
        label: json['label']?.toString() ?? '',
        value: json['value'] as num? ?? 0,
      );
}

class DashboardSummary {
  final DateTime generatedAt;
  final List<DashboardKpi> kpis;
  final List<LiveBranch> liveBranches;
  final List<CarInside> carsInside;
  final List<DashboardAlert> alerts;
  final List<ChartPoint> revenueByHour;

  const DashboardSummary({
    required this.generatedAt,
    required this.kpis,
    required this.liveBranches,
    required this.carsInside,
    required this.alerts,
    required this.revenueByHour,
  });

  DashboardKpi? kpi(String key) {
    for (final item in kpis) {
      if (item.key == key) return item;
    }
    return null;
  }

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final charts = json['charts'] as Map<String, dynamic>? ?? const {};
    return DashboardSummary(
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      kpis: (json['kpis'] as List? ?? const [])
          .map((k) => DashboardKpi.fromJson(k as Map<String, dynamic>))
          .toList(),
      liveBranches: (json['liveBranches'] as List? ?? const [])
          .map((b) => LiveBranch.fromJson(b as Map<String, dynamic>))
          .toList(),
      carsInside: (json['carsInside'] as List? ?? const [])
          .map((o) => CarInside.fromJson(o as Map<String, dynamic>))
          .where((car) => car.orderId.isNotEmpty)
          .toList(),
      alerts: (json['alerts'] as List? ?? const [])
          .map((a) => DashboardAlert.fromJson(a as Map<String, dynamic>))
          .toList(),
      revenueByHour: (charts['revenueByHour'] as List? ?? const [])
          .map((p) => ChartPoint.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}
