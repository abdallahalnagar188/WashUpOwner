import 'package:get/get.dart';

import '../../../../commons/models/customer.dart';
import '../../../../commons/models/json_read.dart';
import '../../../../core/network/api_client.dart';
import '../../common/controllers/manage_controller.dart';

class CustomersController extends PagedController<Customer> {
  static const List<String> segments = ['all', 'new', 'returning', 'lost'];

  final segment = segments.first.obs;

  Map<String, int> get counts => readCounts(meta['counts']);

  @override
  void onInit() {
    super.onInit();
    load();
    ever(session.branchId, (_) => load());
  }

  @override
  Future<ApiPage<Customer>> fetchPage(int page) =>
      api.customers(branchId: session.branchId.value, segment: segment.value, page: page);

  void selectSegment(String value) {
    if (segment.value == value) return;
    segment.value = value;
    load();
  }
}

class CustomerDetailsController extends LoadController<CustomerDetails> {
  final String customerId;

  CustomerDetailsController(this.customerId);

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  Future<CustomerDetails> fetch() => api.customer(customerId);
}
