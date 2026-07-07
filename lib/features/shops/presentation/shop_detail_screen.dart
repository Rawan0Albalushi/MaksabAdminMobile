import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/media_url.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../data/shops_repository.dart';
import '../domain/shop_model.dart';
import 'providers/shops_provider.dart';
import 'widgets/shop_status_chip.dart';

class ShopDetailScreen extends ConsumerStatefulWidget {
  const ShopDetailScreen({super.key, required this.shopUuid});

  final String shopUuid;

  @override
  ConsumerState<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends ConsumerState<ShopDetailScreen> {
  bool _updating = false;

  Future<void> _runUpdate(Future<void> Function() action) async {
    setState(() => _updating = true);
    try {
      await action();
      ref.invalidate(shopDetailProvider(widget.shopUuid));
      ref.read(shopsProvider.notifier).load(refresh: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('shop_updated'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _toggleVerify(ShopModel shop) async {
    if (shop.isDeleted) return;
    await _runUpdate(
      () => ref.read(shopsRepositoryProvider).toggleVerify(shop.uuid),
    );
  }

  Future<void> _toggleOpen(ShopModel shop) async {
    if (shop.isDeleted) return;
    await _runUpdate(
      () => ref.read(shopsRepositoryProvider).toggleWorkingStatus(shop.uuid),
    );
  }

  Future<void> _changeStatus(ShopModel shop) async {
    if (shop.isDeleted) return;

    final statuses = ['new', 'approved', 'rejected'];
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'shop_change_status'.tr(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            ...statuses.map(
              (status) => ListTile(
                title: Text(Formatters.shopStatusLabel(status)),
                trailing: shop.status == status
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(context, status),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (selected == null || selected == shop.status) return;

    await _runUpdate(
      () => ref.read(shopsRepositoryProvider).changeStatus(shop.uuid, selected),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shopAsync = ref.watch(shopDetailProvider(widget.shopUuid));
    final padding = Responsive.pagePadding(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('shop_details'.tr()),
        elevation: 0,
      ),
      body: shopAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(shopDetailProvider(widget.shopUuid)),
        ),
        data: (shop) {
          final logoUrl = MediaUrl.resolve(shop.logoImg);
          final bgUrl = MediaUrl.resolve(shop.backgroundImg);

          return Stack(
            children: [
              RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async =>
                    ref.invalidate(shopDetailProvider(widget.shopUuid)),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    if (bgUrl != null)
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 140,
                          width: double.infinity,
                          child: CachedNetworkImage(
                            imageUrl: bgUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.surfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    SliverPadding(
                      padding: padding.copyWith(top: 20, bottom: 32),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: SizedBox(
                                  width: 72,
                                  height: 72,
                                  child: logoUrl != null
                                      ? CachedNetworkImage(
                                          imageUrl: logoUrl,
                                          fit: BoxFit.cover,
                                          errorWidget: (_, __, ___) =>
                                              _logoPlaceholder(),
                                        )
                                      : _logoPlaceholder(),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      shop.name ?? '#${shop.id}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(height: 6),
                                    ShopStatusChip(status: shop.status),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _sectionTitle(context, 'shop_info'.tr()),
                          const SizedBox(height: 10),
                          _infoCard([
                            _infoRow(Icons.tag, '#${shop.id}'),
                            if (shop.phone != null)
                              _infoRow(Icons.phone_outlined, shop.phone!),
                            if (shop.address != null)
                              _infoRow(Icons.place_outlined, shop.address!),
                            if (shop.tax != null)
                              _infoRow(Icons.percent, '${shop.tax}%'),
                            if (shop.minAmount != null)
                              _infoRow(
                                Icons.shopping_bag_outlined,
                                Formatters.currency(shop.minAmount),
                              ),
                            if (shop.createdAt != null)
                              _infoRow(
                                Icons.schedule,
                                Formatters.dateTime(shop.createdAt),
                              ),
                            if (shop.locales.isNotEmpty)
                              _infoRow(
                                Icons.language,
                                shop.locales.join(' • ').toUpperCase(),
                              ),
                          ]),
                          if (shop.sellerName != null) ...[
                            const SizedBox(height: 20),
                            _sectionTitle(context, 'seller'.tr()),
                            const SizedBox(height: 10),
                            _infoCard([
                              _infoRow(Icons.person_outline, shop.sellerName!),
                              if (shop.sellerPhone != null)
                                _infoRow(Icons.phone_outlined, shop.sellerPhone!),
                              if (shop.sellerEmail != null)
                                _infoRow(Icons.email_outlined, shop.sellerEmail!),
                            ]),
                          ],
                          if (shop.description != null &&
                              shop.description!.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _sectionTitle(context, 'description'.tr()),
                            const SizedBox(height: 10),
                            _infoCard([
                              Padding(
                                padding: const EdgeInsets.all(14),
                                child: Text(
                                  shop.description!,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ]),
                          ],
                          if (shop.statusNote != null &&
                              shop.statusNote!.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            _sectionTitle(context, 'shop_status_note'.tr()),
                            const SizedBox(height: 10),
                            _infoCard([
                              Padding(
                                padding: const EdgeInsets.all(14),
                                child: Text(
                                  shop.statusNote!,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ]),
                          ],
                          const SizedBox(height: 20),
                          _sectionTitle(context, 'shop_actions'.tr()),
                          const SizedBox(height: 10),
                          Card(
                            child: Column(
                              children: [
                                SwitchListTile(
                                  title: Text('verified'.tr()),
                                  subtitle: Text('shop_verify_desc'.tr()),
                                  value: shop.verify,
                                  activeThumbColor: AppColors.primary,
                                  onChanged: shop.isDeleted || _updating
                                      ? null
                                      : (_) => _toggleVerify(shop),
                                ),
                                const Divider(height: 1),
                                SwitchListTile(
                                  title: Text('shop_open'.tr()),
                                  subtitle: Text('shop_open_desc'.tr()),
                                  value: shop.open,
                                  activeThumbColor: AppColors.primary,
                                  onChanged: shop.isDeleted || _updating
                                      ? null
                                      : (_) => _toggleOpen(shop),
                                ),
                                const Divider(height: 1),
                                ListTile(
                                  leading: const Icon(Icons.edit_outlined),
                                  title: Text('shop_change_status'.tr()),
                                  subtitle: Text(
                                    Formatters.shopStatusLabel(shop.status),
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  enabled: !shop.isDeleted && !_updating,
                                  onTap: () => _changeStatus(shop),
                                ),
                              ],
                            ),
                          ),
                          if (shop.ratingAvg != null || shop.ordersCount != null)
                            ...[
                              const SizedBox(height: 20),
                              _sectionTitle(context, 'overview'.tr()),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  if (shop.ratingAvg != null)
                                    Expanded(
                                      child: _statCard(
                                        context,
                                        Icons.star_rounded,
                                        shop.ratingAvg!.toStringAsFixed(1),
                                        'rating'.tr(),
                                      ),
                                    ),
                                  if (shop.ratingAvg != null &&
                                      shop.ordersCount != null)
                                    const SizedBox(width: 12),
                                  if (shop.ordersCount != null)
                                    Expanded(
                                      child: _statCard(
                                        context,
                                        Icons.receipt_long_outlined,
                                        shop.ordersCount.toString(),
                                        'orders'.tr(),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
              if (_updating)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x33000000),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _logoPlaceholder() {
    return Container(
      color: AppColors.surfaceVariant,
      child: const Icon(Icons.store_outlined, size: 32, color: AppColors.textHint),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Card(
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            children[i],
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String value) {
    return ListTile(
      leading: Icon(icon, size: 20, color: AppColors.textSecondary),
      title: Text(value),
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _statCard(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
