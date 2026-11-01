import 'package:flutter_test/flutter_test.dart';
import 'package:washup_owner/commons/models/dashboard_summary.dart';
import 'package:washup_owner/commons/models/live_board.dart';
import 'package:washup_owner/commons/models/owner_account.dart';

// Shapes copied from the vendor API responses, with made-up values.
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
      'businessStatusReason': null,
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
      'lastLoginAt': null,
    });

    expect(account.branches.single.capacity, 4);
    expect(account.can(OwnerPermission.refund), isTrue);
    expect(account.can(OwnerPermission.closeShift), isFalse);
    expect(account.can(OwnerPermission.manageStaff), isFalse, reason: 'missing means not granted');
  });

  test('reads /dashboard, including an empty day', () {
    final summary = DashboardSummary.fromJson({
      'period': 'today',
      'branchId': 'all',
      'generatedAt': '2026-11-01T10:40:01.781Z',
      'kpis': [
        {'key': 'revenue', 'value': 0, 'delta': null, 'spark': [0, 0]},
      ],
      'liveBranches': [
        {
          'id': 'br_1',
          'name': {'ar': 'فرع', 'en': 'Branch'},
          'area': 'nasr',
          'isOpen': true,
          'opensAt': '09:00',
          'closesAt': '23:00',
          'activeOrders': 0,
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
    expect(summary.revenueByHour.single.label, '8');
  });

  test('reads an empty /live board', () {
    final board = LiveBoard.fromJson({
      'branchId': 'all',
      'generatedAt': '2026-11-01T10:40:01.781Z',
      'columns': {
        'upcoming': [],
        'waiting': [],
        'in_service': [],
        'payment_pending': [],
        'done': [],
      },
      'bays': {'busy': 1, 'capacity': 4},
      'staffOnShift': [
        {'id': 'st_2', 'name': 'Staff'},
      ],
    });

    expect(board.baysBusy, 1);
    expect(board.capacity, 4);
    for (final column in LiveColumn.values) {
      expect(board.ordersIn(column), isEmpty);
    }
  });
}
