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
import '../domain/shop_model.dart';
import 'providers/shops_provider.dart';
import 'widgets/shop_status_chip.dart';
import 'widgets/shops_zone_filter.dart';

class ShopCard extends StatelessWidget {
  const ShopCard({super.key, required this.shop, required this.onTap});

  final ShopModel shop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final logoUrl = MediaUrl.resolve(shop.logoImg);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: logoUrl != null
                      ? CachedNetworkImage(
                          imageUrl: logoUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _logoPlaceholder(),
                        )
                      : _logoPlaceholder(),
                ),
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
                            shop.name ?? '#${shop.id}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ShopStatusChip(status: shop.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (shop.sellerName != null)
                      Row(
                        children: [
                          const Icon(Icons.person_outline,
                              size: 15, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              shop.sellerName!,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _badge(
                          shop.open ? 'shop_open'.tr() : 'shop_closed'.tr(),
                          shop.open ? AppColors.success : AppColors.error,
                        ),
                        const SizedBox(width: 8),
                        if (shop.verify)
                          _badge('verified'.tr(), AppColors.primary),
                        const Spacer(),
                        if (shop.tax != null)
                          Text(
                            '${shop.tax}%',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textHint,
                                ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _logoPlaceholder() {
    return Container(
      color: AppColors.surfaceVariant,
      child: const Icon(Icons.store_outlined, color: AppColors.textHint),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class ShopsScreen extends ConsumerStatefulWidget {
  const ShopsScreen({super.key});

  @override
  ConsumerState<ShopsScreen> createState() => _ShopsScreenState();
}

class _ShopsScreenState extends ConsumerState<ShopsScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  static const _statuses = ['all', 'new', 'approved', 'rejected', 'deleted'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(shopsProvider.notifier).load());
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(shopsProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shopsProvider);
    final padding = Responsive.pagePadding(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('shops'.tr()),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(shopsProvider.notifier).load(refresh: true),
        color: AppColors.primary,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: padding.copyWith(bottom: 8),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'search_shops'.tr(),
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  ref.read(shopsProvider.notifier).setSearch('');
                                },
                              )
                            : null,
                      ),
                      onSubmitted: (v) =>
                          ref.read(shopsProvider.notifier).setSearch(v),
                    ),
                    const SizedBox(height: 12),
                    ShopsZoneFilter(
                      selectedZoneId: state.zoneId,
                      onZoneChanged: (zoneId) {
                        if (_scrollController.hasClients) {
                          _scrollController.animateTo(
                            0,
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          );
                        }
                        ref.read(shopsProvider.notifier).setZoneFilter(zoneId);
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _statuses.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final status = _statuses[index];
                          final selected = state.statusFilter == status;
                          return FilterChip(
                            label: Text(Formatters.shopFilterLabel(status)),
                            selected: selected,
                            onSelected: (_) {
                              if (_scrollController.hasClients) {
                                _scrollController.animateTo(
                                  0,
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOut,
                                );
                              }
                              ref
                                  .read(shopsProvider.notifier)
                                  .setStatusFilter(status);
                            },
                            selectedColor:
                                AppColors.primary.withValues(alpha: 0.15),
                            checkmarkColor: AppColors.primary,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (state.loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.error != null && state.shops.isEmpty)
              SliverFillRemaining(
                child: ErrorView(
                  message: state.error!,
                  onRetry: () => ref.read(shopsProvider.notifier).load(),
                ),
              )
            else if (state.shops.isEmpty)
              SliverFillRemaining(
                child: EmptyState(
                  title: 'no_shops'.tr(),
                  subtitle: 'no_shops_desc'.tr(),
                  icon: Icons.store_outlined,
                ),
              )
            else
              SliverPadding(
                padding: padding,
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= state.shops.length) {
                        return state.loadingMore
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                    child: CircularProgressIndicator()),
                              )
                            : const SizedBox.shrink();
                      }
                      final shop = state.shops[index];
                      return ShopCard(
                        shop: shop,
                        onTap: () {
                          final target = shop.uuid.trim();
                          if (target.isEmpty) return;
                          context.push('/shops/$target');
                        },
                      );
                    },
                    childCount:
                        state.shops.length + (state.loadingMore ? 1 : 0),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
