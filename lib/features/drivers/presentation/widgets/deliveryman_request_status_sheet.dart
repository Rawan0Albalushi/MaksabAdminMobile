import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/shared_widgets.dart';

class DeliverymanRequestStatusSheet extends StatefulWidget {
  const DeliverymanRequestStatusSheet({
    super.key,
    required this.currentStatus,
    required this.onSubmit,
  });

  final String currentStatus;
  final Future<void> Function(String status, String? statusNote) onSubmit;

  static Future<void> show(
    BuildContext context, {
    required String currentStatus,
    required Future<void> Function(String status, String? statusNote) onSubmit,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DeliverymanRequestStatusSheet(
        currentStatus: currentStatus,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<DeliverymanRequestStatusSheet> createState() =>
      _DeliverymanRequestStatusSheetState();
}

class _DeliverymanRequestStatusSheetState
    extends State<DeliverymanRequestStatusSheet> {
  static const _statuses = ['pending', 'approved', 'canceled'];

  late String _selectedStatus;
  final _noteController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentStatus;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  bool get _noteRequired => _selectedStatus == 'canceled';

  Future<void> _submit() async {
    final note = _noteController.text.trim();
    if (_noteRequired) {
      if (note.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('driver_request_note_required'.tr())),
        );
        return;
      }
      if (note.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('driver_request_note_min'.tr())),
        );
        return;
      }
    }

    setState(() => _loading = true);
    try {
      await widget.onSubmit(
        _selectedStatus,
        _noteRequired ? note : null,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            Text(
              'driver_request_change_status'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 16),
            ..._statuses.map((status) {
              final selected = _selectedStatus == status;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: () => setState(() => _selectedStatus = status),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textHint,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'driver_request_status_$status'.tr(),
                              style: TextStyle(
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            if (_noteRequired) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                maxLines: 3,
                maxLength: 250,
                decoration: InputDecoration(
                  labelText: 'note'.tr(),
                  alignLabelWithHint: true,
                ),
              ),
            ],
            const SizedBox(height: 20),
            MaksabButton(
              label: 'confirm'.tr(),
              loading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 8),
            MaksabButton(
              label: 'no'.tr(),
              outlined: true,
              onPressed: _loading ? null : () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
