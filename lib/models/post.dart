class CommunityPost {
  final String id;
  final String circleId;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime createdAt;
  final int reactionHeart;
  final int reactionHug;
  final int reactionBulb;
  final int reactionFist;
  final int replyCount;
  final bool isPinned;
  final bool isFeatured;
  final bool isBookmarked;
  final bool isChallengeResponse;
  final String? challengeTheme;
  final String authorRole;
  final String status;

  CommunityPost({
    required this.id,
    required this.circleId,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.createdAt,
    this.reactionHeart = 0,
    this.reactionHug = 0,
    this.reactionBulb = 0,
    this.reactionFist = 0,
    this.replyCount = 0,
    this.isPinned = false,
    this.isFeatured = false,
    this.isBookmarked = false,
    this.isChallengeResponse = false,
    this.challengeTheme,
    this.authorRole = 'TEEN',
    this.status = 'APPROVED',
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id']?.toString() ?? '',
      circleId: json['circleId']?.toString() ?? '',
      authorId: json['authorId']?.toString() ?? '',
      authorName: json['author']?['profile']?['displayName']?.toString() ?? 'Anonymous',
      authorRole: json['author']?['role']?.toString() ?? 'TEEN',
      status: json['status']?.toString() ?? 'APPROVED',
      content: json['content']?.toString() ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      reactionHeart: json['reactionHeart'] ?? 0,
      reactionHug: json['reactionHug'] ?? 0,
      reactionBulb: json['reactionBulb'] ?? 0,
      reactionFist: json['reactionFist'] ?? 0,
      replyCount: json['replyCount'] ?? 0,
      isPinned: json['isPinned'] ?? false,
      isFeatured: json['isFeatured'] ?? false,
      isBookmarked: json['isBookmarked'] ?? false,
      isChallengeResponse: json['isChallengeResponse'] ?? false,
      challengeTheme: json['challenge']?['theme']?.toString(),
    );
  }

  CommunityPost copyWith({
    String? id,
    String? circleId,
    String? authorId,
    String? authorName,
    String? content,
    DateTime? createdAt,
    int? reactionHeart,
    int? reactionHug,
    int? reactionBulb,
    int? reactionFist,
    int? replyCount,
    bool? isPinned,
    bool? isFeatured,
    bool? isBookmarked,
    bool? isChallengeResponse,
    String? challengeTheme,
    String? authorRole,
    String? status,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      circleId: circleId ?? this.circleId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      reactionHeart: reactionHeart ?? this.reactionHeart,
      reactionHug: reactionHug ?? this.reactionHug,
      reactionBulb: reactionBulb ?? this.reactionBulb,
      reactionFist: reactionFist ?? this.reactionFist,
      replyCount: replyCount ?? this.replyCount,
      isPinned: isPinned ?? this.isPinned,
      isFeatured: isFeatured ?? this.isFeatured,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isChallengeResponse: isChallengeResponse ?? this.isChallengeResponse,
      challengeTheme: challengeTheme ?? this.challengeTheme,
      authorRole: authorRole ?? this.authorRole,
      status: status ?? this.status,
    );
  }
}

class CommunityReply {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime createdAt;
  final int depth;
  final int reactionHeart;
  final int reactionHug;
  final int reactionBulb;
  final int reactionFist;
  final bool isBookmarked;
  final List<CommunityReply> childReplies;

  CommunityReply({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.createdAt,
    required this.depth,
    this.reactionHeart = 0,
    this.reactionHug = 0,
    this.reactionBulb = 0,
    this.reactionFist = 0,
    this.isBookmarked = false,
    this.childReplies = const [],
  });

  factory CommunityReply.fromJson(Map<String, dynamic> json) {
    return CommunityReply(
      id: json['id']?.toString() ?? '',
      postId: json['postId']?.toString() ?? '',
      authorId: json['authorId']?.toString() ?? '',
      authorName: json['author']?['profile']?['displayName']?.toString() ?? 'Anonymous',
      content: json['content']?.toString() ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      depth: json['depth'] ?? 1,
      reactionHeart: json['reactionHeart'] ?? 0,
      reactionHug: json['reactionHug'] ?? 0,
      reactionBulb: json['reactionBulb'] ?? 0,
      reactionFist: json['reactionFist'] ?? 0,
      isBookmarked: json['isBookmarked'] ?? false,
      childReplies: (json['childReplies'] as List?)
          ?.map((e) => CommunityReply.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  CommunityReply copyWith({
    String? id,
    String? postId,
    String? authorId,
    String? authorName,
    String? content,
    DateTime? createdAt,
    int? depth,
    int? reactionHeart,
    int? reactionHug,
    int? reactionBulb,
    int? reactionFist,
    bool? isBookmarked,
    List<CommunityReply>? childReplies,
  }) {
    return CommunityReply(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      depth: depth ?? this.depth,
      reactionHeart: reactionHeart ?? this.reactionHeart,
      reactionHug: reactionHug ?? this.reactionHug,
      reactionBulb: reactionBulb ?? this.reactionBulb,
      reactionFist: reactionFist ?? this.reactionFist,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      childReplies: childReplies ?? this.childReplies,
    );
  }
}
