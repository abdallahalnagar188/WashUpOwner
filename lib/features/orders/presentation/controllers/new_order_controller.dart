import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../commons/models/branch_locale.dart';
import '../../../../commons/models/service_item.dart';
import '../../../../core/data/vendor_api.dart';
import '../../../../core/enums/enums.dart';
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
  final services = <ServiceItem>[].obs;
  final selected = <String>{}.obs;
  final loadingServices = true.obs;
  final total = RxnNum();
  final day = DateTime.now().obs;
  final slots = <DateTime>[].obs;
  final slot = Rxn<DateTime>();
  final loadingSlots = false.obs;
  final submitting = false.obs;
  final error = RxnString();
  final recognized = false.obs;

  Timer? _recognizeDelay;

  bool get isPhone => source.value == OrderSource.phone;

  @override
  void onInit() {
    super.onInit();
    branchId.value = session.workingBranchId;
    _loadServices();
    plate.addListener(_scheduleRecognize);
    phone.addListener(_scheduleRecognize);
  }

  void selectSource(OrderSource value) {
    source.value = value;
    slot.value = null;
    if (value == OrderSource.phone) _loadSlots();
  }

  void selectBranch(String id) {
    branchId.value = id;
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

  void toggleService(String id) {
    selected.contains(id) ? selected.remove(id) : selected.add(id);
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
      error.value = e.toString();
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
      error.value = e.toString();
    } finally {
      loadingSlots.value = false;
    }
  }

  void _scheduleRecognize() {
    _recognizeDelay?.cancel();
    final plateReady = plate.text.replaceAll(RegExp(r'[\s-]'), '').length >= 4;
    final phoneReady = phone.text.replaceAll(RegExp(r'\D'), '').length >= 10;
    if (!plateReady && !phoneReady) return;
    _recognizeDelay = Timer(const Duration(milliseconds: 500), () async {
      try {
        final match = await _api.recognize(
          plate: plateReady ? _plate : '',
          phone: phoneReady ? phone.text : '',
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

  String? get _problem {
    if (branchId.value == null) return 'newOrder.chooseBranch'.tr;
    if (plate.text.trim().length < 2) return 'newOrder.needPlate'.tr;
    if (selected.isEmpty) return 'newOrder.needService'.tr;
    if (isPhone) {
      final digits = phone.text.replaceAll(RegExp(r'\D'), '');
      if (digits.length != 11 || !digits.startsWith('01')) return 'newOrder.badPhone'.tr;
      if (slot.value == null) return 'newOrder.needSlot'.tr;
    }
    return null;
  }

  Future<void> submit() async {
    if (submitting.value) return;
    final problem = _problem;
    error.value = problem;
    if (problem != null) return;
    submitting.value = true;
    try {
      final id = await _api.createOrder(
        branchId: branchId.value!,
        source: source.value,
        plate: _plate,
        customerPhone: phone.text.trim(),
        customerName: name.text.trim(),
        serviceIds: selected.toList(),
        scheduledAt: isPhone ? slot.value : null,
        notes: notes.text.trim(),
      );
      session.notifyOrderChanged();
      Get.offNamed(Routes.orderRoute, arguments: id);
      Utils.getSnakBar(message: 'newOrder.created'.tr, type: TosterTypes.sucsses);
    } catch (e) {
      error.value = e.toString();
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
