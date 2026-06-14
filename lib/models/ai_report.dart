class AiReport {
  final double score;
  final List<ReportItem> gaps;
  final List<JargonItem> jargon;
  final List<AnalogyItem> analogies;

  AiReport({
    required this.score,
    required this.gaps,
    required this.jargon,
    required this.analogies,
  });

  factory AiReport.fromJson(Map<String, dynamic> json) {
    return AiReport(
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      gaps: (json['gaps'] as List<dynamic>?)
              ?.map((e) => ReportItem.fromJson(e))
              .toList() ??
          [],
      jargon: (json['jargon'] as List<dynamic>?)
              ?.map((e) => JargonItem.fromJson(e))
              .toList() ??
          [],
      analogies: (json['analogies'] as List<dynamic>?)
              ?.map((e) => AnalogyItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class ReportItem {
  final String title;
  final String detail;

  ReportItem({required this.title, required this.detail});

  factory ReportItem.fromJson(Map<String, dynamic> json) {
    return ReportItem(
      title: json['title'] ?? '',
      detail: json['detail'] ?? '',
    );
  }
}

class JargonItem {
  final String word;
  final String suggestion;

  JargonItem({required this.word, required this.suggestion});

  factory JargonItem.fromJson(Map<String, dynamic> json) {
    return JargonItem(
      word: json['word'] ?? '',
      suggestion: json['suggestion'] ?? '',
    );
  }
}

class AnalogyItem {
  final String topic;
  final String analogy;

  AnalogyItem({required this.topic, required this.analogy});

  factory AnalogyItem.fromJson(Map<String, dynamic> json) {
    return AnalogyItem(
      topic: json['topic'] ?? '',
      analogy: json['analogy'] ?? '',
    );
  }
}
