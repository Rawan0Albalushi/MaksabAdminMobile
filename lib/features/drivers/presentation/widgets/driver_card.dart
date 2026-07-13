import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/media_url.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../domain/driver_model.dart';
import 'driver_status_chip.dart';

class DriverCard extends StatelessWidget {
  const DriverCard({super.key, required this.driver, required this.onTap});

  final DriverModel driver;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imgUrl = MediaUrl.resolve(driver.img);
    final setting = driver.setting;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppNetworkAvatar(
                radius: 28,
                imageUrl: imgUrl,
                fallbackText: driver.fullName,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            driver.fullName,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DriverStatusChip(active: driver.active),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (driver.phone != null && driver.phone!.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined,
                              size: 15, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              driver.phone!,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    if (setting != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (setting.typeOfTechnique != null)
                            _badge(
                              'driver_vehicle_${setting.typeOfTechnique}'.tr(),
                              AppColors.primary,
                            ),
                          if (setting.online) ...[
                            const SizedBox(width: 8),
                            _badge('driver_online'.tr(), AppColors.success),
                          ],
                          const Spacer(),
                          if (driver.ratingAvg != null)
                            Row(
                              children: [
                                const Icon(Icons.star_rounded,
                                    size: 14, color: Color(0xFFF9A825)),
                                const SizedBox(width: 2),
                                Text(
                                  driver.ratingAvg!.toStringAsFixed(1),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: AppColors.textHint),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
