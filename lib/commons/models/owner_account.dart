import 'branch_locale.dart';
import 'localized_text.dart';

/// Names match the keys of `permissions` in `/auth/me`.
enum OwnerPermission {
  refund,
  closeShift,
  runService,
  cancelOrder,
  manageStaff,
  editServices,
  collectPayment,
  confirmBooking,
}

class OwnerBranch {
  final String id;
  final LocalizedText name;
  final String area;
  final bool active;
  final int capacity;
  final BranchLocale? locale;

  const OwnerBranch({
    required this.id,
    required this.name,
    required this.area,
    required this.active,
    required this.capacity,
    this.locale,
  });

  factory OwnerBranch.fromJson(Map<String, dynamic> json) => OwnerBranch(
        id: json['id'] as String,
        name: LocalizedText.fromJson(json['name']),
        area: json['area']?.toString() ?? '',
        active: json['active'] == true,
        capacity: (json['capacity'] as num?)?.toInt() ?? 0,
        locale: BranchLocale.fromBranchJson(json),
      );
}

/// The signed-in account, as `/api/v1/vendor/auth/me` returns it. Owners,
/// branch managers and employees share this shape, so screens check
/// [can] and never the role.
class OwnerAccount {
  final String id;
  final String name;
  final String phone;
  final String role;
  final String businessId;
  final LocalizedText businessName;
  final String businessStatus;
  final String? homeBranchId;
  final List<OwnerBranch> branches;
  final Map<String, bool> permissions;
  final num maxDiscountPct;
  final bool canEditServices;

  const OwnerAccount({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.businessId,
    required this.businessName,
    required this.businessStatus,
    required this.homeBranchId,
    required this.branches,
    required this.permissions,
    required this.maxDiscountPct,
    required this.canEditServices,
  });

  /// A permission the server did not send counts as not granted.
  bool can(OwnerPermission permission) => permissions[permission.name] == true;

  factory OwnerAccount.fromJson(Map<String, dynamic> json) => OwnerAccount(
        id: json['id'] as String,
        name: json['name']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        role: json['role']?.toString() ?? '',
        businessId: json['businessId']?.toString() ?? '',
        businessName: LocalizedText.fromJson(json['businessName']),
        businessStatus: json['businessStatus']?.toString() ?? '',
        homeBranchId: json['homeBranchId'] as String?,
        branches: (json['branches'] as List? ?? const [])
            .map((b) => OwnerBranch.fromJson(b as Map<String, dynamic>))
            .toList(),
        permissions: (json['permissions'] as Map? ?? const {})
            .map((key, value) => MapEntry(key.toString(), value == true)),
        maxDiscountPct: json['maxDiscountPct'] as num? ?? 0,
        canEditServices: json['canEditServices'] == true,
      );
}
