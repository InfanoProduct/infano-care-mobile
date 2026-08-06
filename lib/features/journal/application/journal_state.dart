import 'package:equatable/equatable.dart';
import 'package:infano_care_mobile/features/journal/data/models/journal_entry.dart';
import 'package:infano_care_mobile/features/journal/data/models/journal_streak.dart';

// ─── States ───────────────────────────────────────────────────────────────────

abstract class JournalState extends Equatable {
  const JournalState();
  @override
  List<Object?> get props => [];
}

class JournalInitial extends JournalState {}

class JournalLoading extends JournalState {}

class JournalLoaded extends JournalState {
  final List<JournalEntry> entries;
  final JournalStreak? streak;
  final JournalPrompt? dailyPrompt;
  final List<JournalEntry> onThisDay;
  final Map<String, dynamic> moodWeather;
  final int totalPages;
  final int currentPage;

  const JournalLoaded({
    required this.entries,
    this.streak,
    this.dailyPrompt,
    this.onThisDay = const [],
    this.moodWeather = const {},
    this.totalPages = 1,
    this.currentPage = 1,
  });

  JournalLoaded copyWith({
    List<JournalEntry>? entries,
    JournalStreak? streak,
    JournalPrompt? dailyPrompt,
    List<JournalEntry>? onThisDay,
    Map<String, dynamic>? moodWeather,
    int? totalPages,
    int? currentPage,
  }) =>
      JournalLoaded(
        entries: entries ?? this.entries,
        streak: streak ?? this.streak,
        dailyPrompt: dailyPrompt ?? this.dailyPrompt,
        onThisDay: onThisDay ?? this.onThisDay,
        moodWeather: moodWeather ?? this.moodWeather,
        totalPages: totalPages ?? this.totalPages,
        currentPage: currentPage ?? this.currentPage,
      );

  @override
  List<Object?> get props =>
      [entries, streak, dailyPrompt, onThisDay, moodWeather, totalPages, currentPage];
}

class JournalError extends JournalState {
  final String message;
  const JournalError(this.message);
  @override
  List<Object?> get props => [message];
}

class JournalSaving extends JournalState {}

class JournalSaved extends JournalState {
  final JournalEntry entry;
  const JournalSaved(this.entry);
  @override
  List<Object?> get props => [entry];
}
