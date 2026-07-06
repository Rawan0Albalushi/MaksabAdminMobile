import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../data/chat_repository.dart';
import '../domain/chat_models.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  const ChatDetailScreen({super.key, required this.chatId});

  final String chatId;

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _typingTimer;
  bool _isTyping = false;
  bool _nearBottom = true;
  bool _sending = false;
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    _nearBottom = position.maxScrollExtent - position.pixels < 96;
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    if (_isTyping) {
      ref.read(chatRepositoryProvider).setTyping(widget.chatId, false);
    }
    _scrollController.removeListener(_onScroll);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    final repo = ref.read(chatRepositoryProvider);
    if (value.trim().isNotEmpty && !_isTyping) {
      _isTyping = true;
      repo.setTyping(widget.chatId, true);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _isTyping = false;
      repo.setTyping(widget.chatId, false);
    });
  }

  Future<void> _send({required String chatStatus}) async {
    final text = _controller.text;
    if (text.trim().isEmpty || _sending) return;

    _controller.clear();
    _isTyping = false;
    ref.read(chatRepositoryProvider).setTyping(widget.chatId, false);

    setState(() => _sending = true);
    try {
      await ref.read(chatRepositoryProvider).sendText(
            chatId: widget.chatId,
            text: text,
            reopenIfClosed: chatStatus == 'closed',
          );
      _scrollToBottom(force: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickImage() async {
    if (_sending) return;

    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );
    if (file == null) return;

    setState(() => _sending = true);
    try {
      await ref.read(chatRepositoryProvider).sendImage(
            chatId: widget.chatId,
            file: File(file.path),
          );
      _scrollToBottom(force: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom({bool force = false}) {
    if (!force && !_nearBottom) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _showImageViewer(String url) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4,
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (_, __, ___) => const Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 48,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: IconButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(chatRepositoryProvider);
    final padding = Responsive.pagePadding(context);

    return StreamBuilder<ChatThread?>(
      stream: repo.watchChat(widget.chatId),
      builder: (context, chatSnapshot) {
        final chat = chatSnapshot.data;
        final chatStatus = chat?.status ?? 'open';
        final customerTyping =
            chat?.typing == true && chat?.typingUser != 'Admin';

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _ChatAppBar(
            chat: chat,
            chatStatus: chatStatus,
            onClose: () => repo.closeChat(widget.chatId),
            onReopen: () => repo.reopenChat(widget.chatId),
          ),
          body: Column(
            children: [
              if (chatStatus == 'closed')
                _ClosedChatBanner(onReopen: () => repo.reopenChat(widget.chatId)),
              Expanded(
                child: StreamBuilder<List<ChatMessage>>(
                  stream: repo.watchMessages(widget.chatId),
                  builder: (context, snapshot) {
                    final messages = snapshot.data ?? [];
                    if (messages.isNotEmpty) {
                      repo.markMessagesRead(messages);
                    }

                    if (messages.length != _lastMessageCount) {
                      _lastMessageCount = messages.length;
                      _scrollToBottom();
                    }

                    if (snapshot.connectionState == ConnectionState.waiting &&
                        messages.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (messages.isEmpty) {
                      return EmptyState(
                        title: 'no_messages'.tr(),
                        subtitle: 'no_messages_desc'.tr(),
                        icon: Icons.forum_outlined,
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      padding: padding.copyWith(top: 8, bottom: 8),
                      itemCount: messages.length + (customerTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (customerTyping && index == messages.length) {
                          return const _TypingBubble();
                        }

                        final msg = messages[index];
                        final prev = index > 0 ? messages[index - 1] : null;
                        final next = index < messages.length - 1
                            ? messages[index + 1]
                            : null;

                        final showDate = index == 0 ||
                            !_sameDay(prev!.createdAt, msg.createdAt);
                        final isFirstInGroup =
                            prev == null || !_sameGroup(prev, msg);
                        final isLastInGroup =
                            next == null || !_sameGroup(msg, next);

                        return Column(
                          children: [
                            if (showDate && msg.createdAt != null)
                              _DateSeparator(date: msg.createdAt!),
                            _MessageBubble(
                              message: msg,
                              showSender: isFirstInGroup,
                              showTime: isLastInGroup,
                              isGrouped: !isFirstInGroup,
                              onImageTap: _showImageViewer,
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              _ChatInputBar(
                controller: _controller,
                sending: _sending,
                chatClosed: chatStatus == 'closed',
                onChanged: _onTextChanged,
                onSend: () => _send(chatStatus: chatStatus),
                onPickImage: _pickImage,
              ),
            ],
          ),
        );
      },
    );
  }

  bool _sameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _sameGroup(ChatMessage a, ChatMessage b) {
    if (a.isFromCustomer != b.isFromCustomer) return false;
    if (a.createdAt == null || b.createdAt == null) return false;
    return b.createdAt!.difference(a.createdAt!).inMinutes < 5;
  }
}

class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ChatAppBar({
    required this.chat,
    required this.chatStatus,
    required this.onClose,
    required this.onReopen,
  });

  final ChatThread? chat;
  final String chatStatus;
  final VoidCallback onClose;
  final VoidCallback onReopen;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final name = (chat?.userName.isNotEmpty == true)
        ? chat!.userName
        : 'customer'.tr();
    final isOpen = chatStatus == 'open';

    return AppBar(
      titleSpacing: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            backgroundImage:
                chat?.userImg != null ? NetworkImage(chat!.userImg!) : null,
            child: chat?.userImg == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isOpen ? AppColors.success : AppColors.textHint,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOpen ? 'open'.tr() : 'closed'.tr(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'close') onClose();
            if (value == 'reopen') onReopen();
          },
          itemBuilder: (context) => [
            if (isOpen)
              PopupMenuItem(value: 'close', child: Text('close_chat'.tr())),
            if (!isOpen)
              PopupMenuItem(value: 'reopen', child: Text('reopen_chat'.tr())),
          ],
        ),
      ],
    );
  }
}

class _ClosedChatBanner extends StatelessWidget {
  const _ClosedChatBanner({required this.onReopen});

  final VoidCallback onReopen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.warning.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 18, color: AppColors.warning),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'chat_closed_hint'.tr(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                    ),
              ),
            ),
            TextButton(
              onPressed: onReopen,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text('reopen_chat'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.date});

  final DateTime date;

  String _label(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(date.year, date.month, date.day);

    if (messageDay == today) return 'today'.tr();
    if (messageDay == today.subtract(const Duration(days: 1))) {
      return 'yesterday'.tr();
    }

    return Formatters.date(date, pattern: 'd MMM yyyy');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            _label(context),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadiusDirectional.only(
            topStart: Radius.circular(16),
            topEnd: Radius.circular(16),
            bottomEnd: Radius.circular(16),
            bottomStart: Radius.circular(4),
          ),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'typing'.tr(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(width: 8),
            const _TypingDots(),
          ],
        ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 10,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (index) {
              final delay = index * 0.2;
              final value = (_controller.value + delay) % 1.0;
              final opacity = value < 0.5 ? 0.35 + (value * 1.3) : 1.1 - value;

              return Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: opacity.clamp(0.3, 1.0)),
                  shape: BoxShape.circle,
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.showSender,
    required this.showTime,
    required this.isGrouped,
    required this.onImageTap,
  });

  final ChatMessage message;
  final bool showSender;
  final bool showTime;
  final bool isGrouped;
  final void Function(String url) onImageTap;

  @override
  Widget build(BuildContext context) {
    final isCustomer = message.isFromCustomer;
    final alignment = isCustomer
        ? AlignmentDirectional.centerStart
        : AlignmentDirectional.centerEnd;

    final bubbleColor = isCustomer
        ? AppColors.surface
        : AppColors.primary.withValues(alpha: 0.14);

    final borderRadius = BorderRadiusDirectional.only(
      topStart: const Radius.circular(16),
      topEnd: const Radius.circular(16),
      bottomStart: Radius.circular(isCustomer ? 4 : 16),
      bottomEnd: Radius.circular(isCustomer ? 16 : 4),
    );

    return Align(
      alignment: alignment,
      child: Container(
        margin: EdgeInsets.only(
          bottom: isGrouped ? 3 : 10,
          top: showSender ? 2 : 0,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Column(
          crossAxisAlignment: isCustomer
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
          children: [
            if (showSender)
              Padding(
                padding: const EdgeInsetsDirectional.only(bottom: 4, start: 4, end: 4),
                child: Text(
                  isCustomer ? 'customer'.tr() : 'admin_support'.tr(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textHint,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: borderRadius,
                border: isCustomer
                    ? Border.all(color: AppColors.border)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.imageUrl != null &&
                        message.imageUrl!.isNotEmpty)
                      GestureDetector(
                        onTap: () => onImageTap(message.imageUrl!),
                        child: Semantics(
                          label: 'view_image'.tr(),
                          button: true,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              children: [
                                CachedNetworkImage(
                                  imageUrl: message.imageUrl!,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(
                                    height: 200,
                                    color: AppColors.surfaceVariant,
                                    child: const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                  errorWidget: (_, __, ___) => Container(
                                    height: 120,
                                    color: AppColors.surfaceVariant,
                                    child: const Center(
                                      child: Icon(Icons.broken_image_outlined),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 8,
                                  bottom: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.zoom_in,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (message.content.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(
                          top: message.imageUrl != null &&
                                  message.imageUrl!.isNotEmpty
                              ? 8
                              : 0,
                        ),
                        child: SelectableText(
                          message.content,
                          style: TextStyle(
                            height: 1.4,
                            color: isCustomer
                                ? AppColors.textPrimary
                                : AppColors.primaryDark,
                          ),
                        ),
                      ),
                    if (showTime && message.createdAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: Text(
                            Formatters.time(message.createdAt!),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.textHint,
                                      fontSize: 10,
                                    ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  const _ChatInputBar({
    required this.controller,
    required this.sending,
    required this.chatClosed,
    required this.onChanged,
    required this.onSend,
    required this.onPickImage,
  });

  final TextEditingController controller;
  final bool sending;
  final bool chatClosed;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;
  final VoidCallback onPickImage;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              onPressed: sending ? null : onPickImage,
              icon: const Icon(Icons.image_outlined),
              tooltip: 'attach_image'.tr(),
              color: AppColors.primary,
            ),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: chatClosed
                      ? 'chat_closed_hint'.tr()
                      : 'type_message'.tr(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                final canSend = value.text.trim().isNotEmpty && !sending;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    gradient: canSend ? AppColors.brandGradient : null,
                    color: canSend ? null : AppColors.border,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: canSend ? onSend : null,
                      borderRadius: BorderRadius.circular(14),
                      child: Tooltip(
                        message: 'send'.tr(),
                        child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: sending
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                Icons.send_rounded,
                                color: canSend
                                    ? Colors.white
                                    : AppColors.textHint,
                              ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
