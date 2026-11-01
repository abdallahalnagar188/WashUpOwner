import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/business_settings.dart';
import '../../../../core/helpers/format_helper.dart';
import '../../common/widgets/manage_cards.dart';
import '../../common/widgets/manage_page.dart';
import '../controllers/settings_controller.dart';
import '../widgets/settings_sections.dart';

class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ManagePage(
      title: 'more.settings'.tr,
      body: Obx(
        () => manageLoader(
          ready: controller.data.value != null,
          error: controller.error.value,
          onRetry: controller.load,
          content: () => _content(controller.data.value!),
        ),
      ),
    );
  }

  Widget _content(BusinessSettings settings) {
    final readOnly = !controller.isOwner;
    final business = settings.business;
    return ManageScroll(
      onRefresh: () => controller.load(silent: true),
      children: [
        if (readOnly) NoticeCard(text: 'settings.readOnly'.tr, icon: Iconsax.lock_1),
        BusinessSection(
          key: ValueKey(jsonEncode([business.name.ar, business.name.en, business.phone, business.email])),
          details: business,
          readOnly: readOnly,
          onSave: controller.saveBusiness,
        ),
        SectionCard(
          title: 'settings.account'.tr,
          children: [
            InfoRow('settings.owner'.tr, business.ownerName),
            InfoRow('settings.commission'.tr, '${FormatHelper.number(business.commissionRate)}%'),
            InfoRow('settings.status'.tr, labelOr('settings.status.${business.status}', business.status)),
          ],
        ),
        ManagerEditsSection(
          key: ValueKey(settings.managerCanEditServices),
          value: settings.managerCanEditServices,
          readOnly: readOnly,
          onSave: controller.saveManagerEdits,
        ),
        PrefsSection(
          key: ValueKey(jsonEncode(settings.notificationPrefs)),
          prefs: settings.notificationPrefs,
          readOnly: readOnly,
          onSave: controller.savePrefs,
        ),
      ],
    );
  }
}
