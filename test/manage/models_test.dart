import 'package:flutter_test/flutter_test.dart';
import 'package:washup_owner/commons/models/app_notification.dart';
import 'package:washup_owner/commons/models/audit_entry.dart';
import 'package:washup_owner/commons/models/business_settings.dart';
import 'package:washup_owner/commons/models/customer.dart';
import 'package:washup_owner/commons/models/day_closing.dart';
import 'package:washup_owner/commons/models/finance_summary.dart';
import 'package:washup_owner/commons/models/managed_branch.dart';
import 'package:washup_owner/commons/models/managed_service.dart';
import 'package:washup_owner/commons/models/offer.dart';
import 'package:washup_owner/commons/models/review.dart';
import 'package:washup_owner/commons/models/schedule_day.dart';
import 'package:washup_owner/commons/models/shift.dart';
import 'package:washup_owner/commons/models/staff_member.dart';
import 'package:washup_owner/commons/models/vendor_report.dart';

import 'fixtures.dart';

void main() {
  group('notification', () {
    test('reads a row', () {
      final item = AppNotification.fromJson(notificationRow);
      expect(item.type, 'new_booking');
      expect(item.title.en, 'New booking');
      expect(item.read, isFalse);
      expect(item.createdAt, DateTime.utc(2026, 11, 1, 10));
      expect(item.markedRead().read, isTrue);
    });

    test('finds the order only in an order link', () {
      String? idOf(String? href) => AppNotification.fromJson({'href': href}).orderId;

      expect(idOf('/orders/ord_1'), 'ord_1');
      expect(idOf('/orders/ord_1?tab=x'), 'ord_1');
      expect(idOf('/orders?tab=active'), isNull);
      expect(idOf('/orders/'), isNull);
      expect(idOf('/reviews'), isNull);
      expect(idOf(null), isNull);
    });
  });

  group('schedule', () {
    test('reads a day with orders, blocks and an over-full slot', () {
      final day = ScheduleDay.fromJson(scheduleDay);
      expect(day.slotIntervalMin, 30);
      expect(day.open, '09:00');
      expect(day.blocks.single.reason, 'صيانة معدات');
      expect(day.slots.first.orders.single.plate, 'ABC 123');
      expect(day.slots[1].fill, 1.25);
      expect(day.slots[2].blocked?.id, 'blk_1');
    });

    test('offers only free future slots and ends after the start', () {
      final day = ScheduleDay.fromJson(scheduleDay);
      expect(day.blockableStarts, ['2099-11-01T11:00:00.000Z', '2099-11-01T11:30:00.000Z']);
      expect(day.endsAfter('2099-11-01T12:00:00.000Z'), [
        '2099-11-01T12:30:00.000Z',
        '2099-11-01T13:00:00.000Z',
      ]);
      expect(day.slotEnd('2099-11-01T11:00:00.000Z'), '2099-11-01T11:30:00.000Z');
    });
  });

  group('services', () {
    test('reads the list with canEdit from meta', () {
      final list = ServiceList.fromReply({
        'data': [serviceRow, addonRow],
        'meta': {'canEdit': true},
      });
      expect(list.canEdit, isTrue);
      expect(list.items.first.branchName.ar, 'فرع 1');
      expect(list.items.last.isAddon, isTrue);
      expect(list.items.last.price, 29.5);
    });

    test('canEdit defaults to no', () {
      expect(ServiceList.fromReply(const {}).canEdit, isFalse);
    });

    test('the switch keeps every other field', () {
      expect(ManagedService.fromJson(serviceRow).payload(active: false), {
        'branchId': 'br_1',
        'name': {'ar': 'غسيل خارجي', 'en': 'Exterior wash'},
        'description': {'ar': 'وصف', 'en': 'Description'},
        'category': 'exterior',
        'type': 'primary',
        'price': 120,
        'durationMin': 30,
        'active': false,
      });
    });
  });

  group('offers', () {
    test('reads the list and its counts', () {
      final list = OfferList.fromReply({
        'data': [offerRow, platformOffer],
        'meta': {
          'counts': {'active': 1, 'scheduled': 1},
        },
      });
      expect(list.counts['active'], 1);
      expect(list.items.first.branchIds, ['br_1']);
      expect(list.items.last.isPlatform, isTrue);
      expect(list.items.last.discountValue, 15.5);
    });

    test('only live editable offers can be switched', () {
      expect(Offer.fromJson(offerRow).canToggle, isTrue);
      expect(Offer.fromJson(platformOffer).canToggle, isFalse);
      expect(Offer.fromJson(draftOffer).canToggle, isFalse);
      expect(Offer.fromJson({...offerRow, 'status': 'expired'}).canToggle, isFalse);
      expect(Offer.fromJson({...offerRow, 'status': 'disabled'}).enabled, isFalse);
    });
  });

  group('staff', () {
    test('reads a member with performance and shifts', () {
      final list = StaffList.fromReply({
        'data': [staffRow()],
        'meta': {
          'counts': {'all': 1, 'employee': 1},
          'onShift': 1,
        },
      });
      final member = list.items.single;
      expect(list.onShift, 1);
      expect(list.counts['employee'], 1);
      expect(member.onShiftNow, isTrue);
      expect(member.performance.rating, 4.5);
      expect(member.permissions['collectPayment'], isTrue);
      expect(member.scheduledShifts.single.days, [0, 1, 2, 3, 4]);
    });

    test('a member without ratings keeps them empty', () {
      final member = StaffMember.fromJson({
        ...staffRow(),
        'performance': {'avgDurationMin': null, 'rating': null, 'completed': 0},
      });
      expect(member.performance.rating, isNull);
      expect(member.performance.avgDurationMin, isNull);
    });

    test('default permissions follow the role', () {
      final employee = StaffMember.defaultPermissions('employee');
      final manager = StaffMember.defaultPermissions('manager');
      expect(employee['runService'], isTrue);
      expect(employee['refund'], isFalse);
      expect(manager['manageStaff'], isTrue);
      expect(manager['editServices'], isFalse);
      expect(employee.keys.toSet(), StaffMember.permissionKeys.toSet());
    });
  });

  group('shifts', () {
    test('reads a row with money that may be missing', () {
      final shift = Shift.fromJson(shiftRow);
      expect(shift.actualCash, 880.5);
      expect(shift.difference, -19.5);
      expect(shift.actualEnd, isNull);
      expect(shift.reviewNote, isNull);

      final open = Shift.fromJson({...shiftRow, 'status': 'open', 'actualCash': null, 'difference': null});
      expect(open.isOpen, isTrue);
      expect(open.actualCash, isNull);
    });

    test('reads details', () {
      final details = ShiftDetails.fromJson(shiftDetails);
      expect(details.shift.staffName, 'Test Worker');
      expect(details.orders.last.method, isNull);
      expect(details.orders.last.paid, isFalse);
      expect(details.auditLogs.single.action, 'review.reply');
    });

    test('reads totals', () {
      final totals = ShiftTotals.fromJson({'expected': 900, 'difference': -19.5});
      expect(totals.difference, -19.5);
    });
  });

  group('day closing', () {
    test('reads an open day', () {
      final day = DayClosing.fromJson(dayClosing(unpaid: 1));
      expect(day.closing, isNull);
      expect(day.expected.of('cash'), 900);
      expect(day.hasOpenOrders, isTrue);
      expect(day.paidOrders, 1);
      expect(day.history.single.actual.total, 1180.5);
    });

    test('reads a closed day', () {
      final day = DayClosing.fromJson(dayClosing(closing: closingRecord));
      expect(day.closing?.difference, -19.5);
      expect(day.closing?.ordersLocked, 8);
      expect(day.closing?.closedAt, DateTime.utc(2026, 10, 31, 20));
    });

    test('the total falls back to the sum', () {
      final amounts = MethodAmounts.fromJson({'cash': 10.5, 'card': 2});
      expect(amounts.total, 12.5);
      expect(amounts.of('unknown'), 0);
    });
  });

  group('customers', () {
    test('reads a row', () {
      final customer = Customer.fromJson(customerRow);
      expect(customer.segment, 'returning');
      expect(customer.totalSpent, 980.5);
      expect(customer.lastVisitAt, isNull);
      expect(customer.plates, ['ABC 123']);
    });

    test('reads details', () {
      final details = CustomerDetails.fromJson(customerDetails);
      expect(details.name, 'Test Customer');
      expect(details.segment, 'returning');
      expect(details.avgTicket, 245.13);
      expect(details.vehicles.single.label, 'Kia Cerato 2021');
      expect(details.orders.single.status, 'completed');
      expect(details.reviews.single.stars, 4);
      expect(details.favoriteServices.single.count, 3);
    });
  });

  group('reviews', () {
    test('reads rows and the header numbers', () {
      final review = Review.fromJson(reviewRow(reply: 'شكرًا', reported: true));
      expect(review.reply, 'شكرًا');
      expect(review.reportedByWash, isTrue);
      expect(review.tags, ['wait', 'something_new']);

      final stats = ReviewStats.fromMeta(reviewsMeta);
      expect(stats.average, 4.3);
      expect(stats.distribution.keys.toList(), [5, 4, 3, 2, 1]);
      expect(stats.distribution[5], 5);
    });

    test('a blank reply counts as none', () {
      expect(Review.fromJson({...reviewRow(), 'reply': ' '}).reply, isNull);
    });
  });

  test('reads a report with mixed values', () {
    final report = VendorReport.fromJson(ordersReport);
    expect(report.type, 'orders');
    expect(report.summary.map((s) => s.format), ['number', 'percent', 'text', 'money']);
    expect(report.summary[2].value, 'غسيل');
    expect(report.chart.length, 14);
    expect(report.columns.first.alignEnd, isFalse);
    expect(report.columns[1].alignEnd, isTrue);
    expect(report.rows.first['gross'], 480.5);
  });

  test('reads finance', () {
    final summary = FinanceSummary.fromJson(finance);
    expect(summary.net, 10800.45);
    expect(summary.commissionRate, 10);
    expect(summary.byMethod.first.method, 'cash');
    expect(summary.byBranch.single.name.en, 'Branch 1');
    expect(summary.byDay.single.revenue, 400);
    expect(summary.pendingCount, 1);
    expect(summary.pendingOrders.single.customerName, isNull);
    expect(summary.payouts.single.amountPaid, isNull);
  });

  test('reads a branch with rules and hours', () {
    final branch = ManagedBranch.fromJson(branchRow);
    expect(branch.workingHours.length, 7);
    expect(branch.workingHours[5].closed, isTrue);
    expect(branch.settings.freeCancelMin, 60);
    expect(branch.amenities, contains('pool'));
    expect(branch.settings.toJson().keys, [
      'autoConfirm',
      'slotIntervalMin',
      'leadTimeMin',
      'maxAdvanceDays',
      'freeCancelMin',
      'noShowGraceMin',
      'reminderMin',
    ]);
  });

  test('reads audit values of any shape', () {
    final entry = AuditEntry.fromJson(auditRow);
    expect(entry.newValue, '120');
    expect(AuditEntry.fromJson({'newValue': 120}).newValue, '120');
    expect(AuditEntry.fromJson({'newValue': {'a': 1}}).newValue, '{"a":1}');
    expect(AuditEntry.fromJson({'branchName': null}).branchName, isNull);
  });

  test('reads settings', () {
    final value = BusinessSettings.fromJson(settings);
    expect(value.business.commissionRate, 10);
    expect(value.business.email, 'owner@example.com');
    expect(value.managerCanEditServices, isFalse);
    expect(value.notificationPrefs['daily_summary'], isFalse);
    expect(value.notificationPrefs.keys.toSet(), BusinessSettings.prefKeys.toSet());
  });

  test('numbers sent as text still read', () {
    expect(ManagedService.fromJson({...serviceRow, 'price': '120.5'}).price, 120.5);
  });

  test('empty rows do not crash any model', () {
    const nothing = <String, dynamic>{};
    AppNotification.fromJson(nothing);
    ScheduleDay.fromJson(nothing);
    ScheduleSlot.fromJson(nothing);
    ScheduleBlock.fromJson(nothing);
    ManagedService.fromJson(nothing);
    Offer.fromJson(nothing);
    StaffMember.fromJson(nothing);
    Shift.fromJson(nothing);
    ShiftDetails.fromJson(nothing);
    DayClosing.fromJson(nothing);
    Customer.fromJson(nothing);
    CustomerDetails.fromJson(nothing);
    Review.fromJson(nothing);
    ReviewStats.fromMeta(nothing);
    VendorReport.fromJson(nothing);
    FinanceSummary.fromJson(nothing);
    ManagedBranch.fromJson(nothing);
    AuditEntry.fromJson(nothing);
    BusinessSettings.fromJson(nothing);
  });

  test('wrong types fall back too', () {
    final customer = Customer.fromJson({'visits': 'many', 'plates': 'ABC', 'totalSpent': {}});
    expect(customer.visits, 0);
    expect(customer.plates, isEmpty);
    expect(customer.totalSpent, 0);
    expect(ScheduleDay.fromJson({'slots': 'none', 'hours': 3}).slots, isEmpty);
  });
}
