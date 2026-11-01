import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/order.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../commons/widgets/effects/pressable.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/routing/app_routes.dart';

class CarsInsideSection extends StatelessWidget {
  final List<OrderSummary> cars;

  const CarsInsideSection({super.key, required this.cars});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    if (cars.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Text('home.noCars'.tr, style: text.bodySmall),
      );
    }
    return Column(
      children: [
        for (final car in cars)
          Pressable(
            onTap: () => Get.toNamed(Routes.orderRoute, arguments: car.id),
            child: RoundedContainer(
              margin: EdgeInsets.fromLTRB(20.w, 0, 20.w, 10.h),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              child: Row(
                children: [
                  Container(
                    width: 40.r,
                    height: 40.r,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(13.r),
                    ),
                    child: Icon(Iconsax.car, size: 20.r, color: AppColors.primary),
                  ),
                  12.width,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(car.plate, style: text.titleSmall),
                        Text(car.vehicleLabel, style: text.bodySmall),
                      ],
                    ),
                  ),
                  StatusBadge.order(car.status),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
