enum CacheKeys {
  loggedIn,
  theme,
  userToken,
  userId,
  name,
  mobile,
  selectedBranch,
}

enum TosterTypes { warning, sucsses, failed }

enum OrderStatus {
  pending,
  confirmed,
  waiting,
  inService,
  completed,
  cancelled,
  noShow;

  String get key => switch (this) {
        OrderStatus.inService => 'in_service',
        OrderStatus.noShow => 'no_show',
        _ => name,
      };

  static OrderStatus fromKey(String? key) =>
      OrderStatus.values.firstWhere((s) => s.key == key, orElse: () => OrderStatus.pending);
}

enum PaymentStatus {
  pending,
  paid,
  refunded;

  static PaymentStatus fromKey(String? key) =>
      PaymentStatus.values.firstWhere((s) => s.name == key, orElse: () => PaymentStatus.pending);
}

enum OrderSource {
  app,
  walkIn,
  phone;

  String get key => this == OrderSource.walkIn ? 'walk_in' : name;

  static OrderSource fromKey(String? key) =>
      OrderSource.values.firstWhere((s) => s.key == key, orElse: () => OrderSource.app);
}

enum DashboardPeriod {
  today,
  week,
  month;

  /// The `period` query value the vendor API takes.
  String get apiValue => switch (this) {
        DashboardPeriod.today => 'today',
        DashboardPeriod.week => '7d',
        DashboardPeriod.month => '30d',
      };
}
