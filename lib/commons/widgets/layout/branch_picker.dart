import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/constance/app_colors.dart';
import '../../../core/extensions/sized_box_extension.dart';
import '../../../core/services/session_service.dart';

/// Frosted chip on the header showing the branch in view; opens a picker.
class BranchPickerChip extends StatelessWidget {
  const BranchPickerChip({super.key});

  Future<void> _pick(BuildContext context, SessionService session) async {
    final text = Theme.of(context).textTheme;
    final account = session.account.value;
    if (account == null) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        Widget option(String id, String label) => ListTile(
              title: Text(label, style: text.titleSmall),
              trailing: session.branchId.value == id
                  ? Icon(Iconsax.tick_circle5, color: AppColors.primary)
                  : null,
              onTap: () {
                session.selectBranch(id);
                Navigator.of(context).pop();
              },
            );
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(16.r),
                child: Text('home.chooseBranch'.tr, style: text.titleLarge),
              ),
              option(SessionService.allBranches, 'home.allBranches'.tr),
              for (final branch in account.branches) option(branch.id, branch.name.value),
            ],
          ),
        );
      },
    );
  }

  String _label(SessionService session) {
    for (final branch in session.account.value?.branches ?? const []) {
      if (branch.id == session.branchId.value) return branch.name.value;
    }
    return 'home.allBranches'.tr;
  }

  @override
  Widget build(BuildContext context) {
    final session = Get.find<SessionService>();
    return GestureDetector(
      onTap: () => _pick(context, session),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.building, size: 15.r, color: Colors.white),
            6.width,
            Obx(
              () => Text(
                _label(session),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white),
              ),
            ),
            4.width,
            Icon(Iconsax.arrow_down_1, size: 13.r, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
