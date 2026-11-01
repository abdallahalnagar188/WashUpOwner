import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/utils/utils.dart';

/// The server gives a new staff member's password once, so it stays on screen
/// until the owner closes it.
class TempPasswordDialog extends StatelessWidget {
  final String? password;

  const TempPasswordDialog({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final value = password;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      child: Padding(
        padding: EdgeInsets.all(20.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('staff.tempPasswordTitle'.tr, style: text.titleLarge),
            10.height,
            Text(
              (value == null ? 'staff.noTempPassword' : 'staff.tempPasswordBody').tr,
              textAlign: TextAlign.center,
              style: text.bodyMedium,
            ),
            if (value != null) ...[
              14.height,
              SelectableText(
                value,
                textDirection: TextDirection.ltr,
                style: text.headlineSmall,
              ),
              14.height,
              AppButton(
                title: 'staff.copy'.tr,
                variant: AppButtonVariant.sand,
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: value));
                  Utils.getSnakBar(message: 'staff.copied'.tr, type: TosterTypes.sucsses);
                },
              ),
            ],
            10.height,
            AppButton(title: 'staff.done'.tr, onTap: Get.back),
          ],
        ),
      ),
    );
  }
}
