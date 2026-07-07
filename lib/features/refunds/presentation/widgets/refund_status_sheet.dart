import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/shared_widgets.dart';

class RefundStatusSheet extends StatefulWidget {
  const RefundStatusSheet({
    super.key,
    required this.currentStatus,
    required this.onSubmit,
    this.initialStatus,
  });

  final String currentStatus;
  final String? initialStatus;
  final Future<void> Function(String status, String? answer) onSubmit;

  static Future<void> show(
    BuildContext context, {
    required String currentStatus,
    required Future<void> Function(String status, String? answer) onSubmit,
    String? initialStatus,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RefundStatusSheet(
        currentStatus: currentStatus,
        initialStatus: initialStatus,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<RefundStatusSheet> createState() => _RefundStatusSheetState();
}

class _RefundStatusSheetState extends State<RefundStatusSheet> {
  static const _statuses = ['pending', 'accepted', 'canceled'];

  late String _selectedStatus;
  final _answerController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus ?? widget.currentStatus;
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  bool get _answerRequired => _selectedStatus != 'accepted';

  Future<void> _submit() async {
    if (_answerRequired && _answerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('refund_answer_required'.tr())),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await widget.onSubmit(
        _selectedStatus,
        _answerRequired ? _answerController.text.trim() : null,
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
            'refund_change_status'.tr(),
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
                            Formatters.refundStatusLabel(status),
                            style: TextStyle(
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
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
          if (_answerRequired) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _answerController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'refund_answer'.tr(),
                hintText: 'refund_answer_hint'.tr(),
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
