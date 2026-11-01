import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/session_service.dart';

class AuthController extends GetxController {
  final identifier = TextEditingController();
  final password = TextEditingController();

  final hidePassword = true.obs;
  final loading = false.obs;
  final errorKey = RxnString();

  Future<void> submit() async {
    if (loading.value) return;
    final id = identifier.text.trim();
    if (id.isEmpty || password.text.isEmpty) {
      errorKey.value = 'auth.required';
      return;
    }
    errorKey.value = null;
    loading.value = true;
    try {
      await Get.find<SessionService>().signIn(identifier: id, password: password.text);
      password.clear();
      Get.offAllNamed(Routes.mainRoute);
    } catch (_) {
      errorKey.value = 'auth.failed';
    } finally {
      loading.value = false;
    }
  }

  @override
  void onClose() {
    identifier.dispose();
    password.dispose();
    super.onClose();
  }
}
