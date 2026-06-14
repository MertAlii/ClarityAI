import 'package:uuid/uuid.dart';

/// Sohbet mesajı.
///
/// Kullanıcı ve AI arasındaki iletişimi temsil eder.
/// AI yanıtları, ilgili notlara referans verebilir ([noteReferences]).
class ChatMessage {
  ChatMessage({
    String? id,
    required this.content,
    required this.isUser,
    DateTime? timestamp,
    this.noteReferences,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  /// Benzersiz mesaj kimliği (UUID v4).
  final String id;

  /// Mesaj metni.
  final String content;

  /// `true` ise kullanıcı mesajı, `false` ise AI yanıtı.
  final bool isUser;

  /// Mesajın oluşturulma zamanı.
  final DateTime timestamp;

  /// AI yanıtında referans verilen notlar (yalnızca AI mesajları için).
  final List<NoteReference>? noteReferences;

  /// Bu mesaj bir AI yanıtı mı?
  bool get isAi => !isUser;

  /// Mesajda not referansı var mı?
  bool get hasNoteReferences =>
      noteReferences != null && noteReferences!.isNotEmpty;

  // ─── JSON Serialization ─────────────────────────────────────────────

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String?,
      content: json['content'] as String? ?? '',
      isUser: json['isUser'] as bool? ?? true,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
      noteReferences: (json['noteReferences'] as List<dynamic>?)
          ?.map((e) => NoteReference.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      if (noteReferences != null)
        'noteReferences': noteReferences!.map((e) => e.toJson()).toList(),
    };
  }

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

  // ─── Factory Constructors ───────────────────────────────────────────

  /// Kullanıcı mesajı oluşturur.
  factory ChatMessage.user(String content) {
    return ChatMessage(
      content: content,
      isUser: true,
    );
  }

  /// AI yanıtı oluşturur, isteğe bağlı not referanslarıyla.
  factory ChatMessage.ai(
    String content, {
    List<NoteReference>? noteReferences,
  }) {
    return ChatMessage(
      content: content,
      isUser: false,
      noteReferences: noteReferences,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ChatMessage && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ChatMessage(id: ${id.substring(0, 8)}…, isUser: $isUser, length: ${content.length})';
}

/// AI yanıtında referans verilen bir not.
class NoteReference {
  const NoteReference({
    required this.noteId,
    required this.noteTitle,
  });

  /// Referans verilen notun birincil anahtarı.
  final int noteId;

  /// Notun başlığı — UI'da göstermek için.
  final String noteTitle;

  factory NoteReference.fromJson(Map<String, dynamic> json) {
    return NoteReference(
      noteId: json['noteId'] as int,
      noteTitle: json['noteTitle'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'noteId': noteId,
        'noteTitle': noteTitle,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteReference &&
          other.noteId == noteId &&
          other.noteTitle == noteTitle;

  @override
  int get hashCode => Object.hash(noteId, noteTitle);

  @override
  String toString() => 'NoteReference(id: $noteId, "$noteTitle")';
}
