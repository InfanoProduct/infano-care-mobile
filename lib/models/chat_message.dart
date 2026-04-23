class ChatMessage {
  final String id;
  final String sessionId;
  final String? senderId;
  final String senderRole; // 'mentee' | 'mentor' | 'system'
  final String content;
  final bool crisisFlag;
  final bool isRead;
  final DateTime sentAt;

  ChatMessage({
    required this.id,
    required this.sessionId,
    this.senderId,
    required this.senderRole,
    required this.content,
    this.crisisFlag = false,
    this.isRead = false,
    required this.sentAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      sessionId: json['sessionId'],
      senderId: json['senderId'],
      senderRole: json['senderRole'],
      content: json['content'],
      crisisFlag: json['crisisFlag'] ?? false,
      isRead: json['isRead'] ?? false,
      sentAt: DateTime.parse(json['sentAt']),
    );
  }

  bool isMe(String currentUserId) {
    return senderId == currentUserId;
  }
  
  bool get isSystem => senderRole == 'system';
}
