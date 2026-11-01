import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/owner_account.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/services/session_service.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  Future<void> _pickBranch(BuildContext context, OwnerAccount account) async {
    final session = Get.find<SessionService>();
    final text = Theme.of(context).textTheme;
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

  String _branchLabel(OwnerAccount account, String branchId) {
    for (final branch in account.branches) {
      if (branch.id == branchId) return branch.name.value;
    }
    return 'home.allBranches'.tr;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final session = Get.find<SessionService>();
    return Obx(() {
      final account = session.account.value;
      if (account == null) return empty;
      final greeting = DateTime.now().hour < 12 ? 'home.morning' : 'home.evening';
      return Padding(
        padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 8.h),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting.trParams({'name': account.name.split(' ').first}),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.headlineSmall,
                  ),
                  2.height,
                  Text(
                    account.businessName.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
            if (account.branches.length > 1)
              InkWell(
                onTap: () => _pickBranch(context, account),
                borderRadius: BorderRadius.circular(12.r),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Iconsax.building, size: 16.r, color: AppColors.primary),
                      6.width,
                      Text(
                        _branchLabel(account, session.branchId.value),
                        style: text.labelMedium?.copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}
