import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/utils/system_ui.dart';
import '../controllers/auth_controller.dart';

class LoginPage extends GetView<AuthController> {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUi.onBrand,
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: MediaQuery.paddingOf(context).top + 36.h,
                  bottom: 40.h,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(36.r)),
                ),
                child: Column(
                  children: [
                    FadeSlideIn(child: AppLogo(size: 130.w, onBrand: true)),
                    14.height,
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 120),
                      child: AppWordmark(height: 18.h, onBrand: true),
                    ),
                    10.height,
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 200),
                      child: Text(
                        'auth.partner'.tr,
                        style: text.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
                child: FadeSlideIn(
                  delay: const Duration(milliseconds: 280),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('auth.title'.tr, style: text.headlineMedium),
                      6.height,
                      Text(
                        'auth.body'.tr,
                        style: text.bodyMedium?.copyWith(color: AppColors.ink500),
                      ),
                      24.height,
                      AppTextField(
                        controller: controller.phone,
                        label: 'auth.phone'.tr,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        textDirection: TextDirection.ltr,
                        prefix: Icon(Iconsax.call, size: 20.r, color: AppColors.ink500),
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
                        final message = controller.error.value;
                        return AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          child: message == null
                              ? const SizedBox(width: double.infinity)
                              : Padding(
                                  padding: EdgeInsets.only(top: 12.h),
                                  child: Text(
                                    message,
                                    style: text.bodySmall?.copyWith(color: AppColors.danger),
                                  ),
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
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
