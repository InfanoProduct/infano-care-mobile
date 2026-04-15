import 'package:infano_care_mobile/models/post.dart';

class CommunityEvent {
  final String id;
  final String title;
  final String description;
  final String type; // 'live', 'recorded', 'challenge'
  final String? imageUrl;
  final DateTime startTime;
  final DateTime? endTime;
  final String status; // 'upcoming', 'live', 'past'
  final int participantsCount;
  final String? expertName;
  final String? expertCredentials;
  final String? expertPhotoUrl;
  final int questionCount;
  final int viewCount;

  CommunityEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.imageUrl,
    required this.startTime,
    this.endTime,
    required this.status,
    required this.participantsCount,
    this.expertName,
    this.expertCredentials,
    this.expertPhotoUrl,
    this.questionCount = 0,
    this.viewCount = 0,
  });

  factory CommunityEvent.fromJson(Map<String, dynamic> json) {
    return CommunityEvent(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Untitled Event',
      description: json['description'] ?? '',
      type: json['type'] ?? 'workshop',
      imageUrl: json['imageUrl'],
      startTime: json['startDate'] != null 
          ? DateTime.parse(json['startDate']) 
          : (json['starts_at'] != null ? DateTime.parse(json['starts_at']) : DateTime.now()),
      endTime: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      status: json['status'] ?? 'upcoming',
      participantsCount: json['attendeeCount'] ?? (json['question_count'] ?? 0),
      expertName: json['expert_name'] ?? 'Dr. Expert',
      expertCredentials: json['expert_credentials'] ?? 'Specialist',
      expertPhotoUrl: json['expert_photo_url'],
      questionCount: json['question_count'] ?? 0,
      viewCount: json['view_count'] ?? 0,
    );
  }
}

class EventQuestion {
  final String id;
  final String content;
  final String authorName;
  final String? answer;
  final String? expertName;
  final DateTime? answeredAt;
  final bool isAnonymous;

  EventQuestion({
    required this.id,
    required this.content,
    required this.authorName,
    this.answer,
    this.expertName,
    this.answeredAt,
    this.isAnonymous = false,
  });

  factory EventQuestion.fromJson(Map<String, dynamic> json) {
    return EventQuestion(
      id: json['id']?.toString() ?? '',
      content: json['content'] ?? '',
      authorName: json['authorName'] ?? (json['isAnonymous'] == true ? 'Anonymous' : 'Community Member'),
      answer: json['answer'],
      expertName: json['expertName'],
      answeredAt: json['answeredAt'] != null ? DateTime.parse(json['answeredAt']) : null,
      isAnonymous: json['isAnonymous'] ?? false,
    );
  }
}

class WeeklyChallenge {
  final String id;
  final String theme;
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, String> promptsByCircle;
  final int participatingCount;
  final bool userHasResponded;
  final List<CommunityPost> featuredResponses;

  // UI-facing getters to satisfy ChallengeBanner
  String get title => theme;
  String get description => "Join our community theme: $theme";
  double get completionProgress => userHasResponded ? 1.0 : 0.0;

  WeeklyChallenge({
    required this.id,
    required this.theme,
    required this.startDate,
    required this.endDate,
    required this.promptsByCircle,
    this.participatingCount = 0,
    this.userHasResponded = false,
    this.featuredResponses = const [],
  });

  factory WeeklyChallenge.fromJson(Map<String, dynamic> json) {
    // promptsByCircle is Json/Map
    final prompts = <String, String>{};
    if (json['promptsByCircle'] != null) {
      (json['promptsByCircle'] as Map).forEach((key, value) {
        prompts[key.toString()] = value.toString();
      });
    }

    return WeeklyChallenge(
      id: json['id']?.toString() ?? '',
      theme: json['theme']?.toString() ?? 'Weekly Challenge',
      startDate: DateTime.tryParse(json['startDate']?.toString() ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['endDate']?.toString() ?? '') ?? DateTime.now(),
      promptsByCircle: prompts,
      participatingCount: json['participatingCount'] ?? 0,
      userHasResponded: json['userHasResponded'] ?? false,
      featuredResponses: (json['featuredResponses'] as List?)
          ?.map((e) => CommunityPost.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}
