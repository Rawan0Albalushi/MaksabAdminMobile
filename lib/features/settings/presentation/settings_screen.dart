import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/providers/auth_provider.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/shared_widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final padding = Responsive.pagePadding(context);
    final currentLang = context.locale.languageCode;

    return Scaffold(
      appBar: AppBar(title: Text('settings'.tr())),
      body: ListView(
        padding: padding,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  AppNetworkAvatar(
                    radius: 28,
                    imageUrl: user?.img,
                    fallbackText: user?.fullName.isNotEmpty == true
                        ? user!.fullName
                        : 'A',
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? '',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          user?.email ?? '',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'language'.tr(),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                RadioListTile<String>(
                  title: Text('arabic'.tr()),
                  value: 'ar',
                  groupValue: currentLang,
                  activeColor: AppColors.primary,
                  onChanged: (v) => _switchLanguage(context, ref, v!),
                ),
                const Divider(height: 1),
                RadioListTile<String>(
                  title: Text('english'.tr()),
                  value: 'en',
                  groupValue: currentLang,
                  activeColor: AppColors.primary,
                  onChanged: (v) => _switchLanguage(context, ref, v!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          MaksabButton(
            label: 'logout'.tr(),
            outlined: true,
            icon: Icons.logout,
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _switchLanguage(
    BuildContext context,
    WidgetRef ref,
    String code,
  ) async {
    await context.setLocale(Locale(code));
    await ref.read(localStorageProvider).saveLanguage(code);
  }
}
