class JournalStreak {
  final String id;
  final String userId;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastEntryDate;
  final int totalEntries;
  final List<String> modesUsed;

  const JournalStreak({
    required this.id,
    required this.userId,
    required this.currentStreak,
    required this.longestStreak,
    this.lastEntryDate,
    required this.totalEntries,
    required this.modesUsed,
  });

  factory JournalStreak.fromJson(Map<String, dynamic> json) => JournalStreak(
        id: json['id'] as String,
        userId: json['userId'] as String,
        currentStreak: json['currentStreak'] as int? ?? 0,
        longestStreak: json['longestStreak'] as int? ?? 0,
        lastEntryDate: json['lastEntryDate'] != null
            ? DateTime.parse(json['lastEntryDate'] as String)
            : null,
        totalEntries: json['totalEntries'] as int? ?? 0,
        modesUsed: List<String>.from(json['modesUsed'] as List? ?? []),
      );

  bool get journaledToday {
    if (lastEntryDate == null) return false;
    final now = DateTime.now();
    final last = lastEntryDate!;
    return last.year == now.year && last.month == now.month && last.day == now.day;
  }
}
