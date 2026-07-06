import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/media_url.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../orders/domain/order_detail_models.dart';
import '../data/refunds_repository.dart';
import 'providers/refunds_provider.dart';
import 'widgets/refund_status_chip.dart';
import 'widgets/refund_status_sheet.dart';

class RefundDetailScreen extends ConsumerStatefulWidget {
  const RefundDetailScreen({super.key, required this.refundId});

  final int refundId;

  @override
  ConsumerState<RefundDetailScreen> createState() => _RefundDetailScreenState();
}

class _RefundDetailScreenState extends ConsumerState<RefundDetailScreen> {
  bool _updating = false;

  Future<void> _updateStatus(String status, String? answer) async {
    setState(() => _updating = true);
    try {
      await ref.read(refundsRepositoryProvider).updateStatus(
            id: widget.refundId,
            status: status,
            answer: answer,
          );
      ref.invalidate(refundDetailProvider(widget.refundId));
      ref.read(refundsProvider.notifier).load(refresh: true);
      ref.invalidate(pendingRefundsCountProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('refund_status_updated'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
      rethrow;
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _quickAccept() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('refund_accept_confirm'.tr()),
        content: Text('refund_accept_confirm_desc'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('no'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('yes'.tr()),
          ),
        ],
      ),
    );
    if (confirmed == true) await _updateStatus('accepted', null);
  }

  @override
  Widget build(BuildContext context) {
    final refundAsync = ref.watch(refundDetailProvider(widget.refundId));
    final padding = Responsive.pagePadding(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('refund_details'.tr()),
        elevation: 0,
      ),
      body: refundAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(refundDetailProvider(widget.refundId)),
        ),
        data: (refund) {
          final order = refund.order;

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(refundDetailProvider(widget.refundId));
              await ref.read(refundDetailProvider(widget.refundId).future);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Container(
                    margin: padding.copyWith(bottom: 0),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.headerGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '#${refund.id}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Spacer(),
                            RefundStatusChip(status: refund.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          Formatters.dateTime(refund.createdAt),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        if (order?.totalPrice != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            Formatters.currency(order!.totalPrice),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: padding.copyWith(top: 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _SectionCard(
                        title: 'refund_info'.tr(),
                        children: [
                          _DetailRow(
                            label: 'refund_cause'.tr(),
                            value: refund.cause ?? '—',
                          ),
                          if (refund.answer != null &&
                              refund.answer!.isNotEmpty)
                            _DetailRow(
                              label: 'refund_answer'.tr(),
                              value: refund.answer!,
                            ),
                        ],
                      ),
                      if (refund.galleries.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _SectionCard(
                          title: 'refund_attachments'.tr(),
                          children: [
                            SizedBox(
                              height: 88,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: refund.galleries.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 10),
                                itemBuilder: (context, index) {
                                  final url = MediaUrl.resolve(
                                    refund.galleries[index].path,
                                  );
                                  if (url == null) {
                                    return const SizedBox.shrink();
                                  }
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: CachedNetworkImage(
                                      imageUrl: url,
                                      width: 88,
                                      height: 88,
                                      fit: BoxFit.cover,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (order != null) ...[
                        const SizedBox(height: 12),
                        _SectionCard(
                          title: 'order_details'.tr(),
                          trailing: TextButton.icon(
                            onPressed: () =>
                                context.push('/orders/${order.id}'),
                            icon: const Icon(Icons.open_in_new, size: 18),
                            label: Text('view_order'.tr()),
                          ),
                          children: [
                            _DetailRow(
                              label: 'order'.tr(),
                              value: '#${Formatters.orderId(order.id)}',
                            ),
                            _DetailRow(
                              label: 'status'.tr(),
                              value: Formatters.orderStatusLabel(order.status),
                            ),
                            if (order.shopName != null)
                              _DetailRow(
                                label: 'shop'.tr(),
                                value: order.shopName!,
                              ),
                            if (order.username != null)
                              _DetailRow(
                                label: 'customer'.tr(),
                                value: order.username!,
                              ),
                            if (order.phone != null)
                              _DetailRow(
                                label: 'phone'.tr(),
                                value: order.phone!,
                              ),
                            _DetailRow(
                              label: 'delivery_type'.tr(),
                              value: Formatters.deliveryTypeLabel(
                                order.deliveryType,
                              ),
                            ),
                            _DetailRow(
                              label: 'address'.tr(),
                              value: order.formattedAddress,
                            ),
                          ],
                        ),
                        if (order.items.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _SectionCard(
                            title: 'order_items'.tr(),
                            children: order.items
                                .map((item) => _OrderItemRow(item: item))
                                .toList(),
                          ),
                        ],
                        const SizedBox(height: 12),
                        _SectionCard(
                          title: 'price_summary'.tr(),
                          children: [
                            _PriceRow(
                              label: 'subtotal'.tr(),
                              value: Formatters.currency(order.itemsSubtotal),
                            ),
                            if (order.deliveryFee != null)
                              _PriceRow(
                                label: 'delivery_fee'.tr(),
                                value: Formatters.currency(order.deliveryFee),
                              ),
                            if (order.tax != null)
                              _PriceRow(
                                label: 'tax'.tr(),
                                value: Formatters.currency(order.tax),
                              ),
                            if (order.serviceFee != null)
                              _PriceRow(
                                label: 'service_fee'.tr(),
                                value: Formatters.currency(order.serviceFee),
                              ),
                            if (order.totalDiscount != null &&
                                order.totalDiscount! > 0)
                              _PriceRow(
                                label: 'discount'.tr(),
                                value:
                                    '- ${Formatters.currency(order.totalDiscount)}',
                              ),
                            const Divider(height: 20),
                            _PriceRow(
                              label: 'total'.tr(),
                              value: Formatters.currency(order.totalPrice),
                              bold: true,
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 100),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: refundAsync.maybeWhen(
        data: (refund) => refund.isPending
            ? SafeArea(
                child: Padding(
                  padding: padding.copyWith(top: 8, bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: MaksabButton(
                          label: 'refund_reject'.tr(),
                          outlined: true,
                          loading: _updating,
                          onPressed: _updating
                              ? null
                              : () => RefundStatusSheet.show(
                                    context,
                                    currentStatus: refund.status,
                                    initialStatus: 'canceled',
                                    onSubmit: _updateStatus,
                                  ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MaksabButton(
                          label: 'refund_accept'.tr(),
                          loading: _updating,
                          onPressed: _updating ? null : _quickAccept,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : SafeArea(
                child: Padding(
                  padding: padding.copyWith(top: 8, bottom: 8),
                  child: MaksabButton(
                    label: 'refund_change_status'.tr(),
                    outlined: true,
                    loading: _updating,
                    onPressed: _updating
                        ? null
                        : () => RefundStatusSheet.show(
                              context,
                              currentStatus: refund.status,
                              onSubmit: _updateStatus,
                            ),
                  ),
                ),
              ),
        orElse: () => null,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
    this.trailing,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
              color: bold ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item});

  final OrderLineItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (MediaUrl.resolve(item.productImage) != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: MediaUrl.resolve(item.productImage)!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.fastfood_outlined, size: 22),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName ?? '—',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${'qty'.tr()}: ${item.quantity}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            Formatters.currency(item.totalPrice),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
