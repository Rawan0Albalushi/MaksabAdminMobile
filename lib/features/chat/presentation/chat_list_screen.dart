import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/utils/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../data/chat_repository.dart';
import '../domain/chat_models.dart';

final chatStatusFilterProvider = StateProvider<String>((ref) => 'all');

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(chatStatusFilterProvider);
    final chatsStream = ref.watch(chatRepositoryProvider).watchAdminChats(
          statusFilter: filter,
        );
    final padding = Responsive.pagePadding(context);

    return Scaffold(
      appBar: AppBar(title: Text('conversations'.tr())),
      body: Column(
        children: [
          Padding(
            padding: padding.copyWith(top: 8, bottom: 0),
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'all', label: Text('all'.tr())),
                ButtonSegment(value: 'open', label: Text('open'.tr())),
                ButtonSegment(value: 'closed', label: Text('closed'.tr())),
              ],
              selected: {filter},
              onSelectionChanged: (s) =>
                  ref.read(chatStatusFilterProvider.notifier).state = s.first,
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ChatThread>>(
              stream: chatsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return ErrorView(message: snapshot.error.toString());
                }
                final chats = snapshot.data ?? [];
                if (chats.isEmpty) {
                  return EmptyState(
                    title: 'no_chats'.tr(),
                    subtitle: 'no_chats_desc'.tr(),
                    icon: Icons.chat_bubble_outline,
                  );
                }
                return ListView.separated(
                  padding: padding,
                  itemCount: chats.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    return _ChatListTile(
                      chat: chat,
                      onTap: () => context.push('/chat/${chat.id}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatListTile extends StatelessWidget {
  const _ChatListTile({required this.chat, required this.onTap});

  final ChatThread chat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final displayName =
        chat.userName.isNotEmpty ? chat.userName : 'customer'.tr();
    final timeLabel = chat.createdAt != null
        ? timeago.format(chat.createdAt!, locale: Formatters.displayLocale)
        : '';

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: AppNetworkAvatar(
          imageUrl: chat.userImg,
          fallbackText: displayName,
        ),
        title: Text(
          displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: chat.typing
            ? Text('typing'.tr(), style: TextStyle(color: AppColors.primary))
            : Text(
                chat.status == 'closed' ? 'closed'.tr() : 'open'.tr(),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (timeLabel.isNotEmpty)
              Text(
                timeLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textHint,
                    ),
              ),
            if (chat.status == 'open')
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
