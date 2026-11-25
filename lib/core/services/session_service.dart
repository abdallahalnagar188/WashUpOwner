import 'package:get/get.dart';

import '../../commons/models/branch_locale.dart';
import '../../commons/models/owner_account.dart';
import '../data/vendor_api.dart';
import '../network/api_client.dart';
import '../enums/enums.dart';
import '../local/cache_controller.dart';
import '../local/cache_helper.dart';

class SessionService extends GetxService {
  static const String allBranches = 'all';

  final VendorApi _api;

  SessionService(this._api);

  final account = Rxn<OwnerAccount>();
  final branchId = allBranches.obs;

  /// Goes up after any change to an order, so open lists reload.
  final orderChanges = 0.obs;

  bool can(OwnerPermission? permission) =>
      permission == null || (account.value?.can(permission) ?? false);

  /// The platform suspended the wash: it may finish the cars inside but take no new ones.
  bool get suspended => account.value?.businessStatus == 'suspended';

  /// A concrete branch for forms that need one: the selected branch, else the
  /// account's home branch, else its first.
  String? get workingBranchId {
    final current = account.value;
    if (current == null) return null;
    if (branchId.value != allBranches) return branchId.value;
    if (current.homeBranchId != null) return current.homeBranchId;
    return current.branches.isEmpty ? null : current.branches.first.id;
  }

  /// Currency and time zone of [id], else of the working branch.
  BranchLocale? localeOf([String? id]) {
    final branches = account.value?.branches ?? const <OwnerBranch>[];
    final target = id ?? workingBranchId;
    return branches.where((b) => b.id == target).firstOrNull?.locale ??
        branches.map((b) => b.locale).nonNulls.firstOrNull;
  }

  void notifyOrderChanged() => orderChanges.value++;

  /// Reopens the last session. False sends the user to the login page; null
  /// means the server could not be reached, so the session is kept for a retry.
  Future<bool?> restore() async {
    if (!CacheHelper.isLoggedIn) return false;
    try {
      final me = await _api.me();
      if (_isEmployee(me)) {
        await _endEmployeeSession();
        return false;
      }
      _setAccount(me);
      return true;
    } on ApiException catch (e) {
      return e.statusCode == 401 || e.statusCode == 403 ? false : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> signIn({required String phone, required String password}) async {
    final account = await _api.login(phone: phone, password: password);
    // Employees work from the partner web portal (VENDOR_API.md / PARTNER_APP_HANDOFF.md):
    // this app shows owner and manager data, so their session is closed right away (GAP-004).
    if (_isEmployee(account)) {
      await _endEmployeeSession();
      throw ApiException('auth.employeeNotAllowed'.tr, statusCode: 403);
    }
    _setAccount(account);
    await CacheController().setter(key: CacheKeys.loggedIn, value: true);
  }

  static bool _isEmployee(OwnerAccount account) => account.role == 'employee';

  /// Ends the server session when possible; the local session is cleared either way.
  Future<void> _endEmployeeSession() async {
    try {
      await _api.logout();
    } catch (_) {}
    await clearLocal();
  }

  Future<void> signOut() async {
    await _api.logout();
    await clearLocal();
  }

  /// For a session the server already ended.
  Future<void> clearLocal() async {
    await CacheController().logout();
    await CacheController().setter(key: CacheKeys.selectedBranch, value: null);
    account.value = null;
    branchId.value = allBranches;
  }

  void selectBranch(String id) {
    branchId.value = id;
    CacheController().setter(key: CacheKeys.selectedBranch, value: id);
  }

  void _setAccount(OwnerAccount value) {
    account.value = value;
    final saved = CacheController().getter(key: CacheKeys.selectedBranch);
    final stillAllowed = value.branches.any((b) => b.id == saved);
    branchId.value = stillAllowed ? saved as String : allBranches;
  }
}
