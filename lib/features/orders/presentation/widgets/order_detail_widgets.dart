import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/media_url.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../domain/order_detail_models.dart';
import '../../domain/order_model.dart';

class OrderDetailHeader extends StatelessWidget {
  const OrderDetailHeader({
    super.key,
    required this.order,
    this.onBack,
  });

  final OrderModel order;
  final VoidCallback? onBack;

  void _copyToClipboard(BuildContext context, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('copied'.tr())),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logoUrl = MediaUrl.resolve(order.shopLogo);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.paddingOf(context).top + 12,
          20,
          28,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: onBack ?? () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'order_details'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (logoUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CachedNetworkImage(
                      imageUrl: logoUrl,
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _shopPlaceholder(),
                      errorWidget: (_, __, ___) => _shopPlaceholder(),
                    ),
                  )
                else
                  _shopPlaceholder(),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.shopName ?? '—',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (order.shopNumber != null) ...[
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => _copyToClipboard(
                            context,
                            order.shopNumber!,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${'shop_number'.tr()}: ${order.shopNumber}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.copy_outlined,
                                size: 13,
                                color: Colors.white.withValues(alpha: 0.65),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () => _copyToClipboard(
                          context,
                          order.id.toString(),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '#${Formatters.orderId(order.id)}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.copy_outlined,
                              size: 14,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _HeaderStat(
                    icon: Icons.payments_outlined,
                    label: 'total'.tr(),
                    value: Formatters.currency(order.totalPrice),
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: Colors.white.withValues(alpha: 0.25),
                ),
                Expanded(
                  child: _HeaderStat(
                    icon: Icons.shopping_bag_outlined,
                    label: 'items'.tr(),
                    value: Formatters.number(
                      order.orderDetailsCount ?? order.items.length,
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 36,
                  color: Colors.white.withValues(alpha: 0.25),
                ),
                Expanded(
                  child: _HeaderStat(
                    icon: Icons.local_shipping_outlined,
                    label: 'delivery_type'.tr(),
                    value: Formatters.deliveryTypeLabel(order.deliveryType),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _shopPlaceholder() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.store_outlined, color: Colors.white, size: 26),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class OrderStatusTimeline extends StatelessWidget {
  const OrderStatusTimeline({
    super.key,
    required this.status,
    required this.isPickup,
  });

  final String status;
  final bool isPickup;

  static const _deliverySteps = [
    'new',
    'accepted',
    'cooking',
    'ready',
    'on_a_way',
    'delivered',
  ];

  static const _pickupSteps = [
    'new',
    'accepted',
    'cooking',
    'ready',
    'delivered',
  ];

  static Color _statusColor(String step) => switch (step) {
        'new' => AppColors.statusNew,
        'accepted' => AppColors.statusAccepted,
        'cooking' => AppColors.statusCooking,
        'ready' => AppColors.statusReady,
        'on_a_way' => AppColors.statusOnWay,
        'delivered' => AppColors.statusDelivered,
        'canceled' => AppColors.statusCanceled,
        _ => AppColors.textSecondary,
      };

  static IconData _iconFor(String step) => switch (step) {
        'new' => Icons.receipt_long_outlined,
        'accepted' => Icons.check_circle_outline,
        'cooking' => Icons.restaurant_outlined,
        'ready' => Icons.shopping_bag_outlined,
        'on_a_way' => Icons.delivery_dining_outlined,
        'delivered' => Icons.done_all_rounded,
        _ => Icons.circle_outlined,
      };

  @override
  Widget build(BuildContext context) {
    if (status == 'canceled') {
      return _SectionCard(
        title: 'order_progress'.tr(),
        trailing: OrderStatusChip(status: status),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.statusCanceled.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.statusCanceled.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.statusCanceled.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cancel_outlined,
                  color: AppColors.statusCanceled,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'canceled'.tr(),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.statusCanceled,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'order_canceled_desc'.tr(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final steps = isPickup ? _pickupSteps : _deliverySteps;
    final currentIndex = steps.indexOf(status).clamp(0, steps.length - 1);

    return _SectionCard(
      title: 'order_progress'.tr(),
      trailing: OrderStatusChip(status: status),
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            _VerticalTimelineStep(
              label: Formatters.orderStatusLabel(steps[i]),
              icon: _iconFor(steps[i]),
              accentColor: _statusColor(steps[i]),
              state: i < currentIndex
                  ? _StepState.completed
                  : i == currentIndex
                      ? _StepState.current
                      : _StepState.upcoming,
              isLast: i == steps.length - 1,
            ),
        ],
      ),
    );
  }
}

enum _StepState { completed, current, upcoming }

class _VerticalTimelineStep extends StatelessWidget {
  const _VerticalTimelineStep({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.state,
    required this.isLast,
  });

  final String label;
  final IconData icon;
  final Color accentColor;
  final _StepState state;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final isCompleted = state == _StepState.completed;
    final isCurrent = state == _StepState.current;
    final circleColor = isCompleted
        ? AppColors.success
        : isCurrent
            ? accentColor
            : AppColors.textHint;
    final lineColor =
        isCompleted ? AppColors.success : AppColors.border;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: circleColor.withValues(
                      alpha: isCurrent ? 0.16 : 0.12,
                    ),
                    shape: BoxShape.circle,
                    border: isCurrent
                        ? Border.all(color: circleColor, width: 2)
                        : null,
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_rounded : icon,
                    size: 18,
                    color: circleColor,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: lineColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: isCurrent
                    ? BoxDecoration(
                        color: accentColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.3),
                        ),
                      )
                    : null,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: isCurrent
                                  ? FontWeight.w700
                                  : isCompleted
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                              color: isCurrent
                                  ? accentColor
                                  : isCompleted
                                      ? AppColors.textPrimary
                                      : AppColors.textHint,
                            ),
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'order_progress_now'.tr(),
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OrderItemsSection extends StatelessWidget {
  const OrderItemsSection({super.key, required this.items});

  final List<OrderLineItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return _SectionCard(
      title: 'order_items'.tr(),
      trailing: Text(
        '${items.length} ${'items'.tr()}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 20),
            _OrderItemTile(item: items[i]),
          ],
        ],
      ),
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  const _OrderItemTile({required this.item});

  final OrderLineItem item;

  @override
  Widget build(BuildContext context) {
    final imageUrl = MediaUrl.resolve(item.productImage);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _imagePlaceholder(),
                  errorWidget: (_, __, ___) => _imagePlaceholder(),
                )
              : _imagePlaceholder(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName ?? '—',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '${'qty'.tr()}: ${item.quantity}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              if (item.addons.isNotEmpty) ...[
                const SizedBox(height: 4),
                ...item.addons.map(
                  (addon) => Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '+ ${addon.productName ?? '—'} × ${addon.quantity}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                    ),
                  ),
                ),
              ],
              if (item.note != null && item.note!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  item.note!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.warning,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            ],
          ),
        ),
        Text(
          Formatters.currency(item.totalPrice),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
        ),
      ],
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 52,
      height: 52,
      color: AppColors.surfaceVariant,
      child: const Icon(Icons.fastfood_outlined, color: AppColors.textHint),
    );
  }
}

class OrderDeliveryManSection extends StatelessWidget {
  const OrderDeliveryManSection({
    super.key,
    required this.order,
    this.onChangeDeliveryMan,
    this.updating = false,
  });

  final OrderModel order;
  final VoidCallback? onChangeDeliveryMan;
  final bool updating;

  bool get _showPendingMessage =>
      order.status == 'new' || order.status == 'accepted';

  bool get _canChange =>
      !order.isPickup &&
      order.status != 'canceled' &&
      onChangeDeliveryMan != null;

  void _copyPhone(BuildContext context, String phone) {
    Clipboard.setData(ClipboardData(text: phone));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('copied'.tr())),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (order.isPickup) return const SizedBox.shrink();

    final deliveryMan = order.deliveryMan;
    final driverUuid = deliveryMan?.uuid?.trim();
    final canOpenDriver = driverUuid != null && driverUuid.isNotEmpty;
    final hasDriver = deliveryMan != null;

    return _SectionCard(
      title: 'delivery_man'.tr(),
      trailing: _canChange
          ? TextButton.icon(
              onPressed: updating ? null : onChangeDeliveryMan,
              icon: updating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      hasDriver
                          ? Icons.swap_horiz_rounded
                          : Icons.person_add_alt_1_outlined,
                      size: 18,
                    ),
              label: Text(
                hasDriver
                    ? 'change_delivery_man'.tr()
                    : 'assign_delivery_man'.tr(),
              ),
            )
          : null,
      child: deliveryMan != null
          ? Column(
              children: [
                InkWell(
                  onTap: canOpenDriver
                      ? () => context.push('/drivers/$driverUuid')
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        AppNetworkAvatar(
                          radius: 28,
                          imageUrl: MediaUrl.resolve(deliveryMan.image),
                          fallbackText: deliveryMan.name,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            deliveryMan.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (canOpenDriver)
                          const Icon(
                            Icons.chevron_right,
                            color: AppColors.textHint,
                          ),
                      ],
                    ),
                  ),
                ),
                if (deliveryMan.phone != null &&
                    deliveryMan.phone!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _InfoTile(
                    icon: Icons.phone_outlined,
                    label: 'phone'.tr(),
                    value: deliveryMan.phone!,
                    onTap: () => _copyPhone(context, deliveryMan.phone!),
                    trailing: const Icon(Icons.copy_outlined, size: 16),
                  ),
                ],
                if (deliveryMan.email != null &&
                    deliveryMan.email!.isNotEmpty)
                  _InfoTile(
                    icon: Icons.email_outlined,
                    label: 'email'.tr(),
                    value: deliveryMan.email!,
                  ),
              ],
            )
          : Text(
              _showPendingMessage
                  ? 'delivery_man_pending'.tr()
                  : 'delivery_man_not_assigned'.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
    );
  }
}

class OrderShopSection extends StatelessWidget {
  const OrderShopSection({super.key, required this.order});

  final OrderModel order;

  void _copyPhone(BuildContext context, String phone) {
    Clipboard.setData(ClipboardData(text: phone));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('copied'.tr())),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (order.shopName == null && order.shopNumber == null) {
      return const SizedBox.shrink();
    }

    return _SectionCard(
      title: 'shop_info'.tr(),
      child: Column(
        children: [
          if (order.shopName != null)
            _InfoTile(
              icon: Icons.store_outlined,
              label: 'shop'.tr(),
              value: order.shopName!,
            ),
          if (order.shopNumber != null)
            _InfoTile(
              icon: Icons.phone_outlined,
              label: 'shop_number'.tr(),
              value: order.shopNumber!,
              onTap: () => _copyPhone(context, order.shopNumber!),
              trailing: const Icon(Icons.copy_outlined, size: 16),
            ),
        ],
      ),
    );
  }
}

class OrderInfoSection extends StatelessWidget {
  const OrderInfoSection({super.key, required this.order});

  final OrderModel order;

  void _copyPhone(BuildContext context, String phone) {
    Clipboard.setData(ClipboardData(text: phone));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('copied'.tr())),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'customer_info'.tr(),
      child: Column(
        children: [
          _InfoTile(
            icon: Icons.person_outline,
            label: 'customer'.tr(),
            value: order.username ?? '—',
          ),
          _InfoTile(
            icon: Icons.phone_outlined,
            label: 'phone'.tr(),
            value: order.phone ?? '—',
            onTap: order.phone != null && order.phone!.isNotEmpty
                ? () => _copyPhone(context, order.phone!)
                : null,
            trailing: order.phone != null && order.phone!.isNotEmpty
                ? const Icon(Icons.copy_outlined, size: 16)
                : null,
          ),
          if (!order.isPickup && order.formattedAddress != '—')
            _InfoTile(
              icon: Icons.location_on_outlined,
              label: 'address'.tr(),
              value: order.formattedAddress,
            ),
          if (order.deliveryDate != null && order.deliveryDate!.isNotEmpty)
            _InfoTile(
              icon: Icons.event_outlined,
              label: 'scheduled_for'.tr(),
              value: Formatters.scheduledDelivery(
                order.deliveryDate,
                order.deliveryTime,
              ),
            ),
          if (order.otp != null && order.otp!.isNotEmpty)
            _InfoTile(
              icon: Icons.pin_outlined,
              label: 'otp'.tr(),
              value: order.otp!,
            ),
          _InfoTile(
            icon: Icons.schedule,
            label: 'created_at'.tr(),
            value: Formatters.dateTime(order.createdAt),
          ),
        ],
      ),
    );
  }
}

class OrderNoteCard extends StatelessWidget {
  const OrderNoteCard({super.key, required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.sticky_note_2_outlined, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'note'.tr(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  note,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OrderPriceSummary extends StatelessWidget {
  const OrderPriceSummary({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'price_summary'.tr(),
      child: Column(
        children: [
          if (order.items.isNotEmpty)
            _PriceRow(
              label: 'subtotal'.tr(),
              value: Formatters.currency(order.itemsSubtotal),
            ),
          if (order.deliveryFee != null && order.deliveryFee! > 0)
            _PriceRow(
              label: 'delivery_fee'.tr(),
              value: Formatters.currency(order.deliveryFee),
            ),
          if (order.tax != null && order.tax! > 0)
            _PriceRow(
              label: 'tax'.tr(),
              value: Formatters.currency(order.tax),
            ),
          if (order.serviceFee != null && order.serviceFee! > 0)
            _PriceRow(
              label: 'service_fee'.tr(),
              value: Formatters.currency(order.serviceFee),
            ),
          if (order.couponPrice != null && order.couponPrice! > 0)
            _PriceRow(
              label: 'coupon'.tr(),
              value: '- ${Formatters.currency(order.couponPrice)}',
              valueColor: AppColors.success,
            ),
          if (order.totalDiscount != null && order.totalDiscount! > 0)
            _PriceRow(
              label: 'discount'.tr(),
              value: '- ${Formatters.currency(order.totalDiscount)}',
              valueColor: AppColors.success,
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          _PriceRow(
            label: 'total'.tr(),
            value: Formatters.currency(order.totalPrice),
            bold: true,
            valueColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class OrderStatusActions extends StatelessWidget {
  const OrderStatusActions({
    super.key,
    required this.currentStatus,
    required this.transitions,
    required this.updatingStatus,
    required this.onStatusSelected,
  });

  final String currentStatus;
  final List<String> transitions;
  final String? updatingStatus;
  final ValueChanged<String> onStatusSelected;

  String? get _primaryStatus {
    for (final status in transitions) {
      if (status != 'canceled') return status;
    }
    return null;
  }

  bool get _hasCancel => transitions.contains('canceled');

  static IconData _iconFor(String status) => switch (status) {
        'accepted' => Icons.check_circle_outline,
        'cooking' => Icons.restaurant_outlined,
        'ready' => Icons.shopping_bag_outlined,
        'on_a_way' => Icons.delivery_dining_outlined,
        'delivered' => Icons.done_all,
        _ => Icons.arrow_forward,
      };

  @override
  Widget build(BuildContext context) {
    if (transitions.isEmpty) return const SizedBox.shrink();

    final primary = _primaryStatus;
    final isUpdating = updatingStatus != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'update_status'.tr(),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(width: 8),
                OrderStatusChip(status: currentStatus),
              ],
            ),
            if (primary != null) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: FilledButton.icon(
                        onPressed:
                            isUpdating ? null : () => onStatusSelected(primary),
                        icon: updatingStatus == primary
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(_iconFor(primary), size: 20),
                        label: Text(
                          'update_to_status'.tr(
                            namedArgs: {
                              'status': Formatters.orderStatusLabel(primary),
                            },
                          ),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_hasCancel) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 46,
                      child: TextButton(
                        onPressed: isUpdating
                            ? null
                            : () => onStatusSelected('canceled'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: AppColors.error.withValues(alpha: 0.35),
                            ),
                          ),
                        ),
                        child: updatingStatus == 'canceled'
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                'cancel_order'.tr(),
                                style:
                                    const TextStyle(fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ] else if (_hasCancel)
              SizedBox(
                height: 46,
                child: OutlinedButton.icon(
                  onPressed:
                      isUpdating ? null : () => onStatusSelected('canceled'),
                  icon: updatingStatus == 'canceled'
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cancel_outlined, size: 18),
                  label: Text('cancel_order'.tr()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(
                      color: AppColors.error.withValues(alpha: 0.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
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
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textHint,
                          ),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: bold ? AppColors.textPrimary : AppColors.textSecondary,
                    fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  color: valueColor,
                ),
          ),
        ],
      ),
    );
  }
}
