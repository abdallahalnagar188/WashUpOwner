import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../home/presentation/pages/home_page.dart';
import '../../../live/presentation/pages/live_page.dart';
import '../../../more/presentation/pages/more_page.dart';
import '../controllers/main_controller.dart';
import '../widgets/owner_bottom_nav.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MainController>();
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (AppConfig.useMockData) const _MockDataBanner(),
            Expanded(
              child: Obx(
                () => IndexedStack(
                  index: controller.selectedIndex.value,
                  children: const [HomePage(), LivePage(), MorePage()],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const OwnerBottomNav(),
    );
  }
}

class _MockDataBanner extends StatelessWidget {
  const _MockDataBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      color: AppColors.tint(AppColors.warning),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.info_circle, size: 14.r, color: AppColors.warning),
          6.width,
          Text(
            'common.mockData'.tr,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppColors.warning),
          ),
        ],
      ),
    );
  }
}
