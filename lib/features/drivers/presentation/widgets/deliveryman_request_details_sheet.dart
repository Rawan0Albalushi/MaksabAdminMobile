import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/media_url.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../domain/deliveryman_request_model.dart';
import 'deliveryman_request_status_chip.dart';

class DeliverymanRequestDetailsSheet extends StatelessWidget {
  const DeliverymanRequestDetailsSheet({super.key, required this.request});

  final DeliverymanRequestModel request;

  static Future<void> show(
    BuildContext context, {
    required DeliverymanRequestModel request,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DeliverymanRequestDetailsSheet(request: request),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = request.data;
    final imageUrl = MediaUrl.resolve(data?.imageUrl);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'driver_request_details'.tr(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                DeliverymanRequestStatusChip(status: request.status),
              ],
            ),
            const SizedBox(height: 16),
            if (imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.surfaceVariant,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            _row('id'.tr(), '#${request.id}'),
            _row('driver_request_firstname'.tr(), request.user?.firstname),
            _row('driver_request_lastname'.tr(), request.user?.lastname),
            _row(
              'driver_request_car'.tr(),
              data?.vehicleSummary == '—' ? null : data?.vehicleSummary,
            ),
            _row('driver_request_number'.tr(), data?.number),
            _row('driver_request_color'.tr(), data?.color),
            if (data?.height != null && data!.height!.trim().isNotEmpty)
              _row(
                'driver_request_height'.tr(),
                '${data.height} ${'driver_request_meter'.tr()}',
              ),
            if (data?.width != null && data!.width!.trim().isNotEmpty)
              _row(
                'driver_request_width'.tr(),
                '${data.width} ${'driver_request_meter'.tr()}',
              ),
            _row(
              'status'.tr(),
              data?.online == true
                  ? 'driver_online'.tr()
                  : 'driver_offline'.tr(),
            ),
            if (data?.typeOfTechnique != null)
              _row(
                'driver_request_fuel'.tr(),
                'driver_vehicle_${data!.typeOfTechnique}'.tr(),
              ),
            const SizedBox(height: 16),
            MaksabButton(
              label: 'no'.tr(),
              outlined: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String? value) {
    final text = (value == null || value.trim().isEmpty) ? '—' : value.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
