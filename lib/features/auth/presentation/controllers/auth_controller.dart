import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/session_service.dart';

class AuthController extends GetxController {
  final phone = TextEditingController();
  final password = TextEditingController();

  final hidePassword = true.obs;
  final loading = false.obs;
  final error = RxnString();

  Future<void> submit() async {
    if (loading.value) return;
    final value = phone.text.trim();
    if (value.isEmpty || password.text.isEmpty) {
      error.value = 'auth.required'.tr;
      return;
    }
    error.value = null;
    loading.value = true;
    try {
      await Get.find<SessionService>().signIn(phone: value, password: password.text);
      password.clear();
      Get.offAllNamed(Routes.mainRoute);
    } on ApiException catch (e) {
      error.value = e.message;
    } catch (_) {
      error.value = 'auth.failed'.tr;
    } finally {
      loading.value = false;
    }
  }

  @override
  void onClose() {
    phone.dispose();
    password.dispose();
    super.onClose();
  }
}
