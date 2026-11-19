import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../commons/models/branch_locale.dart';
import '../../../../commons/models/service_item.dart';
import '../../../../core/data/vendor_api.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/helpers/phone_helper.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/utils/utils.dart';

class NewOrderController extends GetxController {
  final _api = Get.find<VendorApi>();
  final session = Get.find<SessionService>();

  final plate = TextEditingController();

  /// The plate as the customer app stores it: Arabic-Indic digits as 0-9.
  String get _plate => plate.text.trim().replaceAllMapped(
        RegExp('[\u0660-\u0669\u06F0-\u06F9]'),
        (m) => String.fromCharCode(48 + (m[0]!.codeUnitAt(0) & 0xF)),
      );
  final phone = TextEditingController();
  final name = TextEditingController();
  final notes = TextEditingController();

  final source = OrderSource.walkIn.obs;
  final branchId = RxnString();

  /// Currency and clock of the chosen branch.
  BranchLocale? get locale => session.localeOf(branchId.value);

  /// Country code of the mobile field, like the login page. Starts as the
  /// chosen branch's country and the user can change it.
  final country = PhoneHelper.defaultCountry.obs;

  /// The typed mobile number parsed for the selected country, null when invalid.
  ParsedPhone? get _parsedPhone => PhoneHelper.parse(phone.text, country.value);

  /// The typed phone in the form the API takes, null while it is not a valid mobile.
  String? get _phone {
    final parsed = _parsedPhone;
    return parsed == null ? null : PhoneHelper.forApi(parsed);
  }

  final services = <ServiceItem>[].obs;
  final selected = <String>{}.obs;
  final loadingServices = true.obs;
  final total = RxnNum();
  final day = DateTime.now().obs;
  final slots = <DateTime>[].obs;
  final slot = Rxn<DateTime>();
  final loadingSlots = false.obs;
  final submitting = false.obs;
  final recognized = false.obs;

  Timer? _recognizeDelay;

  bool get isPhone => source.value == OrderSource.phone;

  @override
  void onInit() {
    super.onInit();
    branchId.value = session.workingBranchId;
    _syncCountry();
    _loadServices();
    plate.addListener(_scheduleRecognize);
    phone.addListener(_scheduleRecognize);
  }

  /// Takes the country of the chosen branch.
  void _syncCountry() {
    country.value = PhoneHelper.forTimezone(locale?.timezone);
  }

  void selectSource(OrderSource value) {
    source.value = value;
    slot.value = null;
    if (value == OrderSource.phone) _loadSlots();
  }

  void selectBranch(String id) {
    branchId.value = id;
    _syncCountry();
    selected.clear();
    total.value = null;
    slots.clear();
    slot.value = null;
    _loadServices();
  }

  void selectDay(DateTime value) {
    day.value = value;
    slot.value = null;
    _loadSlots();
  }

  /// The selected primary services. An order takes exactly one, the rest are add-ons.
  List<ServiceItem> get _selectedPrimary =>
      services.where((s) => !s.isAddon && selected.contains(s.id)).toList();

  /// Adds or removes a service. One primary service per order; add-ons can be
  /// stacked on it and are cleared when it goes.
  void toggleService(String id) {
    final service = services.where((s) => s.id == id).firstOrNull;
    if (service == null) return;

    if (selected.contains(id)) {
      selected.remove(id);
      if (!service.isAddon && _selectedPrimary.isEmpty) {
        final addons = services.where((s) => s.isAddon && selected.contains(s.id)).toList();
        for (final addon in addons) {
          selected.remove(addon.id);
        }
      }
    } else if (service.isAddon) {
      if (_selectedPrimary.isEmpty) {
        Utils.getSnakBar(message: 'newOrder.chooseMainFirst'.tr, type: TosterTypes.warning);
        return;
      }
      selected.add(id);
    } else {
      final previous = _selectedPrimary;
      for (final primary in previous) {
        selected.remove(primary.id);
      }
      selected.add(id);
    }

    slot.value = null;
    _loadPrice();
    if (isPhone) _loadSlots();
  }

  Future<void> _loadServices() async {
    final branch = branchId.value;
    if (branch == null) return;
    loadingServices.value = true;
    try {
      final items = await _api.services(branchId: branch);
      services.assignAll(items.where((s) => s.active));
    } catch (e) {
      Utils.getSnakBar(message: e.toString(), type: TosterTypes.failed);
    } finally {
      loadingServices.value = false;
    }
  }

  Future<void> _loadPrice() async {
    final branch = branchId.value;
    if (branch == null || selected.isEmpty) {
      total.value = null;
      return;
    }
    try {
      total.value = await _api.pricePreview(branchId: branch, serviceIds: selected.toList());
    } catch (_) {
      total.value = services
          .where((s) => selected.contains(s.id))
          .fold<num>(0, (sum, s) => sum + s.price);
    }
  }

  Future<void> _loadSlots() async {
    final branch = branchId.value;
    if (branch == null || selected.isEmpty) {
      slots.clear();
      return;
    }
    loadingSlots.value = true;
    try {
      final d = day.value;
      final date = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      slots.assignAll(await _api.availability(branchId: branch, date: date, serviceIds: selected.toList()));
    } catch (e) {
      slots.clear();
      Utils.getSnakBar(message: e.toString(), type: TosterTypes.failed);
    } finally {
      loadingSlots.value = false;
    }
  }

  void _scheduleRecognize() {
    _recognizeDelay?.cancel();
    final plateReady = plate.text.replaceAll(RegExp(r'[\s-]'), '').length >= 4;
    final phoneReady = _phone != null;
    if (!plateReady && !phoneReady) return;
    _recognizeDelay = Timer(const Duration(milliseconds: 500), () async {
      try {
        final match = await _api.recognize(
          plate: plateReady ? _plate : '',
          phone: phoneReady ? _phone! : '',
        );
        final customer = match?['customer'] as Map<String, dynamic>?;
        if (customer == null) return;
        recognized.value = true;
        if (name.text.isEmpty) name.text = customer['name']?.toString() ?? '';
        if (phone.text.isEmpty) phone.text = customer['phone']?.toString() ?? '';
      } catch (_) {
        // Recognition only saves typing; the form still works without it.
      }
    });
  }

  /// The first problem with the form, or null when it can be submitted.
  String? get _problem {
    if (branchId.value == null) return 'newOrder.chooseBranch'.tr;
    if (plate.text.trim().length < 2) return 'newOrder.needPlate'.tr;
    if (phone.text.trim().isEmpty) return 'newOrder.needPhone'.tr;
    if (_phone == null) return 'newOrder.badPhone'.trParams({'example': country.value.exampleLtr});
    if (_selectedPrimary.length != 1) return 'newOrder.needService'.tr;
    if (isPhone && slot.value == null) return 'newOrder.needSlot'.tr;
    return null;
  }

  Future<void> submit() async {
    if (submitting.value) return;
    final problem = _problem;
    if (problem != null) {
      Utils.getSnakBar(message: problem, type: TosterTypes.warning);
      return;
    }
    // A full international number may belong to another supported country.
    country.value = _parsedPhone!.country;
    submitting.value = true;
    try {
      final id = await _api.createOrder(
        branchId: branchId.value!,
        source: source.value,
        plate: _plate,
        customerPhone: _phone!,
        customerName: name.text.trim(),
        serviceIds: selected.toList(),
        scheduledAt: isPhone ? slot.value : null,
        notes: notes.text.trim(),
      );
      session.notifyOrderChanged();
      Get.offNamed(Routes.orderRoute, arguments: id);
      Utils.getSnakBar(message: 'newOrder.created'.tr, type: TosterTypes.sucsses);
    } catch (e) {
      Utils.getSnakBar(message: e.toString(), type: TosterTypes.failed);
    } finally {
      submitting.value = false;
    }
  }

  @override
  void onClose() {
    _recognizeDelay?.cancel();
    plate.dispose();
    phone.dispose();
    name.dispose();
    notes.dispose();
    super.onClose();
  }
}
