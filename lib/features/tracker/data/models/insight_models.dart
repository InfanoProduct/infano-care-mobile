class InsightStory {
  final String id;
  final String title;
  final String imageUrl;
  final String content;

  InsightStory({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.content,
  });

  factory InsightStory.fromJson(Map<String, dynamic> json) {
    return InsightStory(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      content: json['content'] as String? ?? '',
    );
  }
}

class DailyInsight {
  final String id;
  final String previewTitle;
  final String previewEmoji;
  final String previewColorHex;
  final List<InsightStory> stories;

  DailyInsight({
    required this.id,
    required this.previewTitle,
    required this.previewEmoji,
    required this.previewColorHex,
    required this.stories,
  });

  factory DailyInsight.fromJson(Map<String, dynamic> json) {
    return DailyInsight(
      id: json['id'] as String? ?? '',
      previewTitle: json['previewTitle'] as String? ?? '',
      previewEmoji: json['previewEmoji'] as String? ?? '✨',
      previewColorHex: json['previewColorHex'] as String? ?? '#A855F7',
      stories: (json['stories'] as List<dynamic>? ?? [])
          .map((s) => InsightStory.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}
