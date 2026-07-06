import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/dashboard_date_filter_provider.dart';

class DashboardDateFilterBar extends ConsumerWidget {
  const DashboardDateFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(dashboardDateFilterProvider);
    final notifier = ref.read(dashboardDateFilterProvider.notifier);
    final now = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.date_range, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'filter_by_date'.tr(),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            if (filter.isActive)
              TextButton.icon(
                onPressed: notifier.clear,
                icon: const Icon(Icons.clear, size: 16),
                label: Text('clear_filter'.tr()),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _DateField(
                label: 'date_from'.tr(),
                value: filter.dateFrom != null
                    ? Formatters.date(filter.dateFrom!)
                    : 'all_periods'.tr(),
                onTap: () => _pickDate(
                  context,
                  initial: filter.dateFrom ?? now,
                  firstDate: DateTime(2020),
                  lastDate: filter.dateTo ?? now,
                  onSelected: notifier.setDateFrom,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DateField(
                label: 'date_to'.tr(),
                value: filter.dateTo != null
                    ? Formatters.date(filter.dateTo!)
                    : 'all_periods'.tr(),
                onTap: () => _pickDate(
                  context,
                  initial: filter.dateTo ?? filter.dateFrom ?? now,
                  firstDate: filter.dateFrom ?? DateTime(2020),
                  lastDate: now,
                  onSelected: notifier.setDateTo,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickDate(
    BuildContext context, {
    required DateTime initial,
    required DateTime firstDate,
    required DateTime lastDate,
    required void Function(DateTime) onSelected,
  }) async {
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('en'),
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onSelected(picked);
    }
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
