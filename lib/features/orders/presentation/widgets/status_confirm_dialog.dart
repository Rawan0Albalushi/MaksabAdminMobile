import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/shared_widgets.dart';

abstract class StatusConfirmDialog {
  StatusConfirmDialog._();

  static IconData _statusIcon(String status) => switch (status) {
        'accepted' => Icons.check_circle_outline,
        'cooking' => Icons.restaurant_outlined,
        'ready' => Icons.shopping_bag_outlined,
        'on_a_way' => Icons.delivery_dining_outlined,
        'delivered' => Icons.done_all_rounded,
        'canceled' => Icons.cancel_outlined,
        _ => Icons.sync_alt_rounded,
      };

  static Future<bool> show(
    BuildContext context, {
    required String currentStatus,
    required String targetStatus,
  }) async {
    final isCancel = targetStatus == 'canceled';
    final targetLabel = Formatters.orderStatusLabel(targetStatus);
    final actionColor = isCancel ? AppColors.error : AppColors.primary;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: AppColors.textPrimary.withValues(alpha: 0.45),
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: actionColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCancel
                      ? Icons.warning_amber_rounded
                      : _statusIcon(targetStatus),
                  color: actionColor,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                isCancel
                    ? 'cancel_order_confirm'.tr()
                    : 'status_update_confirm'.tr(
                        namedArgs: {'status': targetLabel},
                      ),
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isCancel
                    ? 'cancel_order_confirm_desc'.tr()
                    : 'status_update_confirm_desc'.tr(
                        namedArgs: {'status': targetLabel},
                      ),
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  'status_change_preview'.tr(),
                  style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                        color: AppColors.textHint,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: OrderStatusChip(status: currentStatus),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        context.locale.languageCode == 'ar'
                            ? Icons.arrow_back_rounded
                            : Icons.arrow_forward_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: OrderStatusChip(status: targetStatus),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'no'.tr(),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: actionColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          isCancel ? 'cancel_order'.tr() : 'confirm'.tr(),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return result == true;
  }
}
