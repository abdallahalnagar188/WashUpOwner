import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../commons/models/service_item.dart';
import '../../../../commons/widgets/common_widgets.dart';
import '../../../../commons/widgets/layout/brand_header.dart';
import '../../../../core/constance/app_colors.dart';
import '../../../../core/enums/enums.dart';
import '../../../../core/extensions/sized_box_extension.dart';
import '../../../../core/helpers/format_helper.dart';
import '../controllers/new_order_controller.dart';

class NewOrderPage extends GetView<NewOrderController> {
  const NewOrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final branches = controller.session.account.value?.branches ?? const [];
    return Scaffold(
      body: Column(
        children: [
          BrandHeader(
            title: 'nav.newOrder'.tr,
            leading: HeaderButton(
              icon: Directionality.of(context) == TextDirection.rtl
                  ? Iconsax.arrow_right_3
                  : Iconsax.arrow_left_2,
              onTap: Get.back,
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
              children: [
                Obx(
                  () => Row(
                    children: [
                      AppChip(
                        label: 'source.walk_in'.tr,
                        icon: Iconsax.car,
                        selected: !controller.isPhone,
                        onTap: () => controller.selectSource(OrderSource.walkIn),
                      ),
                      8.width,
                      AppChip(
                        label: 'source.phone'.tr,
                        icon: Iconsax.call,
                        selected: controller.isPhone,
                        onTap: () => controller.selectSource(OrderSource.phone),
                      ),
                    ],
                  ),
                ),
                if (branches.length > 1) ...[
                  14.height,
                  Obx(
                    () => Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: [
                        for (final branch in branches)
                          AppChip(
                            label: branch.name.value,
                            flat: true,
                            selected: controller.branchId.value == branch.id,
                            onTap: () => controller.selectBranch(branch.id),
                          ),
                      ],
                    ),
                  ),
                ],
                16.height,
                AppTextField(
                  controller: controller.plate,
                  label: 'newOrder.plate'.tr,
                  prefix: Icon(Iconsax.car, size: 20.r, color: AppColors.ink500),
                ),
                12.height,
                AppTextField(
                  controller: controller.phone,
                  label: 'newOrder.phone'.tr,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  prefix: Icon(Iconsax.call, size: 20.r, color: AppColors.ink500),
                ),
                12.height,
                AppTextField(
                  controller: controller.name,
                  label: 'newOrder.name'.tr,
                  prefix: Icon(Iconsax.user, size: 20.r, color: AppColors.ink500),
                ),
                Obx(
                  () => controller.recognized.value
                      ? Padding(
                          padding: EdgeInsets.only(top: 8.h),
                          child: Text(
                            'newOrder.recognized'.tr,
                            style: text.bodySmall?.copyWith(color: AppColors.success),
                          ),
                        )
                      : empty,
                ),
                SectionHeader(
                  title: 'newOrder.services'.tr,
                  padding: EdgeInsets.fromLTRB(0, 20.h, 0, 10.h),
                ),
                Obx(() {
                  if (controller.loadingServices.value) {
                    return const AppShimmerList(count: 2, itemHeight: 60);
                  }
                  return Column(
                    children: [
                      for (final service in controller.services)
                        _ServiceTile(
                          service: service,
                          selected: controller.selected.contains(service.id),
                          onTap: () => controller.toggleService(service.id),
                        ),
                    ],
                  );
                }),
                Obx(() {
                  if (!controller.isPhone) return empty;
                  return const _SlotPicker();
                }),
                16.height,
                AppTextField(
                  controller: controller.notes,
                  label: 'newOrder.notes'.tr,
                  maxLines: 2,
                ),
                Obx(() {
                  final message = controller.error.value;
                  if (message == null) return empty;
                  return Padding(
                    padding: EdgeInsets.only(top: 12.h),
                    child: Text(message, style: text.bodySmall?.copyWith(color: AppColors.danger)),
                  );
                }),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 12.h),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: AppColors.liftShadow,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            ),
            child: SafeArea(
              top: false,
              child: Obx(
                () => Row(
                  children: [
                    if (controller.total.value != null) ...[
                      Text(FormatHelper.money(controller.total.value!, locale: controller.locale), style: text.titleLarge),
                      14.width,
                    ],
                    Expanded(
                      child: AppButton(
                        title: 'newOrder.submit'.tr,
                        loading: controller.submitting.value,
                        onTap: controller.submit,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final ServiceItem service;
  final bool selected;
  final VoidCallback onTap;

  const _ServiceTile({required this.service, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.surface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: selected ? AppColors.primary : AppColors.line),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Iconsax.tick_circle5 : Iconsax.add_circle,
              size: 20.r,
              color: selected ? AppColors.primary : AppColors.ink500,
            ),
            10.width,
            Expanded(child: Text(service.name.value, style: text.titleSmall)),
            Text(FormatHelper.money(service.price, locale: Get.find<NewOrderController>().locale), style: text.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _SlotPicker extends GetView<NewOrderController> {
  const _SlotPicker();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final today = DateTime.now();
    final days = [for (var i = 0; i < 7; i++) today.add(Duration(days: i))];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'newOrder.when'.tr,
          padding: EdgeInsets.fromLTRB(0, 20.h, 0, 10.h),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final day in days) ...[
                AppChip(
                  label: FormatHelper.shortDay(day),
                  flat: true,
                  selected: DateUtils.isSameDay(controller.day.value, day),
                  onTap: () => controller.selectDay(day),
                ),
                8.width,
              ],
            ],
          ),
        ),
        10.height,
        if (controller.loadingSlots.value)
          const Center(child: CircularProgressIndicator())
        else if (controller.selected.isEmpty)
          Text('newOrder.pickServiceFirst'.tr, style: text.bodySmall)
        else if (controller.slots.isEmpty)
          Text('newOrder.noSlots'.tr, style: text.bodySmall)
        else
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              for (final slot in controller.slots)
                AppChip(
                  label: FormatHelper.time(slot, locale: controller.locale),
                  flat: true,
                  selected: controller.slot.value == slot,
                  onTap: () => controller.slot.value = slot,
                ),
            ],
          ),
      ],
    );
  }
}
