import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/media_url.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../domain/deliveryman_request_model.dart';
import 'deliveryman_request_status_chip.dart';

class DeliverymanRequestCard extends StatelessWidget {
  const DeliverymanRequestCard({
    super.key,
    required this.request,
    required this.onViewDetails,
    this.onChangeStatus,
  });

  final DeliverymanRequestModel request;
  final VoidCallback onViewDetails;
  final VoidCallback? onChangeStatus;

  @override
  Widget build(BuildContext context) {
    final data = request.data;
    final imageUrl = MediaUrl.resolve(data?.imageUrl);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppNetworkAvatar(
                  radius: 28,
                  imageUrl: imageUrl,
                  fallbackText: request.displayName,
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
                              request.displayName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DeliverymanRequestStatusChip(status: request.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '#${request.id}',
                        style: const TextStyle(
                          color: AppColors.textHint,
                          fontSize: 12,
                        ),
                      ),
                      if (data != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          data.vehicleSummary,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (data.number != null &&
                            data.number!.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${'driver_request_number'.tr()}: ${data.number}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        if (data.typeOfTechnique != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'driver_vehicle_${data.typeOfTechnique}'.tr(),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onViewDetails,
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: Text('driver_request_details'.tr()),
                  ),
                ),
                if (request.canChangeStatus && onChangeStatus != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onChangeStatus,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: Text('driver_request_change_status'.tr()),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
