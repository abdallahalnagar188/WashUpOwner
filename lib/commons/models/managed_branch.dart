import 'json_read.dart';
import 'localized_text.dart';

/// Booking rules of a branch, the `settings` of `PUT /branches/:id/settings`.
class BranchRules {
  static const List<int> slotChoices = [15, 20, 30, 45, 60];

  final bool autoConfirm;
  final num slotIntervalMin;
  final num leadTimeMin;
  final num maxAdvanceDays;
  final num freeCancelMin;
  final num noShowGraceMin;
  final num reminderMin;

  const BranchRules({
    required this.autoConfirm,
    required this.slotIntervalMin,
    required this.leadTimeMin,
    required this.maxAdvanceDays,
    required this.freeCancelMin,
    required this.noShowGraceMin,
    required this.reminderMin,
  });

  factory BranchRules.fromJson(Map<String, dynamic> json) => BranchRules(
        autoConfirm: readBool(json['autoConfirm']),
        slotIntervalMin: readNum(json['slotIntervalMin'], 30),
        leadTimeMin: readNum(json['leadTimeMin']),
        maxAdvanceDays: readNum(json['maxAdvanceDays'], 1),
        freeCancelMin: readNum(json['freeCancelMin']),
        noShowGraceMin: readNum(json['noShowGraceMin'], 5),
        reminderMin: readNum(json['reminderMin'], 5),
      );

  Map<String, dynamic> toJson() => {
        'autoConfirm': autoConfirm,
        'slotIntervalMin': slotIntervalMin,
        'leadTimeMin': leadTimeMin,
        'maxAdvanceDays': maxAdvanceDays,
        'freeCancelMin': freeCancelMin,
        'noShowGraceMin': noShowGraceMin,
        'reminderMin': reminderMin,
      };
}

class WorkingDay {
  final String open;
  final String close;
  final bool closed;

  const WorkingDay({required this.open, required this.close, required this.closed});

  factory WorkingDay.fromJson(Map<String, dynamic> json) => WorkingDay(
        open: readStr(json['open']).isEmpty ? '09:00' : readStr(json['open']),
        close: readStr(json['close']).isEmpty ? '23:00' : readStr(json['close']),
        closed: readBool(json['closed']),
      );

  Map<String, dynamic> toJson() => {'open': open, 'close': close, 'closed': closed};
}

class ManagedBranch {
  static const List<String> knownAmenities = ['waiting', 'ac', 'wifi', 'card', 'coffee', 'covered'];

  final String id;
  final LocalizedText name;
  final LocalizedText address;
  final String area;
  final String phone;
  final int capacity;
  final bool active;
  final num rating;
  final int reviewCount;
  final int todayOrders;
  final int upcomingOrders;
  final int servicesCount;
  final int staffCount;
  final List<String> amenities;

  /// Seven days, Sunday first.
  final List<WorkingDay> workingHours;
  final BranchRules settings;

  const ManagedBranch({
    required this.id,
    required this.name,
    required this.address,
    required this.area,
    required this.phone,
    required this.capacity,
    required this.active,
    required this.rating,
    required this.reviewCount,
    required this.todayOrders,
    required this.upcomingOrders,
    required this.servicesCount,
    required this.staffCount,
    required this.amenities,
    required this.workingHours,
    required this.settings,
  });

  factory ManagedBranch.fromJson(Map<String, dynamic> json) => ManagedBranch(
        id: readStr(json['id']),
        name: LocalizedText.fromJson(json['name']),
        address: LocalizedText.fromJson(json['address']),
        area: readStr(json['area']),
        phone: readStr(json['phone']),
        capacity: readInt(json['capacity']),
        active: readBool(json['active']),
        rating: readNum(json['rating']),
        reviewCount: readInt(json['reviewCount']),
        todayOrders: readInt(json['todayOrders']),
        upcomingOrders: readInt(json['upcomingOrders']),
        servicesCount: readInt(json['servicesCount']),
        staffCount: readInt(json['staffCount']),
        amenities: readStrings(json['amenities']),
        workingHours: readMaps(json['workingHours']).map(WorkingDay.fromJson).toList(),
        settings: BranchRules.fromJson(readMap(json['settings'])),
      );
}
