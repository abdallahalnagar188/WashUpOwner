import 'package:get/get.dart';

import '../../commons/models/branch_locale.dart';
import '../../commons/models/owner_account.dart';
import '../data/vendor_api.dart';
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

  /// Reopens the last session. False sends the user to the login page.
  Future<bool> restore() async {
    if (!CacheHelper.isLoggedIn) return false;
    try {
      _setAccount(await _api.me());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> signIn({required String phone, required String password}) async {
    _setAccount(await _api.login(phone: phone, password: password));
    await CacheController().setter(key: CacheKeys.loggedIn, value: true);
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
