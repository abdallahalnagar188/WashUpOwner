// Shapes copied from the vendor API replies and, for writes and rows the demo
// account has none of, from the dashboard's code. All values are made up.

Map<String, dynamic> text(String ar, String en) => {'ar': ar, 'en': en};

Map<String, dynamic> account({String role = 'owner', int branches = 2, Map<String, bool>? permissions}) => {
      'id': 'st_1',
      'name': 'Owner Test',
      'phone': '01000000000',
      'role': role,
      'businessId': 'biz_1',
      'businessName': text('مغسلة', 'Wash'),
      'businessStatus': 'active',
      'homeBranchId': 'br_1',
      'branches': [
        for (var i = 1; i <= branches; i++)
          {'id': 'br_$i', 'name': text('فرع $i', 'Branch $i'), 'area': 'nasr', 'active': true, 'capacity': 4},
      ],
      'permissions': permissions ??
          {
            'refund': true,
            'closeShift': true,
            'runService': true,
            'cancelOrder': true,
            'manageStaff': true,
            'editServices': true,
            'collectPayment': true,
            'confirmBooking': true,
          },
      'maxDiscountPct': 100,
      'canEditServices': true,
    };

final Map<String, dynamic> notificationRow = {
  'id': 'ntf_1',
  'businessId': 'biz_1',
  'branchId': 'br_1',
  'type': 'new_booking',
  'title': text('حجز جديد', 'New booking'),
  'body': text('حجز من التطبيق', 'A booking from the app'),
  'href': '/orders/ord_1',
  'read': false,
  'createdAt': '2026-11-01T10:00:00.000Z',
};

final Map<String, dynamic> blockRow = {
  'id': 'blk_1',
  'start': '2026-11-01T12:00:00.000Z',
  'end': '2026-11-01T12:30:00.000Z',
  'reason': 'صيانة معدات',
};

final Map<String, dynamic> scheduleDay = {
  'branchId': 'br_1',
  'date': '2099-11-01',
  'slotIntervalMin': 30,
  'capacity': 4,
  'hours': {'open': '09:00', 'close': '23:00', 'closed': false},
  'blocks': [blockRow],
  'slots': [
    {
      'start': '2099-11-01T11:00:00.000Z',
      'capacity': 4,
      'occupied': 1,
      'past': false,
      'blocked': null,
      'orders': [
        {
          'id': 'ord_1',
          'number': 'WU-1',
          'plate': 'ABC 123',
          'status': 'confirmed',
          'serviceName': text('غسيل', 'Wash'),
        },
      ],
    },
    {
      'start': '2099-11-01T11:30:00.000Z',
      'capacity': 4,
      'occupied': 5,
      'past': false,
      'blocked': null,
      'orders': [],
    },
    {
      'start': '2099-11-01T12:00:00.000Z',
      'capacity': 4,
      'occupied': 0,
      'past': false,
      'blocked': blockRow,
      'orders': [],
    },
    {
      'start': '2099-11-01T12:30:00.000Z',
      'capacity': 4,
      'occupied': 0,
      'past': true,
      'blocked': null,
      'orders': [],
    },
  ],
};

final Map<String, dynamic> serviceRow = {
  'id': 'svc_1',
  'branchId': 'br_1',
  'branchName': text('فرع 1', 'Branch 1'),
  'name': text('غسيل خارجي', 'Exterior wash'),
  'description': text('وصف', 'Description'),
  'category': 'exterior',
  'type': 'primary',
  'price': 120,
  'durationMin': 30,
  'active': true,
  'ordersCount': 12,
  'revenue30d': 1440,
};

final Map<String, dynamic> addonRow = {
  ...serviceRow,
  'id': 'svc_2',
  'name': text('تلميع', 'Polish'),
  'type': 'addon',
  'price': 29.5,
  'active': false,
};

final Map<String, dynamic> offerRow = {
  'id': 'ofr_1',
  'businessId': 'biz_1',
  'scope': 'wash',
  'title': text('خصم الشتاء', 'Winter deal'),
  'description': text('وصف', 'Description'),
  'discountType': 'percent',
  'discountValue': 20,
  'startAt': '2026-11-01T10:00:00.000Z',
  'endAt': '2026-11-08T10:00:00.000Z',
  'branchIds': ['br_1'],
  'serviceCategories': ['exterior', 'interior'],
  'redemptions': 7,
  'status': 'active',
  'editable': true,
};

final Map<String, dynamic> platformOffer = {
  ...offerRow,
  'id': 'ofr_2',
  'scope': 'platform',
  'status': 'scheduled',
  'editable': false,
  'discountType': 'fixed',
  'discountValue': 15.5,
  'serviceCategories': <String>[],
};

final Map<String, dynamic> draftOffer = {...offerRow, 'id': 'ofr_3', 'status': 'draft'};

Map<String, dynamic> staffRow({String id = 'st_2', String role = 'employee', String status = 'active'}) => {
      'id': id,
      'businessId': 'biz_1',
      'branchId': 'br_1',
      'branchName': text('فرع 1', 'Branch 1'),
      'name': 'Test Worker',
      'phone': '01000000001',
      'role': role,
      'status': status,
      'maxDiscountPct': 10,
      'onShiftNow': true,
      'joinedAt': '2026-01-01T10:00:00.000Z',
      'permissions': {
        'cancelOrder': false,
        'closeShift': false,
        'collectPayment': true,
        'confirmBooking': false,
        'editServices': false,
        'manageStaff': false,
        'refund': false,
        'runService': true,
      },
      'performance': {
        'avgDurationMin': 32,
        'completed': 18,
        'discountsAmount': 40.5,
        'discountsCount': 2,
        'expectedDurationMin': 30,
        'rating': 4.5,
        'serviceValue': 3200,
      },
      'scheduledShifts': [
        {
          'start': '09:00',
          'end': '17:00',
          'days': [0, 1, 2, 3, 4],
        },
      ],
    };

final Map<String, dynamic> shiftRow = {
  'id': 'shf_1',
  'staffName': 'Test Worker',
  'branchName': text('فرع 1', 'Branch 1'),
  'status': 'submitted',
  'scheduledStart': '2026-11-01T06:00:00.000Z',
  'scheduledEnd': '2026-11-01T14:00:00.000Z',
  'actualStart': '2026-11-01T06:05:00.000Z',
  'actualEnd': null,
  'ordersCompleted': 6,
  'cashPayments': 900,
  'cardPayments': 300,
  'expectedCash': 900,
  'actualCash': 880.5,
  'difference': -19.5,
  'reason': 'فكة',
  'reviewNote': null,
  'reviewedBy': null,
};

final Map<String, dynamic> auditRow = {
  'id': 'aud_1',
  'action': 'review.reply',
  'actorId': 'st_1',
  'actorName': 'Owner Test',
  'actorType': 'staff',
  'at': '2026-11-01T10:00:00.000Z',
  'branchId': 'br_1',
  'branchName': text('فرع 1', 'Branch 1'),
  'entity': 'reviews',
  'entityId': 'rvw_1',
  'oldValue': '100',
  'newValue': '120',
  'reason': 'زيادة',
};

final Map<String, dynamic> shiftDetails = {
  'shift': shiftRow,
  'orders': [
    {
      'id': 'ord_1',
      'number': 'WU-1',
      'plate': 'ABC 123',
      'at': '2026-11-01T07:00:00.000Z',
      'method': 'cash',
      'paid': true,
      'total': 120,
    },
    {
      'id': 'ord_2',
      'number': 'WU-2',
      'plate': '',
      'at': null,
      'method': null,
      'paid': false,
      'total': 80,
    },
  ],
  'auditLogs': [auditRow],
};

final Map<String, dynamic> closingRecord = {
  'id': 'cls_1',
  'date': '2026-10-31',
  'expected': {'cash': 900, 'card': 300, 'online': 0, 'total': 1200},
  'actual': {'cash': 880.5, 'card': 300, 'online': 0, 'total': 1180.5},
  'difference': -19.5,
  'reason': 'فكة',
  'closedByName': 'Owner Test',
  'closedAt': '2026-10-31T20:00:00.000Z',
  'ordersLocked': 8,
};

Map<String, dynamic> dayClosing({Map<String, dynamic>? closing, int inService = 0, int unpaid = 0}) => {
      'branchId': 'br_1',
      'branchName': text('فرع 1', 'Branch 1'),
      'date': '2026-11-01',
      'completedOrders': 8,
      'inServiceOrders': inService,
      'unpaidOrders': unpaid,
      'expected': {'cash': 900, 'card': 300, 'online': 0, 'total': 1200},
      'closing': closing,
      'orders': [
        {'id': 'ord_1', 'number': 'WU-1', 'plate': 'ABC 123', 'method': 'cash', 'paid': true, 'total': 120},
        {'id': 'ord_2', 'number': 'WU-2', 'plate': '', 'method': null, 'paid': false, 'total': 80},
      ],
      'history': [closingRecord],
    };

final Map<String, dynamic> customerRow = {
  'id': 'cus_1',
  'name': 'Test Customer',
  'phone': '01000000002',
  'segment': 'returning',
  'visits': 4,
  'totalSpent': 980.5,
  'plates': ['ABC 123'],
  'favoriteService': text('غسيل', 'Wash'),
  'firstVisitAt': '2026-01-01T10:00:00.000Z',
  'lastVisitAt': null,
};

final Map<String, dynamic> customerDetails = {
  'customer': {
    'id': 'cus_1',
    'name': 'Test Customer',
    'phone': '01000000002',
    'status': 'active',
    'statusReason': null,
    'createdAt': '2026-01-01T10:00:00.000Z',
    'lastActiveAt': '2026-11-01T10:00:00.000Z',
  },
  'stats': {
    'avgTicket': 245.13,
    'cancellations': 1,
    'noShows': 1,
    'segment': 'returning',
    'totalSpent': 980.5,
    'visits': 4,
  },
  'favoriteServices': [
    {'name': text('غسيل', 'Wash'), 'count': 3},
  ],
  'vehicles': [
    {
      'id': 'veh_1',
      'customerId': 'cus_1',
      'plate': 'ABC 123',
      'make': 'Kia',
      'model': 'Cerato',
      'year': 2021,
      'color': 'white',
      'isDefault': true,
    },
  ],
  'orders': [
    {
      'id': 'ord_1',
      'number': 'WU-1',
      'plate': 'ABC 123',
      'status': 'completed',
      'paymentStatus': 'paid',
      'total': 120,
      'serviceName': text('غسيل', 'Wash'),
      'branchName': text('فرع 1', 'Branch 1'),
      'scheduledAt': '2026-11-01T10:00:00.000Z',
    },
  ],
  'reviews': [
    {
      'id': 'rvw_1',
      'stars': 4,
      'comment': text('ممتاز', 'Great'),
      'reply': null,
      'createdAt': '2026-11-01T10:00:00.000Z',
    },
  ],
};

Map<String, dynamic> reviewRow({String? reply, bool reported = false}) => {
      'id': 'rvw_1',
      'stars': 2,
      'comment': text('تأخير', 'Late'),
      'tags': ['wait', 'something_new'],
      'customerId': 'cus_1',
      'customerName': 'Test Customer',
      'orderId': 'ord_1',
      'orderNumber': 'WU-1',
      'serviceName': text('غسيل', 'Wash'),
      'branchName': text('فرع 1', 'Branch 1'),
      'reply': reply,
      'replyAt': reply == null ? null : '2026-11-01T11:00:00.000Z',
      'reportedByWash': reported,
      'reportReason': reported ? 'ألفاظ مسيئة' : null,
      'hiddenReason': null,
      'status': 'visible',
      'createdAt': '2026-11-01T10:00:00.000Z',
    };

final Map<String, dynamic> reviewsMeta = {
  'average': 4.3,
  'count': 10,
  'reported': 1,
  'unreplied': 3,
  'distribution': {'1': 1, '2': 1, '3': 1, '4': 2, '5': 5},
};

final Map<String, dynamic> ordersReport = {
  'type': 'orders',
  'from': '2026-10-19T00:00:00.000Z',
  'to': '2026-11-01T23:59:59.000Z',
  'chartKind': 'bar',
  'valueFormat': 'number',
  'summary': [
    {'label': 'إجمالي الطلبات', 'value': 120, 'format': 'number'},
    {'label': 'معدل الإكمال', 'value': 87.5, 'format': 'percent'},
    {'label': 'الأكثر طلبًا', 'value': 'غسيل', 'format': 'text'},
    {'label': 'الإيراد', 'value': 2400.5, 'format': 'money'},
  ],
  'chart': [
    for (var day = 1; day <= 14; day++) {'label': '$day/11', 'value': day * 2},
  ],
  'columns': [
    {'key': 'date', 'label': 'اليوم', 'format': 'text', 'align': 'start'},
    {'key': 'total', 'label': 'الإجمالي', 'format': 'number', 'align': 'end'},
    {'key': 'rate', 'label': 'المعدل', 'format': 'percent', 'align': 'end'},
    {'key': 'gross', 'label': 'الإيراد', 'format': 'money', 'align': 'end'},
    {'key': 'rating', 'label': 'التقييم', 'format': 'number', 'align': 'end'},
    {'key': 'branch', 'label': 'الفرع', 'format': 'text', 'align': 'start'},
  ],
  'rows': [
    {'date': '2026-11-01', 'total': 4, 'rate': 75, 'gross': 480.5, 'rating': 0, 'branch': 'فرع 1'},
    {'date': '2026-10-31', 'total': 2, 'rate': 100, 'gross': 240, 'rating': 4.5, 'branch': 'فرع 1'},
  ],
};

final Map<String, dynamic> finance = {
  'period': '30d',
  'revenue': 12000.5,
  'commission': 1200.05,
  'commissionRate': 10,
  'net': 10800.45,
  'refunds': 120,
  'discounts': 80,
  'paidOrders': 96,
  'byMethod': [
    {'method': 'cash', 'amount': 8000, 'count': 60},
    {'method': 'card', 'amount': 4000.5, 'count': 36},
    {'method': 'online', 'amount': 0, 'count': 0},
  ],
  'byBranch': [
    {'branchId': 'br_1', 'name': text('فرع 1', 'Branch 1'), 'orders': 96, 'revenue': 12000.5},
  ],
  'byDay': [
    {'date': '2026-11-01', 'label': '1/11', 'revenue': 400},
  ],
  'discountsByStaff': <Map<String, dynamic>>[],
  'pendingPayments': {
    'amount': 180,
    'count': 1,
    'orders': [
      {
        'id': 'ord_1',
        'number': 'WU-1',
        'plate': 'ABC 123',
        'customerName': null,
        'serviceName': text('غسيل', 'Wash'),
        'total': 180,
      },
    ],
  },
  'payouts': [
    {
      'id': 'pay_1',
      'periodStart': '2026-10-01T00:00:00.000Z',
      'periodEnd': '2026-10-15T00:00:00.000Z',
      'amountDue': 5000.5,
      'amountPaid': null,
      'status': 'due',
      'reference': null,
      'paidAt': null,
    },
  ],
};

final Map<String, dynamic> branchRow = {
  'id': 'br_1',
  'businessId': 'biz_1',
  'name': text('فرع 1', 'Branch 1'),
  'address': text('شارع 1', 'Street 1'),
  'area': 'nasr',
  'phone': '+20 100 000 0000',
  'capacity': 4,
  'active': true,
  'featured': false,
  'lat': 30.05,
  'lng': 31.33,
  'rating': 4.5,
  'reviewCount': 10,
  'todayOrders': 3,
  'upcomingOrders': 2,
  'servicesCount': 5,
  'staffCount': 4,
  'amenities': ['wifi', 'ac', 'pool'],
  'blockedSlots': <Map<String, dynamic>>[],
  'workingHours': [
    for (var day = 0; day < 7; day++) {'open': '09:00', 'close': '23:00', 'closed': day == 5},
  ],
  'settings': {
    'autoConfirm': true,
    'slotIntervalMin': 30,
    'leadTimeMin': 30,
    'maxAdvanceDays': 14,
    'freeCancelMin': 60,
    'noShowGraceMin': 15,
    'reminderMin': 60,
  },
};

final Map<String, dynamic> settings = {
  'business': {
    'id': 'biz_1',
    'name': text('مغسلة', 'Wash'),
    'phone': '+20 100 000 0000',
    'email': 'owner@example.com',
    'ownerName': 'Owner Test',
    'status': 'active',
    'commissionRate': 10,
  },
  'managerCanEditServices': false,
  'notificationPrefs': {
    'booking_cancelled': true,
    'branch_issue': true,
    'cash_difference': true,
    'daily_summary': false,
    'high_cancellation': true,
    'new_booking': true,
    'payout': true,
    'platform': true,
    'review': true,
  },
  'roleMatrix': <Map<String, dynamic>>[],
};
