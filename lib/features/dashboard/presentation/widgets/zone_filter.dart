import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/zones_repository.dart';

/// Horizontal zone chips shared by shops, drivers, and other list screens.
class ZoneFilter extends ConsumerWidget {
  const ZoneFilter({
    super.key,
    required this.selectedZoneId,
    required this.onZoneChanged,
  });

  final int? selectedZoneId;
  final ValueChanged<int?> onZoneChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zonesAsync = ref.watch(zonesListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.place_outlined, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'filter_by_zone'.tr(),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: zonesAsync.when(
            loading: () => const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, __) => Row(
              children: [
                Expanded(
                  child: Text(
                    'zones_load_failed'.tr(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
                TextButton(
                  onPressed: () => ref.invalidate(zonesListProvider),
                  child: Text('retry'.tr()),
                ),
              ],
            ),
            data: (zones) {
              if (zones.isEmpty) {
                return Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    'no_zones'.tr(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                );
              }

              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: zones.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _ZoneChip(
                      label: 'all_zones'.tr(),
                      selected: selectedZoneId == null,
                      onTap: () => onZoneChanged(null),
                    );
                  }

                  final zone = zones[index - 1];
                  return _ZoneChip(
                    label: zone.name,
                    selected: selectedZoneId == zone.id,
                    onTap: () => onZoneChanged(zone.id),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ZoneChip extends StatelessWidget {
  const _ZoneChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.12)
          : AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
