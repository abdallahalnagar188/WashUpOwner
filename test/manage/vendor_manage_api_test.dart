import 'package:flutter_test/flutter_test.dart';
import 'package:washup_owner/commons/models/managed_branch.dart';
import 'package:washup_owner/commons/models/staff_member.dart';
import 'package:washup_owner/core/data/vendor_manage_api.dart';

import '../helpers/fake_server.dart';
import 'fixtures.dart';

void main() {
  late FakeServer server;
  late VendorManageApi api;

  setUp(() {
    server = FakeServer((_) => FakeReply.ok(null));
    api = VendorManageApi(fakeClient(server, MemoryTokens(access: 'a')));
  });

  void expectSent(String method, String path, Object? body) {
    final request = server.requests.single;
    expect(request.method, method);
    expect(request.path, path);
    expect(request.body, body);
  }

  group('writes', () {
    test('notification read', () async {
      await api.markNotificationRead('ntf_1');
      expectSent('POST', '/vendor/notifications/ntf_1/read', null);
    });

    test('all notifications read', () async {
      await api.markAllNotificationsRead();
      expectSent('POST', '/vendor/notifications/read-all', null);
    });

    test('block a slot', () async {
      await api.blockSlot(
        branchId: 'br_1',
        start: '2026-11-01T11:00:00.000Z',
        end: '2026-11-01T11:30:00.000Z',
        reason: 'صيانة',
      );
      expectSent('POST', '/vendor/schedule/blocks', {
        'branchId': 'br_1',
        'start': '2026-11-01T11:00:00.000Z',
        'end': '2026-11-01T11:30:00.000Z',
        'reason': 'صيانة',
      });
    });

    test('remove a block', () async {
      await api.removeBlock('blk_1');
      expectSent('DELETE', '/vendor/schedule/blocks/blk_1', null);
    });

    Map<String, dynamic> servicePayload({String? reason}) => VendorManageApi.servicePayload(
          branchId: 'br_1',
          nameAr: 'غسيل',
          nameEn: 'Wash',
          descriptionAr: '',
          descriptionEn: '',
          category: 'exterior',
          type: 'addon',
          price: 29.5,
          durationMin: 10,
          active: true,
          reason: reason,
        );

    test('add a service', () async {
      await api.saveService(payload: servicePayload());
      expectSent('POST', '/vendor/services', {
        'branchId': 'br_1',
        'name': {'ar': 'غسيل', 'en': 'Wash'},
        'description': {'ar': '', 'en': ''},
        'category': 'exterior',
        'type': 'addon',
        'price': 29.5,
        'durationMin': 10,
        'active': true,
      });
    });

    test('edit a service, with the reason only when given', () async {
      await api.saveService(id: 'svc_1', payload: servicePayload(reason: 'زيادة'));
      expect(server.requests.single.method, 'PATCH');
      expect(server.requests.single.path, '/vendor/services/svc_1');
      expect(server.requests.single.body?['reason'], 'زيادة');

      expect(servicePayload(reason: '').containsKey('reason'), isFalse);
    });

    Map<String, dynamic> offerPayload({required bool publish, String titleEn = 'Deal'}) =>
        VendorManageApi.offerPayload(
          titleAr: 'عرض',
          titleEn: titleEn,
          descriptionAr: 'وصف',
          descriptionEn: '',
          discountType: 'percent',
          discountValue: 12.5,
          startAt: DateTime.utc(2026, 11, 1, 10),
          endAt: DateTime.utc(2026, 11, 8, 10),
          branchIds: const ['br_1'],
          serviceCategories: const ['deep'],
          publish: publish,
        );

    test('add an offer', () async {
      await api.saveOffer(payload: offerPayload(publish: false));
      expectSent('POST', '/vendor/offers', {
        'title': {'ar': 'عرض', 'en': 'Deal'},
        'description': {'ar': 'وصف', 'en': ''},
        'discountType': 'percent',
        'discountValue': 12.5,
        'startAt': '2026-11-01T10:00:00.000Z',
        'endAt': '2026-11-08T10:00:00.000Z',
        'branchIds': ['br_1'],
        'serviceCategories': ['deep'],
        'publish': false,
      });
    });

    test('an offer title falls back to Arabic', () {
      expect(offerPayload(publish: true, titleEn: '')['title'], {'ar': 'عرض', 'en': 'عرض'});
    });

    test('edit an offer', () async {
      await api.saveOffer(id: 'ofr_1', payload: offerPayload(publish: true));
      expect(server.requests.single.method, 'PATCH');
      expect(server.requests.single.path, '/vendor/offers/ofr_1');
      expect(server.requests.single.body?['publish'], isTrue);
    });

    test('offer on and off', () async {
      await api.setOfferEnabled('ofr_1', false);
      expectSent('POST', '/vendor/offers/ofr_1/status', {'enabled': false});
    });

    const permissions = {
      'runService': true,
      'collectPayment': true,
      'confirmBooking': false,
      'cancelOrder': false,
      'refund': false,
      'closeShift': false,
      'manageStaff': false,
      'editServices': false,
    };

    test('add staff', () async {
      await api.createStaff(
        name: 'Test Worker',
        phone: '01000000001',
        role: 'employee',
        branchId: 'br_1',
        maxDiscountPct: 7.5,
        permissions: permissions,
      );
      expectSent('POST', '/vendor/staff', {
        'name': 'Test Worker',
        'phone': '01000000001',
        'role': 'employee',
        'branchId': 'br_1',
        'maxDiscountPct': 7.5,
        'permissions': permissions,
      });
    });

    test('edit staff sends no name or phone', () async {
      await api.updateStaff(
        'st_2',
        role: 'manager',
        branchId: 'br_2',
        maxDiscountPct: 15,
        permissions: permissions,
        reason: 'ترقية',
      );
      expectSent('PATCH', '/vendor/staff/st_2', {
        'role': 'manager',
        'branchId': 'br_2',
        'maxDiscountPct': 15,
        'permissions': permissions,
        'reason': 'ترقية',
      });
    });

    test('staff status', () async {
      await api.setStaffActive('st_2', active: false, reason: 'إجازة طويلة');
      expectSent('POST', '/vendor/staff/st_2/status', {'active': false, 'reason': 'إجازة طويلة'});
    });

    test('staff schedule, with days in order', () async {
      await api.updateStaffSchedule('st_2', const [
        ShiftPattern(start: '09:00', end: '17:00', days: [3, 0, 1]),
      ]);
      expectSent('PUT', '/vendor/staff/st_2/schedule', {
        'shifts': [
          {
            'start': '09:00',
            'end': '17:00',
            'days': [0, 1, 3],
          },
        ],
      });
    });

    test('shift review', () async {
      await api.reviewShift('shf_1', status: 'flagged', note: 'يحتاج متابعة');
      expectSent('POST', '/vendor/shifts/shf_1/review', {'status': 'flagged', 'note': 'يحتاج متابعة'});
    });

    test('day closing', () async {
      await api.closeDay(
        branchId: 'br_1',
        date: '2026-11-01',
        cash: 880.5,
        card: 300,
        online: 0,
        reason: 'فكة',
      );
      expectSent('POST', '/vendor/day-closing', {
        'branchId': 'br_1',
        'date': '2026-11-01',
        'actual': {'cash': 880.5, 'card': 300, 'online': 0},
        'reason': 'فكة',
      });
    });

    test('day closing leaves out an empty reason', () async {
      await api.closeDay(branchId: 'br_1', date: '2026-11-01', cash: 1, card: 2, online: 3, reason: '');
      expect(server.requests.single.body?.containsKey('reason'), isFalse);
    });

    test('review reply', () async {
      await api.replyToReview('rvw_1', 'شكرًا لك');
      expectSent('POST', '/vendor/reviews/rvw_1/reply', {'text': 'شكرًا لك'});
    });

    test('review report', () async {
      await api.reportReview('rvw_1', 'ألفاظ مسيئة');
      expectSent('POST', '/vendor/reviews/rvw_1/report', {'reason': 'ألفاظ مسيئة'});
    });

    test('edit a branch, leaving the map pin alone', () async {
      await api.updateBranch(
        'br_1',
        nameAr: 'فرع',
        nameEn: 'Branch',
        addressAr: 'شارع',
        addressEn: 'Street',
        phone: '+20 100 000 0000',
        capacity: 6,
        amenities: const ['wifi'],
        workingHours: const [WorkingDay(open: '09:00', close: '00:00', closed: false)],
        active: true,
        reason: 'ساعات الصيف',
      );
      expectSent('PATCH', '/vendor/branches/br_1', {
        'name': {'ar': 'فرع', 'en': 'Branch'},
        'address': {'ar': 'شارع', 'en': 'Street'},
        'phone': '+20 100 000 0000',
        'capacity': 6,
        'amenities': ['wifi'],
        'workingHours': [
          {'open': '09:00', 'close': '00:00', 'closed': false},
        ],
        'active': true,
        'reason': 'ساعات الصيف',
      });
    });

    test('booking rules', () async {
      await api.updateBranchRules(
        'br_1',
        rules: const BranchRules(
          autoConfirm: false,
          slotIntervalMin: 45,
          leadTimeMin: 30,
          maxAdvanceDays: 14,
          freeCancelMin: 60,
          noShowGraceMin: 15,
          reminderMin: 90,
        ),
        reason: 'تقليل الإلغاءات',
      );
      expectSent('PUT', '/vendor/branches/br_1/settings', {
        'settings': {
          'autoConfirm': false,
          'slotIntervalMin': 45,
          'leadTimeMin': 30,
          'maxAdvanceDays': 14,
          'freeCancelMin': 60,
          'noShowGraceMin': 15,
          'reminderMin': 90,
        },
        'reason': 'تقليل الإلغاءات',
      });
    });

    test('business details', () async {
      await api.saveBusinessDetails(
        nameAr: 'مغسلة',
        nameEn: 'Wash',
        phone: '+20 100 000 0000',
        email: 'owner@example.com',
        reason: 'تحديث',
      );
      expectSent('PUT', '/vendor/settings', {
        'business': {
          'name': {'ar': 'مغسلة', 'en': 'Wash'},
          'phone': '+20 100 000 0000',
          'email': 'owner@example.com',
        },
        'reason': 'تحديث',
      });
    });

    test('manager permission', () async {
      await api.saveManagerCanEditServices(true, reason: 'تفويض');
      expectSent('PUT', '/vendor/settings', {'managerCanEditServices': true, 'reason': 'تفويض'});
    });

    test('notification prefs keep platform on', () async {
      await api.saveNotificationPrefs(const {'review': false, 'platform': false}, reason: 'تقليل');
      expectSent('PUT', '/vendor/settings', {
        'notificationPrefs': {'review': false, 'platform': true},
        'reason': 'تقليل',
      });
    });
  });

  group('reads', () {
    test('lists send the branch and drop "all"', () async {
      server = FakeServer((_) => FakeReply.ok(const []));
      api = VendorManageApi(fakeClient(server, MemoryTokens()));

      await api.staff(branchId: 'all');
      await api.services(branchId: 'br_1');
      await api.customers(branchId: 'all', segment: 'lost', page: 2);
      await api.shifts(branchId: 'br_1', filter: 'all');

      expect(server.requests[0].query, {'period': '30d'});
      expect(server.requests[1].query, {'branchId': 'br_1'});
      expect(server.requests[2].query, {'segment': 'lost', 'page': 2});
      expect(server.requests[3].query, {'branchId': 'br_1', 'page': 1});
    });

    test('a page keeps its meta', () async {
      server = FakeServer(
        (_) => FakeReply.ok(
          [notificationRow],
          meta: {'unread': 3},
          pagination: {'total': 21, 'has_next': true},
        ),
      );
      api = VendorManageApi(fakeClient(server, MemoryTokens()));

      final page = await api.notifications(filter: 'unread', page: 2);

      expect(page.items.single.id, 'ntf_1');
      expect(page.total, 21);
      expect(page.hasNext, isTrue);
      expect(page.meta['unread'], 3);
      expect(server.requests.single.query, {'filter': 'unread', 'page': 2});
    });

    test('reports use the server type and dates', () async {
      server = FakeServer((_) => FakeReply.ok(ordersReport));
      api = VendorManageApi(fakeClient(server, MemoryTokens()));

      await api.report(type: 'employees', branchId: 'br_1', from: '2026-10-19', to: '2026-11-01');

      expect(server.requests.single.query, {
        'type': 'employees',
        'branchId': 'br_1',
        'from': '2026-10-19',
        'to': '2026-11-01',
      });
    });

    test('day closing and schedule ask for one day', () async {
      server = FakeServer((request) => FakeReply.ok(request.path.contains('closing') ? dayClosing() : scheduleDay));
      api = VendorManageApi(fakeClient(server, MemoryTokens()));

      await api.dayClosing(branchId: 'br_1', date: '2026-11-01');
      await api.schedule(branchId: 'br_1', date: '2026-11-01');

      for (final request in server.requests) {
        expect(request.query, {'branchId': 'br_1', 'date': '2026-11-01'});
      }
    });

    test('branches, finance and settings read their replies', () async {
      server = FakeServer((request) => FakeReply.ok(switch (request.path) {
            '/vendor/branches' => [branchRow],
            '/vendor/finance' => finance,
            _ => settings,
          }));
      api = VendorManageApi(fakeClient(server, MemoryTokens()));

      expect((await api.branches()).single.id, 'br_1');
      expect((await api.finance(branchId: 'all', period: '30d')).revenue, 12000.5);
      expect((await api.settings()).business.id, 'biz_1');
    });
  });
}
