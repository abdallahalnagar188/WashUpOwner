import 'package:flutter/material.dart';

import '../../../../commons/widgets/common_widgets.dart';
import '../../../../core/constance/app_colors.dart';
import '../../common/widgets/manage_cards.dart';

class ShiftStatusBadge extends StatelessWidget {
  final String status;

  const ShiftStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return StatusBadge(
      label: labelOr('shifts.status.$status', status),
      color: switch (status) {
        'open' => AppColors.info,
        'submitted' => AppColors.warning,
        'reviewed' => AppColors.success,
        'flagged' => AppColors.danger,
        _ => AppColors.statusNoShow,
      },
    );
  }
}
