import 'chat_message.dart';

class PeerLineSession {
  final String id;
  final String status; // 'pending', 'active', 'completed', 'cancelled'
  final DateTime createdAt;
  final String? mentorId;
  final String menteeId;
  final String? mentorName;
  final String? menteeName;
  final String? summary;
  final List<String> topicIds;
  final int? menteeRating;
  final List<ChatMessage> messages;
  final int unreadCount;

  PeerLineSession({
    required this.id,
    required this.status,
    required this.menteeId,
    required this.createdAt,
    this.mentorId,
    this.mentorName,
    this.menteeName,
    this.summary,
    this.topicIds = const [],
    this.menteeRating,
    this.messages = const [],
    this.unreadCount = 0,
  });

  factory PeerLineSession.fromJson(Map<String, dynamic> json) {
    String? mentorName;
    if (json['mentor'] != null && 
        json['mentor']['profile'] != null) {
      mentorName = json['mentor']['profile']['displayName'];
    }

    String? menteeName = json['menteeName'];
    if (menteeName == null && json['mentee'] != null && json['mentee']['profile'] != null) {
      menteeName = json['mentee']['profile']['displayName'];
    }

    List<ChatMessage> parsedMessages = [];
    if (json['messages'] != null) {
      parsedMessages = (json['messages'] as List)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return PeerLineSession(
      id: json['id'],
      status: json['status'],
      menteeId: json['menteeId'],
      createdAt: DateTime.parse(json['createdAt']),
      mentorId: json['mentorId'],
      mentorName: mentorName,
      menteeName: menteeName,
      summary: json['summary'],
      topicIds: json['topicIds'] != null ? List<String>.from(json['topicIds']) : [],
      menteeRating: json['menteeRating'],
      messages: parsedMessages,
      unreadCount: json['unread_count'] ?? json['unreadCount'] ?? 0,
    );
  }
}

class MentorAvailability {
  final bool isAvailable;
  final String? nextAvailableAt;
  final int activeMentorsCount;

  MentorAvailability({
    required this.isAvailable,
    this.nextAvailableAt,
    required this.activeMentorsCount,
  });

  factory MentorAvailability.fromJson(Map<String, dynamic> json) {
    return MentorAvailability(
      isAvailable: json['isAvailable'] ?? json['is_available'] ?? false,
      nextAvailableAt: json['nextAvailableAt'] ?? json['unavailable_until'],
      activeMentorsCount: json['availableMentorsCount'] ?? json['available_mentor_count'] ?? 0,
    );
  }
}
