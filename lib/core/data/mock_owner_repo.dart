import '../../commons/models/dashboard_summary.dart';
import '../../commons/models/live_board.dart';
import '../../commons/models/localized_text.dart';
import '../../commons/models/owner_account.dart';
import '../enums/enums.dart';
import 'owner_repo.dart';

class _MockBranch {
  final OwnerBranch branch;
  final List<StaffOnShift> staff;

  const _MockBranch(this.branch, this.staff);
}

/// Made-up wash used until the API is connected. Live actions change the data
/// in memory, so the screens behave like the real flow until the app restarts.
class MockOwnerRepo implements OwnerRepo {
  final Duration latency;
  final OwnerAccount account;

  MockOwnerRepo({this.latency = const Duration(milliseconds: 350), OwnerAccount? account})
      : account = account ?? demoAccount;

  static const List<_MockBranch> _branches = [
    _MockBranch(
      OwnerBranch(
        id: 'br_demo_1',
        name: LocalizedText('الفرع الرئيسي', 'Main Branch'),
        area: 'demo',
        active: true,
        capacity: 4,
      ),
      [StaffOnShift(id: 'st_demo_1', name: 'موظف تجريبي 1')],
    ),
    _MockBranch(
      OwnerBranch(
        id: 'br_demo_2',
        name: LocalizedText('الفرع الثاني', 'Second Branch'),
        area: 'demo',
        active: true,
        capacity: 3,
      ),
      [StaffOnShift(id: 'st_demo_2', name: 'موظف تجريبي 2')],
    ),
  ];

  static final OwnerAccount demoAccount = OwnerAccount(
    id: 'st_demo_owner',
    name: 'مالك تجريبي',
    phone: '+20 100 000 0000',
    role: 'owner',
    businessId: 'biz_demo',
    businessName: const LocalizedText('مغسلة تجريبية', 'Demo Wash'),
    businessStatus: 'active',
    homeBranchId: 'br_demo_1',
    branches: _branches.map((b) => b.branch).toList(),
    permissions: {for (final p in OwnerPermission.values) p.name: true},
    maxDiscountPct: 100,
    canEditServices: true,
  );

  late final List<({String branchId, LiveOrder order})> _orders = _seedOrders();

  List<({String branchId, LiveOrder order})> _seedOrders() {
    final now = DateTime.now();

    ({String branchId, LiveOrder order}) item(
      String branchId,
      String id,
      String plate,
      String vehicle,
      String customer,
      LocalizedText service,
      int minutesFromNow,
      num total,
      OrderSource source,
      OrderStatus status, [
      PaymentStatus payment = PaymentStatus.pending,
    ]) =>
        (
          branchId: branchId,
          order: LiveOrder(
            id: id,
            number: 'DEMO-$id',
            plate: plate,
            vehicle: vehicle,
            customerName: customer,
            serviceName: service,
            scheduledAt: now.add(Duration(minutes: minutesFromNow)),
            total: total,
            source: source,
            status: status,
            paymentStatus: payment,
          ),
        );

    const outside = LocalizedText('غسيل خارجي', 'Exterior wash');
    const full = LocalizedText('داخلي وخارجي', 'Interior and exterior');
    const deep = LocalizedText('تنظيف عميق', 'Deep clean');

    return [
      item('br_demo_1', '1001', 'أ ب ج 1234', 'Toyota Corolla', 'عميل تجريبي 1', full, 45, 180, OrderSource.app, OrderStatus.pending),
      item('br_demo_1', '1002', 'د ه و 2345', 'Hyundai Tucson', 'عميل تجريبي 2', outside, 75, 90, OrderSource.phone, OrderStatus.confirmed),
      item('br_demo_1', '1003', 'ز ح ط 3456', 'Kia Sportage', 'عميل تجريبي 3', deep, -10, 356, OrderSource.app, OrderStatus.waiting),
      item('br_demo_1', '1004', 'ي ك ل 4567', 'Nissan Sunny', 'عميل تجريبي 4', outside, -30, 90, OrderSource.walkIn, OrderStatus.inService),
      item('br_demo_1', '1005', 'م ن س 5678', 'Chevrolet Optra', 'عميل تجريبي 5', full, -60, 180, OrderSource.app, OrderStatus.completed),
      item('br_demo_1', '1006', 'ع ف ص 6789', 'MG 5', 'عميل تجريبي 6', outside, -120, 90, OrderSource.walkIn, OrderStatus.completed, PaymentStatus.paid),
      item('br_demo_1', '1007', 'ب ط ي 1357', 'Honda Civic', 'عميل تجريبي 10', outside, -5, 90, OrderSource.walkIn, OrderStatus.waiting),
      item('br_demo_2', '2001', 'ق ر ش 7890', 'Renault Logan', 'عميل تجريبي 7', full, 30, 170, OrderSource.app, OrderStatus.confirmed),
      item('br_demo_2', '2002', 'ت ث خ 8901', 'Skoda Octavia', 'عميل تجريبي 8', deep, -45, 340, OrderSource.app, OrderStatus.inService),
      item('br_demo_2', '2003', 'ذ ض غ 9012', 'BMW 320', 'عميل تجريبي 9', outside, -150, 95, OrderSource.phone, OrderStatus.completed, PaymentStatus.paid),
    ];
  }

  Future<void> _wait() => Future<void>.delayed(latency);

  Iterable<_MockBranch> _branchesFor(String branchId) =>
      _branches.where((b) => branchId == 'all' || b.branch.id == branchId);

  List<LiveOrder> _ordersFor(String branchId) => _orders
      .where((o) => branchId == 'all' || o.branchId == branchId)
      .map((o) => o.order)
      .toList();

  LiveColumn _columnOf(LiveOrder order) => switch (order.status) {
        OrderStatus.pending || OrderStatus.confirmed => LiveColumn.upcoming,
        OrderStatus.waiting => LiveColumn.waiting,
        OrderStatus.inService => LiveColumn.inService,
        _ => order.paymentStatus == PaymentStatus.pending ? LiveColumn.paymentPending : LiveColumn.done,
      };

  LiveBoard _board(String branchId) {
    final orders = _ordersFor(branchId);
    final branches = _branchesFor(branchId);
    return LiveBoard(
      branchId: branchId,
      generatedAt: DateTime.now(),
      columns: {
        for (final column in LiveColumn.values)
          column: orders.where((o) => _columnOf(o) == column).toList(),
      },
      baysBusy: orders.where((o) => o.status == OrderStatus.inService).length,
      capacity: branches.fold(0, (sum, b) => sum + b.branch.capacity),
      staffOnShift: branches.expand((b) => b.staff).toList(),
    );
  }

  LiveBranch _liveBranch(_MockBranch mock) {
    final orders = _ordersFor(mock.branch.id);
    int count(LiveColumn column) => orders.where((o) => _columnOf(o) == column).length;
    return LiveBranch(
      id: mock.branch.id,
      name: mock.branch.name,
      isOpen: true,
      opensAt: '09:00',
      closesAt: '23:00',
      waiting: count(LiveColumn.waiting),
      inService: count(LiveColumn.inService),
      paymentPending: count(LiveColumn.paymentPending),
      baysBusy: count(LiveColumn.inService),
      capacity: mock.branch.capacity,
      staffOnShift: mock.staff,
      revenueToday: orders
          .where((o) => o.paymentStatus == PaymentStatus.paid)
          .fold<num>(0, (sum, o) => sum + o.total),
    );
  }

  @override
  Future<OwnerAccount> signIn({required String identifier, required String password}) async {
    await _wait();
    return account;
  }

  @override
  Future<OwnerAccount> me() async {
    await _wait();
    return account;
  }

  @override
  Future<void> signOut() => _wait();

  @override
  Future<DashboardSummary> dashboard({required DashboardPeriod period, String branchId = 'all'}) async {
    await _wait();
    final orders = _ordersFor(branchId);
    final paid = orders.where((o) => o.paymentStatus == PaymentStatus.paid);
    final today = {
      'revenue': paid.fold<num>(0, (sum, o) => sum + o.total),
      'totalOrders': orders.length,
      'completed': orders.where((o) => o.status == OrderStatus.completed).length,
      'pendingPayments': orders.where((o) => _columnOf(o) == LiveColumn.paymentPending).length,
      'confirmedBookings': orders.where((o) => o.status == OrderStatus.confirmed).length,
      'walkIns': orders.where((o) => o.source == OrderSource.walkIn).length,
      'cancelled': 0,
      'noShows': 0,
    };
    final scale = switch (period) {
      DashboardPeriod.today => 1,
      DashboardPeriod.week => 6,
      DashboardPeriod.month => 24,
    };
    final pendingPayments = today['pendingPayments'];
    final cars = orders.where((o) {
      final column = _columnOf(o);
      return column == LiveColumn.waiting || column == LiveColumn.inService || column == LiveColumn.paymentPending;
    }).toList();

    return DashboardSummary(
      generatedAt: DateTime.now(),
      kpis: [
        for (final entry in today.entries)
          DashboardKpi(
            key: entry.key,
            value: entry.key == 'pendingPayments' ? entry.value : entry.value * scale,
            delta: entry.key == 'revenue' || entry.key == 'totalOrders' ? 12 : null,
          ),
      ],
      liveBranches: _branchesFor(branchId).map(_liveBranch).toList(),
      carsInside: cars,
      alerts: [
        if (pendingPayments != 0)
          DashboardAlert(
            id: 'pending_payments',
            title: LocalizedText(
              'مدفوعات معلقة: $pendingPayments',
              'Pending payments: $pendingPayments',
            ),
            body: const LocalizedText(
              'حصّل ثمن الطلبات المكتملة قبل إغلاق اليوم.',
              'Collect completed orders before closing the day.',
            ),
          ),
      ],
      revenueByHour: const [
        ChartPoint(label: '9', value: 180),
        ChartPoint(label: '10', value: 90),
        ChartPoint(label: '11', value: 356),
        ChartPoint(label: '12', value: 270),
        ChartPoint(label: '1', value: 170),
        ChartPoint(label: '2', value: 95),
      ],
    );
  }

  @override
  Future<LiveBoard> live({String branchId = 'all'}) async {
    await _wait();
    return _board(branchId);
  }

  @override
  Future<LiveBoard> runAction({
    required String orderId,
    required LiveAction action,
    String branchId = 'all',
  }) async {
    await _wait();
    final index = _orders.indexWhere((o) => o.order.id == orderId);
    if (index < 0 || _orders[index].order.nextAction != action) {
      throw const OwnerRepoException('live.actionFailed');
    }
    final entry = _orders[index];
    if (action == LiveAction.start) {
      final busy = _ordersFor(entry.branchId).where((o) => o.status == OrderStatus.inService).length;
      final capacity = _branchesFor(entry.branchId).first.branch.capacity;
      if (busy >= capacity) throw const OwnerRepoException('live.baysFull');
    }
    final order = entry.order;
    _orders[index] = (
      branchId: entry.branchId,
      order: switch (action) {
        LiveAction.confirm => order.copyWith(status: OrderStatus.confirmed),
        LiveAction.checkIn => order.copyWith(status: OrderStatus.waiting),
        LiveAction.start => order.copyWith(status: OrderStatus.inService),
        LiveAction.finish => order.copyWith(status: OrderStatus.completed),
        LiveAction.collect => order.copyWith(paymentStatus: PaymentStatus.paid),
      },
    );
    return _board(branchId);
  }
}
