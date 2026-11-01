import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/live_board.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';

class CarsInsideSection extends StatelessWidget {
  final List<LiveOrder> cars;

  const CarsInsideSection({super.key, required this.cars});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    if (cars.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Text('home.noCars'.tr, style: text.bodySmall),
      );
    }
    return Column(
      children: [
        for (final car in cars)
          RoundedContainer(
            margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            child: Row(
              children: [
                Icon(Iconsax.car, size: 20.r, color: AppColors.primary),
                10.width,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(car.plate, style: text.titleSmall),
                      Text(car.vehicle, style: text.bodySmall),
                    ],
                  ),
                ),
                StatusBadge.order(car.status),
              ],
            ),
          ),
      ],
    );
  }
}
