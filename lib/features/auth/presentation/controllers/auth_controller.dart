import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/helpers/phone_helper.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/session_service.dart';

class AuthController extends GetxController {
  final phone = TextEditingController();
  final password = TextEditingController();

  final country = PhoneHelper.defaultCountry.obs;
  final hidePassword = true.obs;
  final loading = false.obs;
  final error = RxnString();

  Future<void> submit() async {
    if (loading.value) return;
    if (phone.text.trim().isEmpty || password.text.isEmpty) {
      error.value = 'auth.required'.tr;
      return;
    }
    final parsed = PhoneHelper.parse(phone.text, country.value);
    if (parsed == null) {
      error.value = 'auth.badPhone'.trParams({'example': country.value.exampleLtr});
      return;
    }
    country.value = parsed.country;
    error.value = null;
    loading.value = true;
    try {
      await Get.find<SessionService>().signIn(phone: _loginPhone(parsed), password: password.text);
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

  /// The vendor login has only ever received Egyptian numbers typed locally
  /// ("010..."), so Egypt keeps that form; every other country goes as E.164.
  String _loginPhone(ParsedPhone parsed) =>
      parsed.country == PhoneHelper.defaultCountry ? '0${parsed.number.nsn}' : parsed.e164;

  @override
  void onClose() {
    phone.dispose();
    password.dispose();
    super.onClose();
  }
}
