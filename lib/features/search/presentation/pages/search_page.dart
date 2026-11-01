import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/search_result.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../commons/widgets/effects/pressable.dart';
import '../../../../commons/widgets/layout/brand_header.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../controllers/search_controller.dart';

class SearchPage extends GetView<OwnerSearchController> {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          BrandHeader(
            title: 'search.title'.tr,
            leading: HeaderButton(
              icon: Directionality.of(context) == TextDirection.rtl
                  ? Iconsax.arrow_right_3
                  : Iconsax.arrow_left_2,
              onTap: Get.back,
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 8.h),
            child: AppTextField(
              controller: controller.input,
              hint: 'search.hint'.tr,
              autofocus: true,
              onChanged: controller.onChanged,
              prefix: Icon(Iconsax.search_normal_1, size: 20.r, color: AppColors.ink500),
            ),
          ),
          Expanded(child: Obx(_results)),
        ],
      ),
    );
  }

  Widget _results() {
    if (controller.error.value != null) {
      return CustomEmptyState(icon: Iconsax.cloud_cross, title: controller.error.value!);
    }
    if (controller.searching.value && controller.results.isEmpty) {
      return const AppShimmerList(count: 3, itemHeight: 64);
    }
    if (!controller.searched.value) {
      return CustomEmptyState(icon: Iconsax.search_normal_1, title: 'search.prompt'.tr);
    }
    if (controller.results.isEmpty) {
      return CustomEmptyState(icon: Iconsax.search_status, title: 'search.empty'.tr);
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(20.w, 4.h, 20.w, 24.h),
      itemCount: controller.results.length,
      itemBuilder: (_, index) => FadeSlideIn(
        key: ValueKey(controller.results[index].href),
        delay: Duration(milliseconds: 30 * index.clamp(0, 6)),
        child: _ResultTile(result: controller.results[index]),
      ),
    );
  }
}

class _ResultTile extends GetView<OwnerSearchController> {
  final SearchResult result;

  const _ResultTile({required this.result});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final isOrder = result.href.startsWith('/orders');
    return Pressable(
      onTap: () => controller.open(result),
      child: RoundedContainer(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(14.r),
        child: Row(
          children: [
            Icon(
              isOrder ? Iconsax.receipt_2 : Iconsax.user,
              size: 20.r,
              color: AppColors.primary,
            ),
            12.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(result.title, style: text.titleSmall),
                  if (result.subtitle.isNotEmpty)
                    Text(
                      result.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
