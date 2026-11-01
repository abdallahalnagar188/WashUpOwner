import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:washup_owner/commons/models/live_board.dart';
import 'package:washup_owner/commons/models/localized_text.dart';
import 'package:washup_owner/commons/models/owner_account.dart';
import 'package:washup_owner/core/data/mock_owner_repo.dart';
import 'package:washup_owner/core/data/owner_repo.dart';
import 'package:washup_owner/core/enums/enums.dart';
import 'package:washup_owner/core/local/cache_controller.dart';
import 'package:washup_owner/core/services/session_service.dart';
import 'package:washup_owner/features/live/presentation/controllers/live_controller.dart';
import 'package:washup_owner/features/main/presentation/controllers/main_controller.dart';

OwnerAccount _accountWith(Set<OwnerPermission> granted) => OwnerAccount(
      id: 'st_1',
      name: 'Staff',
      phone: '',
      role: 'employee',
      businessId: 'biz_demo',
      businessName: const LocalizedText('مغسلة', 'Wash'),
      businessStatus: 'active',
      homeBranchId: null,
      branches: MockOwnerRepo.demoAccount.branches,
      permissions: {for (final p in granted) p.name: true},
      maxDiscountPct: 0,
      canEditServices: false,
    );

Future<LiveController> _start(OwnerAccount account) async {
  final repo = MockOwnerRepo(latency: Duration.zero, account: account);
  Get.put<OwnerRepo>(repo);
  final session = Get.put(SessionService(repo));
  await session.signIn(identifier: 'x', password: 'x');
  Get.put(MainController());
  final controller = Get.put(LiveController());
  await controller.load();
  return controller;
}

LiveOrder _firstIn(LiveController controller, LiveColumn column) =>
    controller.board.value!.ordersIn(column).first;

void main() {
  setUp(() async {
    Get.testMode = true;
    SharedPreferences.setMockInitialValues({});
    await CacheController().initSharedPreferences();
  });

  tearDown(Get.reset);

  test('a car moves through every stage until it is paid', () async {
    final c = await _start(MockOwnerRepo.demoAccount);

    final booking = c.board.value!.ordersIn(LiveColumn.upcoming)
        .firstWhere((o) => o.status == OrderStatus.pending);
    expect(booking.nextAction, LiveAction.confirm);

    await c.run(booking);
    var order = _orderById(c, booking.id);
    expect(order.status, OrderStatus.confirmed);

    for (final (action, column) in [
      (LiveAction.checkIn, LiveColumn.waiting),
      (LiveAction.start, LiveColumn.inService),
      (LiveAction.finish, LiveColumn.paymentPending),
      (LiveAction.collect, LiveColumn.done),
    ]) {
      expect(order.nextAction, action);
      await c.run(order);
      order = _orderById(c, booking.id);
      expect(c.board.value!.ordersIn(column).map((o) => o.id), contains(booking.id));
    }

    expect(order.paymentStatus, PaymentStatus.paid);
    expect(order.nextAction, isNull);
  });

  test('without the permission the action does nothing', () async {
    final c = await _start(_accountWith({OwnerPermission.runService}));
    final unpaid = _firstIn(c, LiveColumn.paymentPending);

    expect(c.canRun(LiveAction.collect), isFalse);
    expect(c.canRun(LiveAction.start), isTrue);

    await c.run(unpaid);

    expect(_orderById(c, unpaid.id).paymentStatus, PaymentStatus.pending);
  });

  test('the repo refuses an action that does not fit the stage', () async {
    final repo = MockOwnerRepo(latency: Duration.zero);
    final board = await repo.live();
    final waiting = board.ordersIn(LiveColumn.waiting).first;

    expect(
      () => repo.runAction(orderId: waiting.id, action: LiveAction.collect),
      throwsA(isA<OwnerRepoException>()),
    );
  });

  test('a full branch cannot start another car', () async {
    final repo = MockOwnerRepo(latency: Duration.zero);
    // The main branch has 4 bays with 1 in use; these three fill it.
    for (final id in ['1003', '1002', '1001']) {
      var order = (await repo.live()).columns.values.expand((o) => o).firstWhere((o) => o.id == id);
      while (order.status != OrderStatus.inService) {
        final board = await repo.runAction(orderId: id, action: order.nextAction!);
        order = board.columns.values.expand((o) => o).firstWhere((o) => o.id == id);
      }
    }

    await expectLater(
      repo.runAction(orderId: '1007', action: LiveAction.start),
      throwsA(isA<OwnerRepoException>().having((e) => e.messageKey, 'messageKey', 'live.baysFull')),
    );
  });

  test('switching the branch reloads that branch only', () async {
    final c = await _start(MockOwnerRepo.demoAccount);
    final session = Get.find<SessionService>();

    session.selectBranch('br_demo_2');
    await c.load();

    expect(c.board.value!.branchId, 'br_demo_2');
    expect(c.board.value!.capacity, 3);
  });
}

LiveOrder _orderById(LiveController c, String id) =>
    c.board.value!.columns.values.expand((o) => o).firstWhere((o) => o.id == id);
