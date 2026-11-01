import 'json_read.dart';
import 'localized_text.dart';

class BusinessDetails {
  final String id;
  final LocalizedText name;
  final String phone;
  final String email;
  final String ownerName;
  final String status;

  /// A percentage: 10 means 10%.
  final num commissionRate;

  const BusinessDetails({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.ownerName,
    required this.status,
    required this.commissionRate,
  });

  factory BusinessDetails.fromJson(Map<String, dynamic> json) => BusinessDetails(
        id: readStr(json['id']),
        name: LocalizedText.fromJson(json['name']),
        phone: readStr(json['phone']),
        email: readStr(json['email']),
        ownerName: readStr(json['ownerName']),
        status: readStr(json['status']),
        commissionRate: readNum(json['commissionRate']),
      );
}

class BusinessSettings {
  /// `platform` is always on: it carries account and policy messages.
  static const String alwaysOnPref = 'platform';

  static const List<String> prefKeys = [
    'new_booking',
    'booking_cancelled',
    'cash_difference',
    'high_cancellation',
    'branch_issue',
    'review',
    'daily_summary',
    'payout',
    'platform',
  ];

  final BusinessDetails business;
  final bool managerCanEditServices;
  final Map<String, bool> notificationPrefs;

  const BusinessSettings({
    required this.business,
    required this.managerCanEditServices,
    required this.notificationPrefs,
  });

  factory BusinessSettings.fromJson(Map<String, dynamic> json) => BusinessSettings(
        business: BusinessDetails.fromJson(readMap(json['business'])),
        managerCanEditServices: readBool(json['managerCanEditServices']),
        notificationPrefs: readFlags(json['notificationPrefs']),
      );
}
