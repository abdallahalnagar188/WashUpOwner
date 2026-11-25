import 'json_read.dart';
import 'localized_text.dart';

/// One weekly pattern; days run 0 = Sunday to 6 = Saturday.
class ShiftPattern {
  final String start;
  final String end;
  final List<int> days;

  const ShiftPattern({required this.start, required this.end, required this.days});

  factory ShiftPattern.fromJson(Map<String, dynamic> json) => ShiftPattern(
        start: readStr(json['start']),
        end: readStr(json['end']),
        days: readInts(json['days']),
      );

  Map<String, dynamic> toJson() => {
        'start': start,
        'end': end,
        'days': [...days]..sort(),
      };
}

class StaffPerformance {
  final int completed;
  final num serviceValue;
  final num? avgDurationMin;
  final num? expectedDurationMin;
  final num? rating;
  final int discountsCount;
  final num discountsAmount;

  const StaffPerformance({
    required this.completed,
    required this.serviceValue,
    required this.avgDurationMin,
    required this.expectedDurationMin,
    required this.rating,
    required this.discountsCount,
    required this.discountsAmount,
  });

  factory StaffPerformance.fromJson(Map<String, dynamic> json) => StaffPerformance(
        completed: readInt(json['completed']),
        serviceValue: readNum(json['serviceValue']),
        avgDurationMin: readNumOrNull(json['avgDurationMin']),
        expectedDurationMin: readNumOrNull(json['expectedDurationMin']),
        rating: readNumOrNull(json['rating']),
        discountsCount: readInt(json['discountsCount']),
        discountsAmount: readNum(json['discountsAmount']),
      );
}

class StaffMember {
  /// Permission keys in the order the dashboard lists them.
  static const List<String> permissionKeys = [
    'runService',
    'collectPayment',
    'confirmBooking',
    'cancelOrder',
    'refund',
    'closeShift',
    'manageStaff',
    'editServices',
  ];

  final String id;
  final String name;
  final String phone;
  final String role;
  final String status;
  final String branchId;
  final LocalizedText branchName;
  final num maxDiscountPct;
  final Map<String, bool> permissions;
  final bool onShiftNow;
  final DateTime? joinedAt;
  final StaffPerformance performance;
  final List<ShiftPattern> scheduledShifts;

  const StaffMember({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.status,
    required this.branchId,
    required this.branchName,
    required this.maxDiscountPct,
    required this.permissions,
    required this.onShiftNow,
    required this.joinedAt,
    required this.performance,
    required this.scheduledShifts,
  });

  bool get active => status == 'active';

  bool get isOwner => role == 'owner';

  /// An Egyptian mobile, with or without the country code.
  static bool validPhone(String text) {
    final digits = text.replaceAll(RegExp(r'\D'), '');
    final String local;
    if (digits.length == 11 && digits.startsWith('01')) {
      local = digits.substring(1);
    } else if (digits.length == 12 && digits.startsWith('20')) {
      local = digits.substring(2);
    } else if (digits.length == 10) {
      local = digits;
    } else {
      return false;
    }
    return RegExp(r'^1[0125]\d{8}$').hasMatch(local);
  }

  /// What a new account of this role starts with, as on the dashboard.
  static Map<String, bool> defaultPermissions(String role) {
    final senior = role != 'employee';
    return {
      'confirmBooking': senior,
      'cancelOrder': senior,
      'closeShift': senior,
      'editServices': role == 'owner',
      'refund': senior,
      'collectPayment': true,
      'runService': true,
      'manageStaff': senior,
    };
  }

  factory StaffMember.fromJson(Map<String, dynamic> json) => StaffMember(
        id: readStr(json['id']),
        name: readStr(json['name']),
        phone: readStr(json['phone']),
        role: readStr(json['role']),
        status: readStr(json['status']),
        branchId: readStr(json['branchId']),
        branchName: LocalizedText.fromJson(json['branchName']),
        maxDiscountPct: readNum(json['maxDiscountPct']),
        permissions: readFlags(json['permissions']),
        onShiftNow: readBool(json['onShiftNow']),
        joinedAt: readDate(json['joinedAt']),
        performance: StaffPerformance.fromJson(readMap(json['performance'])),
        scheduledShifts: readMaps(json['scheduledShifts']).map(ShiftPattern.fromJson).toList(),
      );
}

class StaffList {
  final List<StaffMember> items;
  final Map<String, int> counts;
  final int onShift;

  const StaffList({required this.items, required this.counts, required this.onShift});

  factory StaffList.fromReply(Map<String, dynamic> reply) {
    final meta = readMap(reply['meta']);
    return StaffList(
      items: readMaps(reply['data']).map(StaffMember.fromJson).toList(),
      counts: readCounts(meta['counts']),
      onShift: readInt(meta['onShift']),
    );
  }
}

/// What `POST /vendor/staff` says about the new member's login (GAP-077).
class NewStaffLogin {
  /// Shown once; null when the server made no login.
  final String? password;

  /// The server's text. Without a password it says why (the number already has
  /// a Wash Up login, or the server cannot create logins).
  final String? message;

  const NewStaffLogin({this.password, this.message});

  static final RegExp _inMessage = RegExp(r'المؤقتة\s*[:：]?\s*([A-Za-z0-9_\-]{4,})');

  /// Prefers a structured field; older servers only write it into the message:
  /// "كلمة المرور المؤقتة: XXXX (…)".
  factory NewStaffLogin.fromReply(Map<String, dynamic> reply) {
    final data = reply['data'];
    String? given;
    if (data is Map) {
      final login = data['login'];
      given = (data['tempPassword'] ?? data['temp_password'] ?? (login is Map ? login['tempPassword'] : null))
          ?.toString()
          .trim();
    }
    final message = reply['message']?.toString().trim();
    final password = (given != null && given.isNotEmpty)
        ? given
        : _inMessage.firstMatch(message ?? '')?.group(1);
    return NewStaffLogin(
      password: password,
      message: message == null || message.isEmpty || message.toUpperCase() == 'OK' ? null : message,
    );
  }
}
