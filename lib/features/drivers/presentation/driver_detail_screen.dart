import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/media_url.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../dashboard/data/zones_repository.dart';
import '../../dashboard/domain/zone_model.dart';
import '../data/drivers_repository.dart';
import '../domain/driver_model.dart';
import 'providers/drivers_provider.dart';
import 'widgets/driver_status_chip.dart';

class DriverDetailScreen extends ConsumerStatefulWidget {
  const DriverDetailScreen({super.key, required this.driverUuid});

  final String driverUuid;

  @override
  ConsumerState<DriverDetailScreen> createState() => _DriverDetailScreenState();
}

class _DriverDetailScreenState extends ConsumerState<DriverDetailScreen> {
  bool _updating = false;
  bool _savingZones = false;
  Set<int>? _selectedZoneIds;
  bool _zonesDirty = false;

  Future<void> _runUpdate(Future<void> Function() action) async {
    setState(() => _updating = true);
    try {
      await action();
      ref.invalidate(driverDetailProvider(widget.driverUuid));
      ref.read(driversProvider.notifier).load(refresh: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('driver_updated'.tr())),
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

  Future<void> _toggleActive(DriverModel driver) async {
    final approve = !driver.active;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          approve
              ? 'driver_approve_confirm'.tr()
              : 'driver_deactivate_confirm'.tr(),
        ),
        content: Text(
          approve
              ? 'driver_approve_confirm_desc'.tr()
              : 'driver_deactivate_confirm_desc'.tr(),
        ),
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
    if (confirmed != true) return;

    await _runUpdate(
      () => ref.read(driversRepositoryProvider).toggleActive(driver.uuid),
    );
  }

  Future<void> _saveZones(DriverModel driver) async {
    final selected = _selectedZoneIds;
    if (selected == null || selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('driver_select_zones_required'.tr())),
      );
      return;
    }

    setState(() => _savingZones = true);
    try {
      await ref.read(driversRepositoryProvider).assignZones(
            driverId: driver.id,
            zoneIds: selected.toList(),
          );
      ref.invalidate(driverAssignedZonesProvider(widget.driverUuid));
      setState(() => _zonesDirty = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('driver_zones_assigned'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _savingZones = false);
    }
  }

  void _syncSelectedZones(List<ZoneModel> assigned) {
    if (_zonesDirty || _selectedZoneIds != null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _zonesDirty || _selectedZoneIds != null) return;
      setState(() {
        _selectedZoneIds = assigned.map((z) => z.id).toSet();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final driverAsync = ref.watch(driverDetailProvider(widget.driverUuid));
    final assignedZonesAsync =
        ref.watch(driverAssignedZonesProvider(widget.driverUuid));
    final allZonesAsync = ref.watch(zonesListProvider);
    final padding = Responsive.pagePadding(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('driver_details'.tr()),
        elevation: 0,
      ),
      body: driverAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () =>
              ref.invalidate(driverDetailProvider(widget.driverUuid)),
        ),
        data: (driver) {
          final imgUrl = MediaUrl.resolve(driver.img);
          final setting = driver.setting;

          assignedZonesAsync.whenData(_syncSelectedZones);

          return Stack(
            children: [
              RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  setState(() {
                    _selectedZoneIds = null;
                    _zonesDirty = false;
                  });
                  ref.invalidate(driverDetailProvider(widget.driverUuid));
                  ref.invalidate(
                      driverAssignedZonesProvider(widget.driverUuid));
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: padding.copyWith(top: 20, bottom: 32),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppNetworkAvatar(
                                radius: 36,
                                imageUrl: imgUrl,
                                fallbackText: driver.fullName,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      driver.fullName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    DriverStatusChip(active: driver.active),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _sectionTitle(context, 'driver_info'.tr()),
                          const SizedBox(height: 10),
                          _infoCard([
                            _infoRow(Icons.tag, '#${driver.id}'),
                            if (driver.phone != null)
                              _infoRow(Icons.phone_outlined, driver.phone!),
                            if (driver.email != null)
                              _infoRow(Icons.email_outlined, driver.email!),
                            if (driver.createdAt != null)
                              _infoRow(
                                Icons.schedule,
                                Formatters.dateTime(driver.createdAt),
                              ),
                          ]),
                          if (setting != null) ...[
                            const SizedBox(height: 20),
                            _sectionTitle(context, 'driver_vehicle'.tr()),
                            const SizedBox(height: 10),
                            _infoCard([
                              if (setting.typeOfTechnique != null)
                                _infoRow(
                                  Icons.two_wheeler_outlined,
                                  'driver_vehicle_${setting.typeOfTechnique}'
                                      .tr(),
                                ),
                              if (setting.brand != null)
                                _infoRow(
                                  Icons.branding_watermark_outlined,
                                  setting.brand!,
                                ),
                              if (setting.model != null)
                                _infoRow(Icons.directions_car_outlined,
                                    setting.model!),
                              if (setting.number != null)
                                _infoRow(
                                    Icons.pin_outlined, setting.number!),
                              if (setting.color != null)
                                _infoRow(
                                    Icons.palette_outlined, setting.color!),
                              _infoRow(
                                Icons.wifi_tethering,
                                setting.online
                                    ? 'driver_online'.tr()
                                    : 'driver_offline'.tr(),
                              ),
                            ]),
                          ],
                          const SizedBox(height: 20),
                          _sectionTitle(context, 'driver_actions'.tr()),
                          const SizedBox(height: 10),
                          Card(
                            child: SwitchListTile(
                              title: Text(
                                driver.active
                                    ? 'driver_approved'.tr()
                                    : 'driver_approve'.tr(),
                              ),
                              subtitle: Text(
                                driver.active
                                    ? 'driver_active_desc'.tr()
                                    : 'driver_approve_desc'.tr(),
                              ),
                              value: driver.active,
                              activeThumbColor: AppColors.primary,
                              onChanged: _updating
                                  ? null
                                  : (_) => _toggleActive(driver),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _sectionTitle(context, 'driver_zones'.tr()),
                          const SizedBox(height: 10),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'driver_zones_hint'.tr(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                  const SizedBox(height: 12),
                                  allZonesAsync.when(
                                    loading: () => const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                    error: (e, _) => ErrorView(
                                      message: e.toString(),
                                      onRetry: () =>
                                          ref.invalidate(zonesListProvider),
                                    ),
                                    data: (zones) {
                                      if (zones.isEmpty) {
                                        return Text(
                                          'no_zones'.tr(),
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                          ),
                                        );
                                      }

                                      final selected =
                                          _selectedZoneIds ?? <int>{};

                                      return Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: zones.map((zone) {
                                          final isSelected =
                                              selected.contains(zone.id);
                                          return FilterChip(
                                            label: Text(zone.name),
                                            selected: isSelected,
                                            onSelected: _savingZones
                                                ? null
                                                : (value) {
                                                    setState(() {
                                                      final next =
                                                          Set<int>.from(
                                                              selected);
                                                      if (value) {
                                                        next.add(zone.id);
                                                      } else {
                                                        next.remove(zone.id);
                                                      }
                                                      _selectedZoneIds = next;
                                                      _zonesDirty = true;
                                                    });
                                                  },
                                            selectedColor: AppColors.primary
                                                .withValues(alpha: 0.15),
                                            checkmarkColor: AppColors.primary,
                                          );
                                        }).toList(),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  MaksabButton(
                                    label: 'driver_assign_zones'.tr(),
                                    icon: Icons.map_outlined,
                                    loading: _savingZones,
                                    onPressed: _savingZones ||
                                            _updating ||
                                            !_zonesDirty
                                        ? null
                                        : () => _saveZones(driver),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (driver.ratingAvg != null ||
                              driver.ordersCount != null) ...[
                            const SizedBox(height: 20),
                            _sectionTitle(context, 'overview'.tr()),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                if (driver.ratingAvg != null)
                                  Expanded(
                                    child: StatCard(
                                      label: 'rating'.tr(),
                                      value:
                                          driver.ratingAvg!.toStringAsFixed(1),
                                      color: AppColors.warning,
                                      icon: Icons.star_rounded,
                                    ),
                                  ),
                                if (driver.ratingAvg != null &&
                                    driver.ordersCount != null)
                                  const SizedBox(width: 12),
                                if (driver.ordersCount != null)
                                  Expanded(
                                    child: StatCard(
                                      label: 'orders'.tr(),
                                      value: driver.ordersCount.toString(),
                                      color: AppColors.primary,
                                      icon: Icons.receipt_long_outlined,
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
}
