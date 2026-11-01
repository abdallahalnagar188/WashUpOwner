import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/owner_account.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../commons/widgets/layout/brand_header.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/local/lang_controller.dart';
import '../../../../core/local/theme_controller.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/session_service.dart';
import '../controllers/more_controller.dart';

class _MenuEntry {
  final IconData icon;
  final String titleKey;
  final String route;
  final OwnerPermission? permission;

  const _MenuEntry(this.icon, this.titleKey, this.route, [this.permission]);
}

class MorePage extends GetView<MoreController> {
  const MorePage({super.key});

  static const List<_MenuEntry> _entries = [
    _MenuEntry(Iconsax.clock, 'more.schedule', Routes.scheduleRoute),
    _MenuEntry(Iconsax.brush_1, 'more.services', Routes.servicesRoute),
    _MenuEntry(Iconsax.discount_shape, 'more.offers', Routes.offersRoute),
    _MenuEntry(Iconsax.people, 'more.staff', Routes.staffRoute, OwnerPermission.manageStaff),
    _MenuEntry(Iconsax.timer_1, 'more.shifts', Routes.shiftsRoute, OwnerPermission.closeShift),
    _MenuEntry(Iconsax.profile_2user, 'more.customers', Routes.customersRoute),
    _MenuEntry(Iconsax.star, 'more.reviews', Routes.reviewsRoute),
    _MenuEntry(Iconsax.chart, 'more.reports', Routes.reportsRoute),
    _MenuEntry(Iconsax.wallet_2, 'more.finance', Routes.financeRoute),
    _MenuEntry(Iconsax.building, 'more.branches', Routes.branchesRoute),
    _MenuEntry(Iconsax.document_text, 'more.audit', Routes.auditRoute),
    _MenuEntry(Iconsax.setting_2, 'more.settings', Routes.settingsRoute),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final session = Get.find<SessionService>();
    final theme = Get.find<ThemeController>();
    final language = Get.find<LanguageGetxController>();
    return Column(
      children: [
        Obx(() {
          final account = session.account.value;
          return BrandHeader(
            title: account?.name ?? '',
            subtitle: account == null
                ? null
                : '${'more.role.${account.role}'.tr} · ${account.businessName.value}',
            leading: InitialsAvatar(name: account?.name, size: 46.r, sand: true),
          );
        }),
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: EdgeInsets.only(bottom: 120.h),
            children: [
              FadeSlideIn(
                child: SectionHeader(title: 'more.manage'.tr),
              ),
              FadeSlideIn(
                delay: const Duration(milliseconds: 70),
                child: RoundedContainer(
                  margin: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Obx(() {
                    final entries = _entries.where((e) => session.can(e.permission));
                    return Column(
                      children: [
                        for (final entry in entries)
                          ListTile(
                            dense: true,
                            leading: Icon(entry.icon, size: 21.r, color: AppColors.primary),
                            title: Text(entry.titleKey.tr, style: text.bodyMedium),
                            trailing: Icon(
                              Directionality.of(context) == TextDirection.rtl
                                  ? Iconsax.arrow_left_2
                                  : Iconsax.arrow_right_3,
                              size: 16.r,
                              color: AppColors.ink500,
                            ),
                            onTap: () => Get.toNamed(entry.route),
                          ),
                      ],
                    );
                  }),
                ),
              ),
              FadeSlideIn(
                delay: const Duration(milliseconds: 120),
                child: SectionHeader(title: 'more.preferences'.tr),
              ),
              FadeSlideIn(
                delay: const Duration(milliseconds: 160),
                child: RoundedContainer(
                  margin: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    children: [
                      ListTile(
                        dense: true,
                        leading: Icon(Iconsax.language_square, size: 21.r, color: AppColors.primary),
                        title: Text('more.language'.tr, style: text.bodyMedium),
                        onTap: language.toggle,
                      ),
                      Obx(
                        () => SwitchListTile(
                          dense: true,
                          secondary: Icon(Iconsax.moon, size: 21.r, color: AppColors.primary),
                          title: Text('more.darkMode'.tr, style: text.bodyMedium),
                          value: theme.isDarkMode.value,
                          onChanged: theme.setDarkMode,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              20.height,
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: AppButton(
                  title: 'more.logout'.tr,
                  icon: Iconsax.logout,
                  variant: AppButtonVariant.danger,
                  onTap: controller.logout,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
