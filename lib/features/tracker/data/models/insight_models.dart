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
}
