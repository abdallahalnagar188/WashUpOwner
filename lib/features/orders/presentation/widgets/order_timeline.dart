import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../commons/models/order.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';

class OrderTimeline extends StatelessWidget {
  final List<OrderTimelineEntry> entries;

  const OrderTimeline({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('orders.timeline'.tr, style: text.titleSmall),
        10.height,
        for (var i = 0; i < entries.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  children: [
                    Container(
                      width: 12.r,
                      height: 12.r,
                      decoration: BoxDecoration(
                        color: StatusBadge.colorFor(entries[i].status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (i < entries.length - 1)
                      Expanded(child: Container(width: 2, color: AppColors.line)),
                  ],
                ),
                12.width,
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 14.h),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('status.${entries[i].status.key}'.tr, style: text.bodyMedium),
                        ),
                        Text(FormatHelper.time(entries[i].at), style: text.bodySmall),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
