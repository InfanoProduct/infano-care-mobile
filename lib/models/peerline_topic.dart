class PeerLineTopic {
  final String id;
  final String name;
  final String emoji;
  final String accentColor;
  final bool isActive;
  final int sortOrder;

  PeerLineTopic({
    required this.id,
    required this.name,
    required this.emoji,
    required this.accentColor,
    required this.isActive,
    required this.sortOrder,
  });

  factory PeerLineTopic.fromJson(Map<String, dynamic> json) {
    return PeerLineTopic(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      accentColor: json['accentColor'] as String? ?? '#6D28D9',
      isActive: json['isActive'] as bool? ?? true,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'accentColor': accentColor,
      'isActive': isActive,
      'sortOrder': sortOrder,
    };
  }
}
