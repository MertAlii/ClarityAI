/// Note model representing a Feynman Technique study note.
///
/// Each note stores the original reference text, the student's spoken
/// explanation (transcript), the AI evaluation score, and the target
/// audience used during the explanation.
class Note {
  final int? id;
  final String title;
  final String referenceText;
  final String transcript;
  final double score;
  final String targetAudience;
  final DateTime createdAt;

  Note({
    this.id,
    required this.title,
    required this.referenceText,
    required this.transcript,
    this.score = 0.0,
    this.targetAudience = 'university',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Creates a [Note] from a SQLite row map.
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      referenceText: map['reference_text'] as String? ?? '',
      transcript: map['transcript'] as String? ?? '',
      score: (map['score'] as num?)?.toDouble() ?? 0.0,
      targetAudience: map['target_audience'] as String? ?? 'university',
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  /// Converts this note to a SQLite-compatible map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'reference_text': referenceText,
      'transcript': transcript,
      'score': score,
      'target_audience': targetAudience,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Returns a copy of this note with the given fields replaced.
  Note copyWith({
    int? id,
    String? title,
    String? referenceText,
    String? transcript,
    double? score,
    String? targetAudience,
    DateTime? createdAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      referenceText: referenceText ?? this.referenceText,
      transcript: transcript ?? this.transcript,
      score: score ?? this.score,
      targetAudience: targetAudience ?? this.targetAudience,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'Note(id: $id, title: $title, score: $score)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Note && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
