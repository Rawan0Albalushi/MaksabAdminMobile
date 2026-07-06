import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';

class RefundStatusChip extends StatelessWidget {
  const RefundStatusChip({super.key, required this.status});

  final String status;

  Color get _color => switch (status) {
        'pending' => AppColors.refundPending,
        'accepted' => AppColors.refundAccepted,
        'canceled' => AppColors.refundCanceled,
        _ => AppColors.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        Formatters.refundStatusLabel(status),
        style: TextStyle(
          color: _color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
