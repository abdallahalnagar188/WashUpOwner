import '../../../../commons/models/managed_branch.dart';
import '../../common/controllers/manage_controller.dart';

class BranchesController extends LoadController<List<ManagedBranch>> {
  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  Future<List<ManagedBranch>> fetch() => api.branches();

  ManagedBranch? byId(String id) {
    for (final branch in data.value ?? const <ManagedBranch>[]) {
      if (branch.id == id) return branch;
    }
    return null;
  }

  Future<bool> saveBranch(
    ManagedBranch branch, {
    required String nameAr,
    required String nameEn,
    required String addressAr,
    required String addressEn,
    required String phone,
    required num capacity,
    required List<String> amenities,
    required List<WorkingDay> workingHours,
    required bool active,
    required String reason,
  }) =>
      write(
        () => api.updateBranch(
          branch.id,
          nameAr: nameAr,
          nameEn: nameEn.isEmpty ? branch.name.en : nameEn,
          addressAr: addressAr,
          addressEn: addressEn.isEmpty ? branch.address.en : addressEn,
          phone: phone,
          capacity: capacity,
          amenities: amenities,
          workingHours: workingHours,
          active: active,
          reason: reason,
        ),
        reload: () => load(silent: true),
      );

  Future<bool> updateRules(ManagedBranch branch, BranchRules rules, String reason) => write(
        () => api.updateBranchRules(branch.id, rules: rules, reason: reason),
        reload: () => load(silent: true),
      );
}
