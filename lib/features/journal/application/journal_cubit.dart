import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infano_care_mobile/features/journal/application/journal_state.dart';
import 'package:infano_care_mobile/features/journal/data/models/journal_entry.dart';
import 'package:infano_care_mobile/features/journal/data/models/journal_streak.dart';
import 'package:infano_care_mobile/features/journal/data/repositories/journal_repository.dart';

class JournalCubit extends Cubit<JournalState> {
  final JournalRepository _repo;
  JournalRepository get repo => _repo;

  static JournalLoaded? _cachedState;

  static void clearCache() {
    _cachedState = null;
  }

  JournalCubit(this._repo) : super(_cachedState ?? JournalInitial());

  Future<void> loadFeed({bool forceRefresh = false}) async {
    if (state is JournalInitial && !forceRefresh) {
      emit(JournalLoading());
    }
    try {
      final results = await Future.wait([
        _repo.listEntries().catchError((e, s) {
          // print("[JOURNAL_ERROR] listEntries failed: $e\n$s");
          return {'entries': <JournalEntry>[], 'total': 0, 'page': 1, 'pages': 1};
        }),
        _repo.getStreak().catchError((e, s) {
          // print("[JOURNAL_ERROR] getStreak failed: $e\n$s");
          return null;
        }),
        _repo.getDailyPrompt().catchError((e, s) {
          // print("[JOURNAL_ERROR] getDailyPrompt failed: $e\n$s");
          return null;
        }),
        _repo.getOnThisDay().catchError((e, s) {
          // print("[JOURNAL_ERROR] getOnThisDay failed: $e\n$s");
          return <JournalEntry>[];
        }),
        _repo.getMoodWeather().catchError((e, s) {
          // print("[JOURNAL_ERROR] getMoodWeather failed: $e\n$s");
          return <String, dynamic>{};
        }),
      ]);

      final listResult = (results[0] as Map<String, dynamic>?) ?? {};
      final entriesList = (listResult['entries'] as List? ?? []).cast<JournalEntry>();
      final onThisDayList = (results[3] as List? ?? []).cast<JournalEntry>();

      final loadedState = JournalLoaded(
        entries: entriesList,
        streak: results[1] as JournalStreak?,
        dailyPrompt: results[2] as JournalPrompt?,
        onThisDay: onThisDayList,
        moodWeather: (results[4] as Map<String, dynamic>?) ?? {},
        totalPages: listResult['pages'] as int? ?? 1,
        currentPage: 1,
      );

      _cachedState = loadedState;
      emit(loadedState);
    } catch (e) {
      // print("[JOURNAL_CUBIT_FATAL] $e\n$s");
      if (state is! JournalLoaded) {
        emit(JournalError(e.toString()));
      }
    }
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! JournalLoaded) return;
    if (current.currentPage >= current.totalPages) return;

    try {
      final result = await _repo.listEntries(page: current.currentPage + 1);
      final newEntries = result['entries'] as List<JournalEntry>;
      emit(current.copyWith(
        entries: [...current.entries, ...newEntries],
        currentPage: current.currentPage + 1,
        totalPages: result['pages'] as int,
      ));
    } catch (e) {
      // Silently fail on pagination errors
    }
  }

  Future<JournalEntry?> saveEntry({
    String? id,
    required String mode,
    required Map<String, dynamic> content,
    String? promptId,
    String? moodTag,
    String? moodColor,
    String? title,
    bool isSealedTimeCapsule = false,
    String? capsuleRevealDate,
  }) async {
    emit(JournalSaving());
    try {
      final dto = {
        'mode': mode,
        'content': content,
        if (promptId != null) 'promptId': promptId,
        if (moodTag != null) 'moodTag': moodTag,
        if (moodColor != null) 'moodColor': moodColor,
        if (title != null) 'title': title,
        'isSealedTimeCapsule': isSealedTimeCapsule,
        if (capsuleRevealDate != null) 'capsuleRevealDate': capsuleRevealDate,
      };

      final JournalEntry entry;
      if (id != null && id.isNotEmpty) {
        entry = await _repo.updateEntry(id, dto);
      } else {
        entry = await _repo.createEntry(
          mode: mode,
          content: content,
          promptId: promptId,
          moodTag: moodTag,
          moodColor: moodColor,
          title: title,
          isSealedTimeCapsule: isSealedTimeCapsule,
          capsuleRevealDate: capsuleRevealDate,
        );
      }
      emit(JournalSaved(entry));
      // Reload feed to reflect entry updates
      await loadFeed(forceRefresh: true);
      return entry;
    } catch (e) {
      emit(JournalError(e.toString()));
      return null;
    }
  }

  Future<void> deleteEntry(String id) async {
    try {
      await _repo.deleteEntry(id);
      await loadFeed(forceRefresh: true);
    } catch (e) {
      emit(JournalError(e.toString()));
    }
  }

  Future<JournalPrompt?> shakePromptJar({String? category}) async {
    return _repo.getRandomPrompt(category: category);
  }
}
