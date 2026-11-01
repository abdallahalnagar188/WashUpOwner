import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/constance/app_colors.dart';
import '../../../core/extensions/sized_box_extension.dart';

ShapeBorder get appSheetShape => RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    );

/// Bottom sheet that fits its content, stays clear of the keyboard and never
/// takes the whole screen.
Future<T?> showAppSheet<T>(BuildContext context, Widget child) => showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      shape: appSheetShape,
      builder: (sheet) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheet).bottom),
        child: SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheet).height * 0.8),
            child: child,
          ),
        ),
      ),
    );

/// Handle, title and close button at the top of every sheet.
class AppSheetHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const AppSheetHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(20.w, 8.h, 14.w, 8.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: AppColors.line,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          8.height,
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: text.titleLarge),
                    if (subtitle != null) Text(subtitle!, style: text.bodySmall),
                  ],
                ),
              ),
              8.width,
              Semantics(
                button: true,
                label: 'common.close'.tr,
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Padding(
                    padding: EdgeInsets.all(4.r),
                    child: Container(
                      width: 32.r,
                      height: 32.r,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Iconsax.close_circle, size: 18.r, color: AppColors.ink700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Fixed header over content that scrolls when it is long.
class AppSheetBody extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;

  const AppSheetBody({super.key, required this.title, this.subtitle, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSheetHeader(title: title, subtitle: subtitle),
        Flexible(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(20.w, 2.h, 20.w, 12.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      ],
    );
  }
}
