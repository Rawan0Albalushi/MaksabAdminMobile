import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../data/orders_repository.dart';
import '../domain/order_model.dart';
import 'providers/orders_provider.dart';
import 'widgets/order_detail_widgets.dart';
import 'widgets/select_delivery_man_sheet.dart';
import 'widgets/status_confirm_dialog.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final int orderId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  String? _updatingStatus;
  bool _updatingDeliveryMan = false;

  static const _nextStatuses = {
    'new': ['accepted', 'canceled'],
    'accepted': ['cooking', 'canceled'],
    'cooking': ['ready', 'canceled'],
    'ready': ['on_a_way', 'canceled'],
    'on_a_way': ['delivered', 'canceled'],
  };

  List<String> _transitionsFor(OrderModel order) {
    if (order.isPickup && order.status == 'ready') {
      return ['delivered', 'canceled'];
    }
    return _nextStatuses[order.status] ?? <String>[];
  }

  Future<bool> _confirmStatusChange(String targetStatus) {
    return StatusConfirmDialog.show(
      context,
      targetStatus: targetStatus,
    );
  }

  Future<void> _updateStatus(OrderModel order, String status) async {
    if (!await _confirmStatusChange(status) || !mounted) return;

    setState(() => _updatingStatus = status);
    try {
      await ref
          .read(ordersRepositoryProvider)
          .updateStatus(widget.orderId, status);
      ref.invalidate(orderDetailProvider(widget.orderId));
      ref.read(ordersProvider.notifier).load(refresh: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('status_updated'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _updatingStatus = null);
    }
  }

  Future<void> _changeDeliveryMan(OrderModel order) async {
    await SelectDeliveryManSheet.show(
      context,
      currentDriverId: order.deliveryMan?.id,
      onSelected: (driver) async {
        setState(() => _updatingDeliveryMan = true);
        try {
          await ref
              .read(ordersRepositoryProvider)
              .updateDeliveryMan(widget.orderId, driver.id);
          ref.invalidate(orderDetailProvider(widget.orderId));
          ref.read(ordersProvider.notifier).load(refresh: true);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('delivery_man_updated'.tr())),
            );
          }
        } finally {
          if (mounted) setState(() => _updatingDeliveryMan = false);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderDetailProvider(widget.orderId));
    final padding = Responsive.pagePadding(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(orderDetailProvider(widget.orderId)),
        ),
        data: (OrderModel order) {
          final transitions = _transitionsFor(order);

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(orderDetailProvider(widget.orderId));
              await ref.read(orderDetailProvider(widget.orderId).future);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: OrderDetailHeader(
                    order: order,
                    onBack: () => Navigator.maybePop(context),
                  ),
                ),
                SliverPadding(
                  padding: padding.copyWith(top: 16, bottom: 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      OrderStatusTimeline(
                        status: order.status,
                        isPickup: order.isPickup,
                      ),
                      if (transitions.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        OrderStatusActions(
                          currentStatus: order.status,
                          transitions: transitions,
                          updatingStatus: _updatingStatus,
                          onStatusSelected: (status) =>
                              _updateStatus(order, status),
                        ),
                      ],
                      const SizedBox(height: 12),
                      OrderItemsSection(items: order.items),
                      if (order.items.isNotEmpty) const SizedBox(height: 12),
                      OrderShopSection(order: order),
                      if (!order.isPickup) ...[
                        const SizedBox(height: 12),
                        OrderDeliveryManSection(
                          order: order,
                          updating: _updatingDeliveryMan,
                          onChangeDeliveryMan: () =>
                              _changeDeliveryMan(order),
                        ),
                      ],
                      const SizedBox(height: 12),
                      OrderInfoSection(order: order),
                      if (order.note != null && order.note!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        OrderNoteCard(note: order.note!),
                      ],
                      const SizedBox(height: 12),
                      OrderPriceSummary(order: order),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
