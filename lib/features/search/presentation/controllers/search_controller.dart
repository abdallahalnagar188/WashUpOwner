import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../commons/models/search_result.dart';
import '../../../../core/data/vendor_api.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/routing/manage_pages.dart';

class OwnerSearchController extends GetxController {
  static const int minLength = 2;

  final _api = Get.find<VendorApi>();
  final input = TextEditingController();

  final results = <SearchResult>[].obs;
  final searching = false.obs;
  final searched = false.obs;
  final error = RxnString();

  Timer? _delay;
  int _requestId = 0;

  void onChanged(String value) {
    _delay?.cancel();
    final query = value.trim();
    if (query.length < minLength) {
      ++_requestId;
      results.clear();
      searched.value = false;
      searching.value = false;
      return;
    }
    _delay = Timer(const Duration(milliseconds: 350), () => _search(query));
  }

  Future<void> _search(String query) async {
    final id = ++_requestId;
    searching.value = true;
    error.value = null;
    try {
      final found = await _api.search(query);
      if (id != _requestId) return;
      results.assignAll(found);
      searched.value = true;
    } catch (e) {
      if (id == _requestId) error.value = e.toString();
    } finally {
      if (id == _requestId) searching.value = false;
    }
  }

  void open(SearchResult result) {
    final match = RegExp(r'^/(orders|customers)/([^/?]+)').firstMatch(result.href);
    if (match == null) return;
    final route = match.group(1) == 'orders' ? Routes.orderRoute : ManageRoutes.customerRoute;
    Get.toNamed(route, arguments: match.group(2));
  }

  @override
  void onClose() {
    _delay?.cancel();
    input.dispose();
    super.onClose();
  }
}
