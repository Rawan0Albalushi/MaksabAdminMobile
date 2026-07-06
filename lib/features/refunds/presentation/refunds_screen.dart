import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../domain/refund_model.dart';
import 'providers/refunds_provider.dart';
import 'widgets/refund_status_chip.dart';

class RefundCard extends StatelessWidget {
  const RefundCard({super.key, required this.refund, required this.onTap});

  final RefundModel refund;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.refundPending.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.assignment_return_outlined,
                      size: 20,
                      color: AppColors.refundPending,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${'refund'.tr()} #${refund.id}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  RefundStatusChip(status: refund.status),
                ],
              ),
              const SizedBox(height: 12),
              if (refund.orderId != null)
                _InfoRow(
                  icon: Icons.receipt_outlined,
                  label: '${'order'.tr()} #${Formatters.orderId(refund.orderId)}',
                ),
              if (refund.customerName != null) ...[
                const SizedBox(height: 4),
                _InfoRow(
                  icon: Icons.person_outline,
                  label: refund.customerName!,
                ),
              ],
              if (refund.shopName != null) ...[
                const SizedBox(height: 4),
                _InfoRow(
                  icon: Icons.store_outlined,
                  label: refund.shopName!,
                ),
              ],
              if (refund.cause != null && refund.cause!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  refund.cause!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  if (refund.order?.totalPrice != null)
                    Text(
                      Formatters.currency(refund.order!.totalPrice),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  const Spacer(),
                  Text(
                    Formatters.dateTime(refund.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textHint,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class RefundsScreen extends ConsumerStatefulWidget {
  const RefundsScreen({super.key});

  @override
  ConsumerState<RefundsScreen> createState() => _RefundsScreenState();
}

class _RefundsScreenState extends ConsumerState<RefundsScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  static const _statuses = ['all', 'pending', 'accepted', 'canceled'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(refundsProvider.notifier).load());
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(refundsProvider.notifier).loadMore();
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
    final state = ref.watch(refundsProvider);
    final padding = Responsive.pagePadding(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('refunds'.tr()),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(refundsProvider.notifier).load(refresh: true),
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
                        hintText: 'search_refunds'.tr(),
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  ref
                                      .read(refundsProvider.notifier)
                                      .setSearch('');
                                  setState(() {});
                                },
                              )
                            : null,
                      ),
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (v) =>
                          ref.read(refundsProvider.notifier).setSearch(v),
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
                            label: Text(status == 'all'
                                ? 'all'.tr()
                                : Formatters.refundStatusLabel(status)),
                            selected: selected,
                            onSelected: (_) => ref
                                .read(refundsProvider.notifier)
                                .setStatusFilter(status),
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
            if (state.loading && state.refunds.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.error != null && state.refunds.isEmpty)
              SliverFillRemaining(
                child: ErrorView(
                  message: state.error!,
                  onRetry: () => ref.read(refundsProvider.notifier).load(),
                ),
              )
            else if (state.refunds.isEmpty)
              SliverFillRemaining(
                child: EmptyState(
                  title: 'no_refunds'.tr(),
                  subtitle: 'no_refunds_desc'.tr(),
                  icon: Icons.assignment_return_outlined,
                ),
              )
            else
              SliverPadding(
                padding: padding,
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= state.refunds.length) {
                        return state.loadingMore
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                    child: CircularProgressIndicator()),
                              )
                            : const SizedBox.shrink();
                      }
                      final refund = state.refunds[index];
                      return RefundCard(
                        refund: refund,
                        onTap: () => context.push('/refunds/${refund.id}'),
                      );
                    },
                    childCount:
                        state.refunds.length + (state.loadingMore ? 1 : 0),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
