import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/owner_account.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../commons/widgets/effects/pressable.dart';
import '../../../../commons/widgets/layout/brand_header.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/data/vendor_api.dart';
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
              FadeSlideIn(child: SectionHeader(title: 'more.manage'.tr)),
              FadeSlideIn(
                delay: const Duration(milliseconds: 70),
                child: Obx(() {
                  final entries = _entries.where((e) => session.can(e.permission)).toList();
                  return _MenuGrid(entries: entries);
                }),
              ),
              FadeSlideIn(
                delay: const Duration(milliseconds: 120),
                child: SectionHeader(title: 'more.preferences'.tr),
              ),
              FadeSlideIn(
                delay: const Duration(milliseconds: 160),
                child: RoundedContainer(
                  margin: EdgeInsets.symmetric(horizontal: 20.w),
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Column(
                    children: [
                      _PreferenceRow(
                        icon: Iconsax.language_square,
                        title: 'more.languageTitle'.tr,
                        onTap: language.toggle,
                        trailing: Text(
                          'more.languageName'.tr,
                          style: text.labelLarge?.copyWith(color: AppColors.primary),
                        ),
                      ),
                      Divider(height: 1, indent: 62.w, color: AppColors.line),
                      _PreferenceRow(
                        icon: Iconsax.moon,
                        title: 'more.darkMode'.tr,
                        trailing: Obx(
                          () => Switch.adaptive(
                            value: theme.isDarkMode.value,
                            onChanged: theme.setDarkMode,
                            activeTrackColor: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              14.height,
              Center(
                child: TextButton.icon(
                  onPressed: controller.logout,
                  icon: Icon(Iconsax.logout, size: 18.r, color: AppColors.danger),
                  label: Text(
                    'more.logout'.tr,
                    style: text.labelLarge?.copyWith(color: AppColors.danger),
                  ),
                ),
              ),
              Center(
                child: Text(
                  'Wash Up Owner ${VendorApi.appVersion}',
                  style: text.labelSmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuGrid extends StatelessWidget {
  final List<_MenuEntry> entries;

  const _MenuGrid({required this.entries});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      itemCount: entries.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10.w,
        mainAxisSpacing: 10.h,
        mainAxisExtent: 92.h,
      ),
      itemBuilder: (_, index) {
        final entry = entries[index];
        return Pressable(
          onTap: () => Get.toNamed(entry.route),
          child: RoundedContainer(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 38.r,
                  height: 38.r,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(13.r),
                  ),
                  child: Icon(entry.icon, size: 20.r, color: AppColors.primary),
                ),
                6.height,
                Text(
                  entry.titleKey.tr,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelSmall?.copyWith(color: AppColors.ink900),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PreferenceRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget trailing;
  final VoidCallback? onTap;

  const _PreferenceRow({
    required this.icon,
    required this.title,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        child: Row(
          children: [
            Container(
              width: 36.r,
              height: 36.r,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, size: 19.r, color: AppColors.primary),
            ),
            12.width,
            Expanded(child: Text(title, style: Theme.of(context).textTheme.bodyMedium)),
            trailing,
          ],
        ),
      ),
    );
  }
}
