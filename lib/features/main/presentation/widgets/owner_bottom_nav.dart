import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../controllers/main_controller.dart';

class OwnerBottomNav extends GetView<MainController> {
  const OwnerBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Obx(
            () => Row(
              children: [
                _NavItem(
                  icon: Iconsax.home_2,
                  label: 'nav.home'.tr,
                  selected: controller.selectedIndex.value == MainController.homeTab,
                  onTap: () => controller.changeTab(MainController.homeTab),
                ),
                _NavItem(
                  icon: Iconsax.activity,
                  label: 'nav.live'.tr,
                  selected: controller.selectedIndex.value == MainController.liveTab,
                  onTap: () => controller.changeTab(MainController.liveTab),
                ),
                _NavItem(
                  icon: Iconsax.menu_1,
                  label: 'nav.more'.tr,
                  selected: controller.selectedIndex.value == 2,
                  onTap: () => controller.changeTab(2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.ink500;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22.r, color: color),
            4.height,
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
