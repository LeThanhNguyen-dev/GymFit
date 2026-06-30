import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' show Database, openDatabase, getDatabasesPath, ConflictAlgorithm, databaseFactory;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' show sqfliteFfiInit, databaseFactoryFfi;

import '../models/chat_message_model.dart';

class ChatLocalDatabase {
  static Database? _instance;
  static bool _factoryInitAttempted = false;

  static Future<Database> get instance async {
    if (_instance != null) return _instance!;
    if (kIsWeb) {
      throw UnsupportedError('sqflite not available on web');
    }
    _initFactoryOnce();
    final dbPath = await getDatabasesPath();
    _instance = await openDatabase(
      p.join(dbPath, 'chat_cache.db'),
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _instance!;
  }

  static void _initFactoryOnce() {
    if (_factoryInitAttempted) return;
    _factoryInitAttempted = true;
    try {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    } catch (_) {
      // On mobile, sqflite native factory is already set — ignore FFI failure
    }
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS messages (
        local_id TEXT NOT NULL,
        conversation_id TEXT NOT NULL,
        remote_id TEXT,
        sender_id TEXT NOT NULL,
        content TEXT NOT NULL DEFAULT '',
        message_type TEXT NOT NULL DEFAULT 'text',
        media_url TEXT,
        media_path TEXT,
        media_thumb TEXT,
        media_width INTEGER,
        media_height INTEGER,
        file_name TEXT,
        file_size INTEGER,
        reactions TEXT DEFAULT '{}',
        reply_to_id TEXT,
        status TEXT NOT NULL DEFAULT 'sending',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        PRIMARY KEY (local_id, conversation_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS conversations (
        conversation_id TEXT PRIMARY KEY,
        peer_user_id TEXT NOT NULL,
        peer_name TEXT NOT NULL DEFAULT '',
        peer_email TEXT NOT NULL DEFAULT '',
        peer_avatar_url TEXT,
        peer_role TEXT NOT NULL DEFAULT 'customer',
        last_message_preview TEXT,
        last_message_at TEXT,
        unread_count INTEGER NOT NULL DEFAULT 0,
        is_pinned INTEGER NOT NULL DEFAULT 0,
        is_archived INTEGER NOT NULL DEFAULT 0,
        is_muted INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_messages_conversation
      ON messages(conversation_id, created_at ASC)
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_messages_status
      ON messages(status)
    ''');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {}

  /* ─── Web fallback via shared_preferences ─── */

  static Future<void> _saveToPrefs(String key, List<ChatMessageModel> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(messages.map((m) => m.toJson()).toList());
    await prefs.setString(key, json);
  }

  static Future<List<ChatMessageModel>> _loadFromPrefs(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(key);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list.map((e) => ChatMessageModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  /* ─── Public API ─── */

  static Future<void> insertMessage(ChatMessageModel message) async {
    if (kIsWeb) {
      final msgs = await _loadFromPrefs('chat_msgs_${message.conversationId}');
      msgs.insert(0, message);
      await _saveToPrefs('chat_msgs_${message.conversationId}', msgs);
      return;
    }
    final db = await instance;
    await db.insert('messages', _messageToRow(message), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> updateMessageStatus(String localId, String conversationId, String status, {String? remoteId}) async {
    if (kIsWeb) {
      final msgs = await _loadFromPrefs('chat_msgs_$conversationId');
      final idx = msgs.indexWhere((m) => m.localId == localId);
      if (idx < 0) return;
      var updated = msgs[idx].copyWith(status: status, id: remoteId ?? msgs[idx].id);
      msgs[idx] = updated;
      await _saveToPrefs('chat_msgs_$conversationId', msgs);
      return;
    }
    final db = await instance;
    final values = <String, dynamic>{'status': status, 'updated_at': DateTime.now().toIso8601String()};
    if (remoteId != null) values['remote_id'] = remoteId;
    await db.update('messages', values, where: 'local_id = ? AND conversation_id = ?', whereArgs: [localId, conversationId]);
  }

  static Future<void> insertMessages(List<ChatMessageModel> messages) async {
    for (final m in messages) {
      await insertMessage(m);
    }
  }

  static Future<List<ChatMessageModel>> getMessages(
    String conversationId, {
    int limit = 50,
    String? beforeId,
    DateTime? beforeCreatedAt,
  }) async {
    if (kIsWeb) {
      final msgs = await _loadFromPrefs('chat_msgs_$conversationId');
      if (beforeCreatedAt != null) {
        return msgs.where((m) => m.createdAt.isBefore(beforeCreatedAt)).take(limit).toList();
      }
      return msgs.take(limit).toList();
    }
    final db = await instance;
    final where = beforeCreatedAt != null
        ? 'conversation_id = ? AND created_at < ?'
        : 'conversation_id = ?';
    final whereArgs = beforeCreatedAt != null
        ? [conversationId, beforeCreatedAt.toIso8601String()]
        : [conversationId];
    final rows = await db.query('messages', where: where, whereArgs: whereArgs, orderBy: 'created_at DESC', limit: limit);
    return rows.reversed.map(_rowToMessage).toList();
  }

  static Future<List<ChatMessageModel>> getPendingMessages() async {
    if (kIsWeb) return [];
    final db = await instance;
    final rows = await db.query('messages', where: 'status IN (?, ?)', whereArgs: ['pending', 'sending'], orderBy: 'created_at ASC');
    return rows.map(_rowToMessage).toList();
  }

  static Future<void> deleteConversationMessages(String conversationId) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('chat_msgs_$conversationId');
      return;
    }
    final db = await instance;
    await db.delete('messages', where: 'conversation_id = ?', whereArgs: [conversationId]);
    await db.delete('conversations', where: 'conversation_id = ?', whereArgs: [conversationId]);
  }

  static Future<List<ChatMessageModel>> searchMessages(String conversationId, String query) async {
    if (kIsWeb) {
      final msgs = await _loadFromPrefs('chat_msgs_$conversationId');
      final q = query.toLowerCase();
      return msgs.where((m) => m.content.toLowerCase().contains(q)).toList();
    }
    final db = await instance;
    final rows = await db.query('messages', where: 'conversation_id = ? AND content LIKE ?', whereArgs: [conversationId, '%$query%'], orderBy: 'created_at ASC');
    return rows.map(_rowToMessage).toList();
  }

  static Future<ChatMessageModel?> getMessageByRemoteId(String remoteId) async {
    if (kIsWeb) return null;
    final db = await instance;
    final rows = await db.query('messages', where: 'remote_id = ?', whereArgs: [remoteId]);
    if (rows.isEmpty) return null;
    return _rowToMessage(rows.first);
  }

  static Future<ChatMessageModel?> getMessageByLocalId(String localId) async {
    if (kIsWeb) return null;
    final db = await instance;
    final rows = await db.query('messages', where: 'local_id = ?', whereArgs: [localId]);
    if (rows.isEmpty) return null;
    return _rowToMessage(rows.first);
  }

  static Future<List<Map<String, dynamic>>> getConversationList() async {
    if (kIsWeb) return [];
    final db = await instance;
    return await db.query('conversations', orderBy: 'updated_at DESC');
  }

  static Future<void> upsertConversation(Map<String, dynamic> data) async {
    if (kIsWeb) return;
    final db = await instance;
    await db.insert('conversations', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> updateConversationUnread(String conversationId, int count) async {
    if (kIsWeb) return;
    final db = await instance;
    await db.update('conversations', {'unread_count': count, 'updated_at': DateTime.now().toIso8601String()},
        where: 'conversation_id = ?', whereArgs: [conversationId]);
  }

  static Future<void> deleteDatabase() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('chat_msgs_'));
      for (final k in keys) { await prefs.remove(k); }
      return;
    }
    if (_instance != null) {
      await _instance!.close();
      _instance = null;
    }
    final dbPath = await getDatabasesPath();
    await databaseFactory.deleteDatabase(p.join(dbPath, 'chat_cache.db'));
  }

  /* ─── Helpers ─── */

  static Map<String, dynamic> _messageToRow(ChatMessageModel msg) {
    return {
      'local_id': msg.localId,
      'conversation_id': msg.conversationId,
      'remote_id': msg.id,
      'sender_id': msg.senderId,
      'content': msg.content,
      'message_type': msg.messageType,
      'media_url': msg.mediaUrl,
      'media_path': msg.mediaPath,
      'media_thumb': msg.mediaThumb,
      'media_width': msg.mediaWidth,
      'media_height': msg.mediaHeight,
      'file_name': msg.fileName,
      'file_size': msg.fileSize,
      'reactions': jsonEncode(msg.reactions),
      'reply_to_id': msg.replyToId,
      'status': msg.status,
      'created_at': msg.createdAt.toIso8601String(),
      'updated_at': msg.updatedAt.toIso8601String(),
    };
  }

  static ChatMessageModel _rowToMessage(Map<String, dynamic> row) {
    return ChatMessageModel(
      id: row['remote_id'] as String?,
      localId: row['local_id'] as String,
      conversationId: row['conversation_id'] as String,
      senderId: row['sender_id'] as String,
      content: row['content'] as String? ?? '',
      messageType: row['message_type'] as String? ?? 'text',
      mediaUrl: row['media_url'] as String?,
      mediaPath: row['media_path'] as String?,
      mediaThumb: row['media_thumb'] as String?,
      mediaWidth: row['media_width'] as int?,
      mediaHeight: row['media_height'] as int?,
      fileName: row['file_name'] as String?,
      fileSize: row['file_size'] as int?,
      reactions: row['reactions'] != null
          ? Map<String, int>.from(jsonDecode(row['reactions'] as String))
          : const {},
      replyToId: row['reply_to_id'] as String?,
      status: row['status'] as String? ?? 'sent',
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(row['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
