class ChatMessage {
  final String id;
  final String sessionId;
  final String? senderId;
  final String senderRole; // 'mentee' | 'mentor' | 'system'
  final String? content;
  final String? mediaUrl;
  final String messageType; // 'TEXT' | 'VOICE' | 'IMAGE'
  final bool crisisFlag;
  final bool isRead;
  final DateTime sentAt;

  ChatMessage({
    required this.id,
    required this.sessionId,
    this.senderId,
    required this.senderRole,
    this.content,
    this.mediaUrl,
    this.messageType = 'TEXT',
    this.crisisFlag = false,
    this.isRead = false,
    required this.sentAt,
  });

  ChatMessage copyWith({
    String? id,
    String? sessionId,
    String? senderId,
    String? senderRole,
    String? content,
    String? mediaUrl,
    String? messageType,
    bool? crisisFlag,
    bool? isRead,
    DateTime? sentAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      senderId: senderId ?? this.senderId,
      senderRole: senderRole ?? this.senderRole,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      messageType: messageType ?? this.messageType,
      crisisFlag: crisisFlag ?? this.crisisFlag,
      isRead: isRead ?? this.isRead,
      sentAt: sentAt ?? this.sentAt,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      sessionId: json['sessionId'],
      senderId: json['senderId'],
      senderRole: json['senderRole'],
      content: json['content'],
      mediaUrl: json['mediaUrl'],
      messageType: json['messageType'] ?? 'TEXT',
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
