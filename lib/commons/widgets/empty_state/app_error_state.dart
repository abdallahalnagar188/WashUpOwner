import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/constance/app_colors.dart';
import 'custom_empty_state.dart';

/// Failed load with a retry button.
class AppErrorState extends StatelessWidget {
  final String? message;
  final VoidCallback onRetry;

  const AppErrorState({super.key, this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return CustomEmptyState(
      icon: Iconsax.cloud_cross,
      title: 'error.title'.tr,
      body: message ?? 'error.body'.tr,
      actionText: 'error.retry'.tr,
      onAction: onRetry,
      color: AppColors.danger,
    );
  }
}
