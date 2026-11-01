import 'package:get/get.dart';

import '../../../../commons/models/owner_account.dart';
import '../../../../commons/models/staff_member.dart';
import '../../common/controllers/manage_controller.dart';

class StaffController extends LoadController<StaffList> {
  static const List<String> roles = ['all', 'owner', 'manager', 'employee'];

  final role = roles.first.obs;

  bool get canManage => session.can(OwnerPermission.manageStaff);

  /// Role, branch, discount limit and permissions are the owner's to change.
  bool canEdit(StaffMember member) => isOwner && !member.isOwner;

  bool canEditSchedule(StaffMember member) => canManage && !member.isOwner;

  bool canToggle(StaffMember member) {
    if (!canManage || member.isOwner) return false;
    if (member.id == session.account.value?.id) return false;
    return member.role != 'manager' || isOwner;
  }

  /// The highest discount limit this account may hand out.
  num get maxDiscountLimit {
    const cap = 50;
    if (isOwner) return cap;
    final own = session.account.value?.maxDiscountPct ?? 0;
    return own < cap ? own : cap;
  }

  @override
  void onInit() {
    super.onInit();
    load();
    ever(session.branchId, (_) => load());
  }

  @override
  Future<StaffList> fetch() => api.staff(branchId: session.branchId.value);

  List<StaffMember> get visible {
    final items = data.value?.items ?? const <StaffMember>[];
    return role.value == 'all' ? items : items.where((m) => m.role == role.value).toList();
  }

  StaffMember? byId(String id) {
    for (final member in data.value?.items ?? const <StaffMember>[]) {
      if (member.id == id) return member;
    }
    return null;
  }

  Future<bool> create({
    required String name,
    required String phone,
    required String role,
    required String branchId,
    required num maxDiscountPct,
    required Map<String, bool> permissions,
  }) =>
      write(
        () => api.createStaff(
          name: name,
          phone: phone,
          role: role,
          branchId: branchId,
          maxDiscountPct: maxDiscountPct,
          permissions: permissions,
        ),
        reload: () => load(silent: true),
        doneText: 'staff.added'.tr,
      );

  Future<bool> saveMember(
    StaffMember member, {
    required String role,
    required String branchId,
    required num maxDiscountPct,
    required Map<String, bool> permissions,
    required String reason,
  }) =>
      write(
        () => api.updateStaff(
          member.id,
          role: role,
          branchId: branchId,
          maxDiscountPct: maxDiscountPct,
          permissions: permissions,
          reason: reason,
        ),
        reload: () => load(silent: true),
      );

  Future<bool> setActive(StaffMember member, {required String reason}) => write(
        () => api.setStaffActive(member.id, active: !member.active, reason: reason),
        reload: () => load(silent: true),
      );

  Future<bool> saveSchedule(StaffMember member, List<ShiftPattern> shifts) => write(
        () => api.updateStaffSchedule(member.id, shifts),
        reload: () => load(silent: true),
      );
}
