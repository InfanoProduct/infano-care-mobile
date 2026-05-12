class MindfulActivity {
  final String id;
  final String title;
  final String? description;
  final String videoUrl;
  final String? thumbnailUrl;
  final String? expertName;
  final int duration;
  final String category;
  final int points;

  MindfulActivity({
    required this.id,
    required this.title,
    this.description,
    required this.videoUrl,
    this.thumbnailUrl,
    this.expertName,
    required this.duration,
    required this.category,
    required this.points,
  });

  factory MindfulActivity.fromJson(Map<String, dynamic> json) {
    return MindfulActivity(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      videoUrl: json['videoUrl'],
      thumbnailUrl: json['thumbnailUrl'],
      expertName: json['expertName'],
      duration: json['duration'] ?? 5,
      category: json['category'] ?? 'Meditation',
      points: json['points'] ?? 30,
    );
  }
}
