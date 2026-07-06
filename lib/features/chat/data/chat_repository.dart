import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../domain/chat_models.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

class ChatRepository {
  ChatRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  Stream<List<ChatThread>> watchAdminChats({String statusFilter = 'all'}) {
    return _db
        .collection('chats')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs
          .map((d) => ChatThread.fromDoc(d.id, d.data()))
          .where((c) => c.roleId == AppConfig.adminChatRoleId)
          .where((c) =>
              statusFilter == 'all' || (c.status) == statusFilter)
          .toList();
    });
  }

  Stream<ChatThread?> watchChat(String chatId) {
    return _db.collection('chats').doc(chatId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ChatThread.fromDoc(doc.id, doc.data()!);
    });
  }

  Stream<List<ChatMessage>> watchMessages(String chatId) {
    return _db.collection('messages').snapshots().map((snap) {
      final list = snap.docs
          .where((d) => d.data()['chat_id']?.toString() == chatId)
          .map((d) => ChatMessage.fromDoc(d.id, d.data()))
          .toList();
      list.sort((a, b) {
        final ta = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tb = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return ta.compareTo(tb);
      });
      return list;
    });
  }

  Future<void> sendText({
    required String chatId,
    required String text,
    required bool reopenIfClosed,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    if (reopenIfClosed) {
      await _db.collection('chats').doc(chatId).set(
        {'status': 'open', 'updated_at': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    }

    await _db.collection('messages').add({
      'chat_content': trimmed,
      'chat_id': chatId,
      'sender': 0,
      'unread': true,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendImage({
    required String chatId,
    required File file,
  }) async {
    final ref = _storage.ref(
      'chat/$chatId/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await ref.putFile(file);
    final url = await ref.getDownloadURL();

    await _db.collection('messages').add({
      'chat_content': '',
      'chat_id': chatId,
      'chat_img': url,
      'sender': 0,
      'unread': true,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markMessagesRead(List<ChatMessage> messages) async {
    final batch = _db.batch();
    for (final msg in messages) {
      if (msg.isFromCustomer && msg.unread) {
        batch.update(_db.collection('messages').doc(msg.id), {'unread': false});
      }
    }
    await batch.commit();
  }

  Future<void> setTyping(String chatId, bool typing) async {
    await _db.collection('chats').doc(chatId).set(
      {
        'typing': typing,
        'typingUser': typing ? 'Admin' : null,
        'typingTimestamp': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> closeChat(String chatId) async {
    await _db.collection('chats').doc(chatId).update({
      'status': 'closed',
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> reopenChat(String chatId) async {
    await _db.collection('chats').doc(chatId).update({
      'status': 'open',
      'updated_at': FieldValue.serverTimestamp(),
    });
  }
}
