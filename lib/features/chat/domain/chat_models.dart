import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/media_url.dart';

class ChatThread {
  const ChatThread({
    required this.id,
    required this.status,
    this.roleId,
    this.userFirstName,
    this.userLastName,
    this.userImg,
    this.userId,
    this.createdAt,
    this.typing = false,
    this.typingUser,
  });

  final String id;
  final String status;
  final String? roleId;
  final String? userFirstName;
  final String? userLastName;
  final String? userImg;
  final int? userId;
  final DateTime? createdAt;
  final bool typing;
  final String? typingUser;

  String get userName =>
      '${userFirstName ?? ''} ${userLastName ?? ''}'.trim();

  factory ChatThread.fromDoc(String id, Map<String, dynamic> data) {
    final user = data['user'];
    DateTime? created;
    final rawCreated = data['created_at'];
    if (rawCreated is Timestamp) created = rawCreated.toDate();

    return ChatThread(
      id: id,
      status: data['status']?.toString() ?? 'open',
      roleId: data['roleId']?.toString(),
      userFirstName:
          user is Map ? user['firstname']?.toString() : null,
      userLastName: user is Map ? user['lastname']?.toString() : null,
      userImg: user is Map
          ? MediaUrl.resolve(user['img']?.toString())
          : null,
      userId: user is Map ? user['id'] as int? : null,
      createdAt: created,
      typing: data['typing'] == true,
      typingUser: data['typingUser']?.toString(),
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.content,
    required this.isFromCustomer,
    this.imageUrl,
    this.unread = false,
    this.createdAt,
  });

  final String id;
  final String chatId;
  final String content;
  final bool isFromCustomer;
  final String? imageUrl;
  final bool unread;
  final DateTime? createdAt;

  factory ChatMessage.fromDoc(String id, Map<String, dynamic> data) {
    DateTime? created;
    final raw = data['created_at'];
    if (raw is Timestamp) {
      created = raw.toDate();
    } else if (raw is String) {
      created = DateTime.tryParse(raw);
    }

    return ChatMessage(
      id: id,
      chatId: data['chat_id']?.toString() ?? '',
      content: data['chat_content']?.toString() ?? '',
      isFromCustomer: data['sender'] == 1 || data['sender'] == true,
      imageUrl: data['chat_img']?.toString(),
      unread: data['unread'] == true,
      createdAt: created,
    );
  }
}
