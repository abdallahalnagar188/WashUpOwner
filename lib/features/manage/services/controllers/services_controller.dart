import 'package:get/get.dart';

import '../../../../commons/models/managed_service.dart';
import '../../common/controllers/manage_controller.dart';

class ServicesController extends LoadController<ServiceList> {
  final toggling = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    load();
    ever(session.branchId, (_) => load());
  }

  @override
  Future<ServiceList> fetch() => api.services(branchId: session.branchId.value);

  /// Services grouped by branch, in the order they arrived.
  Map<String, List<ManagedService>> get byBranch {
    final groups = <String, List<ManagedService>>{};
    for (final service in data.value?.items ?? const <ManagedService>[]) {
      groups.putIfAbsent(service.branchId, () => []).add(service);
    }
    return groups;
  }

  Future<bool> save({String? id, required Map<String, dynamic> payload}) => write(
        () => api.saveService(id: id, payload: payload),
        reload: () => load(silent: true),
      );

  Future<void> setActive(ManagedService service, bool active) async {
    if (!toggling.add(service.id)) return;
    await save(id: service.id, payload: service.payload(active: active));
    toggling.remove(service.id);
  }
}
