import 'dart:convert';

import 'package:uuid/uuid.dart';

/// Chat message model used in the AI learning assistant conversation.
///
/// Supports JSON-serialized note references so the chat can link back
/// to the user's Feynman notes contextually.
class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final List<NoteReference> noteReferences;

  ChatMessage({
    String? id,
    required this.content,
    required this.isUser,
    DateTime? timestamp,
    this.noteReferences = const [],
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  /// Creates a [ChatMessage] from a SQLite row map.
  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    List<NoteReference> refs = [];
    final refsJson = map['note_references'] as String?;
    if (refsJson != null && refsJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(refsJson) as List<dynamic>;
        refs = decoded
            .map((e) => NoteReference.fromMap(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        // Silently ignore malformed JSON — treat as no references.
      }
    }

    return ChatMessage(
      id: map['id'] as String?,
      content: map['content'] as String? ?? '',
      isUser: (map['is_user'] as int?) == 1,
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ??
          DateTime.now(),
      noteReferences: refs,
    );
  }

  /// Converts this message to a SQLite-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'is_user': isUser ? 1 : 0,
      'timestamp': timestamp.toIso8601String(),
      'note_references': noteReferences.isNotEmpty
          ? jsonEncode(noteReferences.map((r) => r.toMap()).toList())
          : null,
    };
  }

  /// Returns a copy of this message with the given fields replaced.
  ChatMessage copyWith({
    String? id,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    List<NoteReference>? noteReferences,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      noteReferences: noteReferences ?? this.noteReferences,
    );
  }

  @override
  String toString() =>
      'ChatMessage(id: $id, isUser: $isUser, content: ${content.length > 40 ? '${content.substring(0, 40)}…' : content})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// A reference to a specific [Note] embedded within a chat response.
class NoteReference {
  final int noteId;
  final String noteTitle;

  const NoteReference({
    required this.noteId,
    required this.noteTitle,
  });

  factory NoteReference.fromMap(Map<String, dynamic> map) {
    return NoteReference(
      noteId: map['noteId'] as int? ?? 0,
      noteTitle: map['noteTitle'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'noteId': noteId,
      'noteTitle': noteTitle,
    };
  }

  @override
  String toString() => 'NoteReference(noteId: $noteId, title: $noteTitle)';
}
