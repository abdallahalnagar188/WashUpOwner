import 'package:get/get.dart';

/// GetX `ever` workers live until disposed; a closed controller would keep
/// reacting (reloads on branch switch, toasts for a page that is gone). Keep
/// them here and they end with the controller (GAP-098).
mixin DisposesWorkers on GetxController {
  final List<Worker> _workers = [];

  void keep(Worker worker) => _workers.add(worker);

  @override
  void onClose() {
    for (final worker in _workers) {
      worker.dispose();
    }
    _workers.clear();
    super.onClose();
  }
}
