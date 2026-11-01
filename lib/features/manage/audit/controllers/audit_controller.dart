import 'package:get/get.dart';

import '../../../../commons/models/audit_entry.dart';
import '../../../../core/network/api_client.dart';
import '../../common/controllers/manage_controller.dart';

class AuditController extends PagedController<AuditEntry> {
  @override
  void onInit() {
    super.onInit();
    load();
    ever(session.branchId, (_) => load());
  }

  @override
  Future<ApiPage<AuditEntry>> fetchPage(int page) =>
      api.audit(branchId: session.branchId.value, page: page);
}
