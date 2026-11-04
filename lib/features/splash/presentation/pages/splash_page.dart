import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/session_service.dart';
import '../../../../core/utils/system_ui.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _open();
  }

  /// The saved session could not be checked (no internet or a server error).
  bool _unreachable = false;

  Future<void> _open() async {
    if (_unreachable) setState(() => _unreachable = false);
    final results = await Future.wait<bool?>([
      Get.find<SessionService>().restore(),
      Future<bool>.delayed(const Duration(milliseconds: 1100), () => true),
    ]);
    final restored = results.first;
    if (restored == null) {
      if (mounted) setState(() => _unreachable = true);
      return;
    }
    Get.offAllNamed(restored ? Routes.mainRoute : Routes.loginRoute);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUi.onBrand,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          decoration: BoxDecoration(gradient: AppColors.heroGradient),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.7, end: 1),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutBack,
                builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
                child: AppLogo(size: 160.w, onBrand: true),
              ),
              20.height,
              FadeSlideIn(
                delay: const Duration(milliseconds: 250),
                child: AppWordmark(height: 22.h, onBrand: true),
              ),
              12.height,
              FadeSlideIn(
                delay: const Duration(milliseconds: 400),
                child: Text(
                  'auth.partner'.tr,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                ),
              ),
              if (_unreachable) ...[
                28.height,
                Text(
                  'error.offline'.tr,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
                ),
                12.height,
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 48.w),
                  child: AppButton(title: 'error.retry'.tr, variant: AppButtonVariant.sand, onTap: _open),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
