import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/local/lang_controller.dart';
import '../../../../core/local/theme_controller.dart';
import '../../../../core/services/session_service.dart';
import '../controllers/more_controller.dart';

class MorePage extends GetView<MoreController> {
  const MorePage({super.key});

  static const List<(IconData, String)> _planned = [
    (Iconsax.calendar_1, 'more.bookings'),
    (Iconsax.receipt_2, 'more.orders'),
    (Iconsax.clock, 'more.schedule'),
    (Iconsax.brush_1, 'more.services'),
    (Iconsax.discount_shape, 'more.offers'),
    (Iconsax.people, 'more.staff'),
    (Iconsax.timer_1, 'more.shifts'),
    (Iconsax.profile_2user, 'more.customers'),
    (Iconsax.star, 'more.reviews'),
    (Iconsax.chart, 'more.reports'),
    (Iconsax.wallet_2, 'more.finance'),
    (Iconsax.building, 'more.branches'),
    (Iconsax.document_text, 'more.audit'),
    (Iconsax.setting_2, 'more.settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final session = Get.find<SessionService>();
    final theme = Get.find<ThemeController>();
    final language = Get.find<LanguageGetxController>();
    return ListView(
      padding: EdgeInsets.only(top: 14.h, bottom: 24.h),
      children: [
        Obx(() {
          final account = session.account.value;
          if (account == null) return empty;
          return RoundedContainer(
            margin: EdgeInsets.symmetric(horizontal: 16.w),
            padding: EdgeInsets.all(14.r),
            child: Row(
              children: [
                InitialsAvatar(name: account.name, size: 52.r),
                12.width,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(account.name, style: text.titleMedium),
                      Text(
                        '${'more.role.${account.role}'.tr} · ${account.businessName.value}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        SectionHeader(title: 'more.manage'.tr),
        RoundedContainer(
          margin: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            children: [
              for (final (icon, key) in _planned)
                ListTile(
                  dense: true,
                  leading: Icon(icon, size: 20.r, color: AppColors.ink500),
                  title: Text(key.tr, style: text.bodyMedium?.copyWith(color: AppColors.ink500)),
                  trailing: Text('common.soon'.tr, style: text.labelSmall),
                ),
            ],
          ),
        ),
        SectionHeader(title: 'more.preferences'.tr),
        RoundedContainer(
          margin: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            children: [
              ListTile(
                dense: true,
                leading: Icon(Iconsax.language_square, size: 20.r, color: AppColors.primary),
                title: Text('more.language'.tr, style: text.bodyMedium),
                onTap: language.toggle,
              ),
              Obx(
                () => SwitchListTile(
                  dense: true,
                  secondary: Icon(Iconsax.moon, size: 20.r, color: AppColors.primary),
                  title: Text('more.darkMode'.tr, style: text.bodyMedium),
                  value: theme.isDarkMode.value,
                  onChanged: theme.setDarkMode,
                ),
              ),
            ],
          ),
        ),
        20.height,
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: AppButton(
            title: 'more.logout'.tr,
            icon: Iconsax.logout,
            variant: AppButtonVariant.danger,
            onTap: controller.logout,
          ),
        ),
      ],
    );
  }
}
