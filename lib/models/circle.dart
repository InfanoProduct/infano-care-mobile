class Circle {
  final String id;
  final String slug;
  final String name;
  final String? description;
  final String iconEmoji;
  final String accentColor;
  final bool isAgeSpecific;
  final int? recentPostCount;
  final int? memberCount;
  final int? unreadCount;
  final bool userHasPosted;

  Circle({
    required this.id,
    required this.slug,
    required this.name,
    this.description,
    required this.iconEmoji,
    required this.accentColor,
    required this.isAgeSpecific,
    this.recentPostCount,
    this.memberCount,
    this.unreadCount,
    this.userHasPosted = false,
  });

  factory Circle.fromJson(Map<String, dynamic> json) {
    return Circle(
      id: json['id'],
      slug: json['slug'],
      name: json['name'],
      description: json['description'],
      iconEmoji: json['iconEmoji'] ?? json['icon_emoji'] ?? '🌸',
      accentColor: json['accentColor'] ?? json['accent_color'] ?? '#6D28D9',
      isAgeSpecific: json['isAgeSpecific'] ?? json['is_age_specific'] ?? false,
      recentPostCount: json['recentPostCount'] ?? json['recent_post_count'],
      memberCount: json['memberCount'] ?? json['member_count'],
      unreadCount: json['unreadCount'] ?? json['unread_count'],
      userHasPosted: json['userHasPosted'] ?? json['user_has_posted'] ?? false,
    );
  }
}
