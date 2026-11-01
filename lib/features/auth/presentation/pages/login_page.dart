import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../controllers/auth_controller.dart';

class LoginPage extends GetView<AuthController> {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              24.height,
              Center(child: AppLogo(size: 150.w)),
              16.height,
              Center(child: AppWordmark(height: 20.h)),
              40.height,
              Text('auth.title'.tr, style: text.headlineMedium),
              8.height,
              Text(
                'auth.body'.tr,
                style: text.bodyMedium?.copyWith(color: AppColors.ink500),
              ),
              28.height,
              AppTextField(
                controller: controller.identifier,
                label: 'auth.identifier'.tr,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                textDirection: TextDirection.ltr,
                prefix: Icon(Iconsax.user, size: 20.r, color: AppColors.ink500),
              ),
              16.height,
              Obx(
                () => AppTextField(
                  controller: controller.password,
                  label: 'auth.password'.tr,
                  obscureText: controller.hidePassword.value,
                  textInputAction: TextInputAction.done,
                  textDirection: TextDirection.ltr,
                  onSubmitted: (_) => controller.submit(),
                  prefix: Icon(Iconsax.lock, size: 20.r, color: AppColors.ink500),
                  suffix: IconButton(
                    onPressed: controller.hidePassword.toggle,
                    icon: Icon(
                      controller.hidePassword.value ? Iconsax.eye : Iconsax.eye_slash,
                      size: 20.r,
                      color: AppColors.ink500,
                    ),
                  ),
                ),
              ),
              Obx(() {
                final key = controller.errorKey.value;
                if (key == null) return empty;
                return Padding(
                  padding: EdgeInsets.only(top: 12.h),
                  child: Text(
                    key.tr,
                    style: text.bodySmall?.copyWith(color: AppColors.danger),
                  ),
                );
              }),
              24.height,
              Obx(
                () => AppButton(
                  title: 'auth.submit'.tr,
                  loading: controller.loading.value,
                  onTap: controller.submit,
                ),
              ),
              if (AppConfig.useMockData) ...[
                16.height,
                Center(
                  child: Text(
                    'auth.mockHint'.tr,
                    textAlign: TextAlign.center,
                    style: text.bodySmall?.copyWith(color: AppColors.warning),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
