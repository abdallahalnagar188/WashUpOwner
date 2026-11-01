import 'package:get/get.dart';

import '../../commons/models/owner_account.dart';
import '../data/owner_repo.dart';
import '../enums/enums.dart';
import '../local/cache_controller.dart';
import '../local/cache_helper.dart';

class SessionService extends GetxService {
  static const String allBranches = 'all';

  final OwnerRepo _repo;

  SessionService(this._repo);

  final account = Rxn<OwnerAccount>();
  final branchId = allBranches.obs;

  bool can(OwnerPermission permission) => account.value?.can(permission) ?? false;

  /// Reopens the last session. False sends the user to the login page.
  Future<bool> restore() async {
    if (!CacheHelper.isLoggedIn) return false;
    try {
      _setAccount(await _repo.me());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> signIn({required String identifier, required String password}) async {
    _setAccount(await _repo.signIn(identifier: identifier, password: password));
    await CacheController().setter(key: CacheKeys.loggedIn, value: true);
  }

  Future<void> signOut() async {
    try {
      await _repo.signOut();
    } finally {
      await CacheController().logout();
      await CacheController().setter(key: CacheKeys.selectedBranch, value: null);
      account.value = null;
      branchId.value = allBranches;
    }
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
