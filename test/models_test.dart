import 'package:flutter_test/flutter_test.dart';
import 'package:washup_owner/commons/models/dashboard_summary.dart';
import 'package:washup_owner/commons/models/live_board.dart';
import 'package:washup_owner/commons/models/order.dart';
import 'package:washup_owner/commons/models/owner_account.dart';
import 'package:washup_owner/core/enums/enums.dart';

// Shapes copied from the vendor API responses, with made-up values.
Map<String, dynamic> orderRow({String status = 'waiting', String? next = 'start'}) => {
      'id': 'ord_1',
      'number': 'CZ-1',
      'plate': 'ABC 123',
      'vehicleLabel': 'Kia Cerato',
      'customerName': 'Customer',
      'serviceName': {'ar': 'غسيل', 'en': 'Wash'},
      'branchName': {'ar': 'فرع', 'en': 'Branch'},
      'staffName': null,
      'scheduledAt': '2026-11-01T10:00:00.000Z',
      'total': 356,
      'source': 'walk_in',
      'status': status,
      'paymentStatus': 'pending',
      'nextAction': next,
      'locked': false,
      'overdueMin': 5,
    };

void main() {
  test('reads /auth/me', () {
    final account = OwnerAccount.fromJson({
      'id': 'st_1',
      'name': 'Owner',
      'phone': '+20 100 000 0000',
      'role': 'owner',
      'businessId': 'biz_1',
      'businessName': {'ar': 'مغسلة', 'en': 'Wash'},
      'businessStatus': 'active',
      'homeBranchId': 'br_1',
      'branches': [
        {
          'id': 'br_1',
          'name': {'ar': 'فرع', 'en': 'Branch'},
          'area': 'nasr',
          'active': true,
          'capacity': 4,
        },
      ],
      'permissions': {'refund': true, 'closeShift': false},
      'maxDiscountPct': 100,
      'canEditServices': true,
    });

    expect(account.branches.single.capacity, 4);
    expect(account.can(OwnerPermission.refund), isTrue);
    expect(account.can(OwnerPermission.closeShift), isFalse);
    expect(account.can(OwnerPermission.manageStaff), isFalse, reason: 'missing means not granted');
  });

  test('reads /dashboard, including an empty day', () {
    final summary = DashboardSummary.fromJson({
      'generatedAt': '2026-11-01T10:40:01.781Z',
      'kpis': [
        {'key': 'revenue', 'value': 0, 'delta': null, 'spark': [0, 0]},
      ],
      'liveBranches': [
        {
          'id': 'br_1',
          'name': {'ar': 'فرع', 'en': 'Branch'},
          'isOpen': true,
          'opensAt': '09:00',
          'closesAt': '23:00',
          'waiting': 0,
          'inService': 0,
          'paymentPending': 0,
          'baysBusy': 0,
          'capacity': 4,
          'staffOnShift': [
            {'id': 'st_2', 'name': 'Staff'},
          ],
          'revenueToday': 0,
        },
      ],
      'carsInside': [],
      'alerts': [],
      'charts': {
        'revenueByHour': [
          {'label': '8', 'value': 0},
        ],
      },
    });

    expect(summary.kpi('revenue')?.delta, isNull);
    expect(summary.kpi('unknown'), isNull);
    expect(summary.liveBranches.single.staffOnShift.single.name, 'Staff');
  });

  test('reads /live with cars in its columns', () {
    final board = LiveBoard.fromJson({
      'generatedAt': '2026-11-01T10:40:01.781Z',
      'columns': {
        'upcoming': [],
        'waiting': [orderRow()],
        'in_service': [],
        'payment_pending': [],
        'done': [],
      },
      'bays': {'busy': 1, 'capacity': 4},
      'staffOnShift': [],
    });

    expect(board.baysBusy, 1);
    final order = board.ordersIn(LiveColumn.waiting).single;
    expect(order.nextAction, OrderAction.start);
    expect(order.source, OrderSource.walkIn);
    expect(board.ordersIn(LiveColumn.inService), isEmpty);
  });

  test('an unknown next action is ignored rather than crashing', () {
    expect(OrderSummary.fromJson(orderRow(next: 'something_new')).nextAction, isNull);
    expect(OrderSummary.fromJson(orderRow(next: null)).nextAction, isNull);
  });

  test('reads /orders/:id', () {
    final details = OrderDetails.fromJson({
      'allowedActions': ['note', 'refund', 'something_new'],
      'nextAction': null,
      'assignableStaff': [
        {'id': 'st_2', 'name': 'Staff'},
      ],
      'availableAddons': [],
      'maxDiscountPct': 20,
      'locked': false,
      'customer': {'name': 'Customer', 'phone': '01000000000'},
      'vehicle': {'make': 'Kia', 'model': 'Cerato', 'plate': 'ABC'},
      'staff': {'id': 'st_2', 'name': 'Staff'},
      'order': {
        'id': 'ord_1',
        'number': 'CZ-1',
        'plate': 'ABC',
        'status': 'completed',
        'paymentStatus': 'paid',
        'source': 'app',
        'scheduledAt': '2026-11-01T10:00:00.000Z',
        'subtotal': 400,
        'discount': {'amount': 44, 'pct': 11, 'reason': 'offer'},
        'total': 356,
        'paymentMethod': 'cash',
        'items': [
          {
            'serviceId': 's1',
            'name': {'ar': 'غسيل', 'en': 'Wash'},
            'price': 400,
            'durationMin': 30,
            'type': 'primary',
          },
        ],
        'timeline': [
          {'status': 'pending', 'at': '2026-11-01T09:00:00.000Z'},
        ],
        'notes': [],
      },
    });

    expect(details.vehicleLabel, 'Kia Cerato');
    expect(details.discountAmount, 44);
    expect(details.allowedActions, [OrderAction.note, OrderAction.refund]);
    expect(details.items.single.isAddon, isFalse);
    expect(details.assignableStaff.single.id, 'st_2');
  });
}
