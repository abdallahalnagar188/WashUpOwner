import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/session_service.dart';

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

  Future<void> _open() async {
    final results = await Future.wait([
      Get.find<SessionService>().restore(),
      Future<bool>.delayed(const Duration(milliseconds: 900), () => true),
    ]);
    Get.offAllNamed(results.first ? Routes.mainRoute : Routes.loginRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(gradient: AppColors.heroGradient),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppLogo(size: 150.w, onBrand: true),
            20.height,
            AppWordmark(height: 22.h, onBrand: true),
          ],
        ),
      ),
    );
  }
}
