import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../data/models/quest_models.dart';
import '../data/repositories/quest_repository.dart';

part 'quest_bloc.freezed.dart';

@freezed
class QuestEvent with _$QuestEvent {
  const factory QuestEvent.load() = _Load;
  const factory QuestEvent.acceptQuest(String id) = _AcceptQuest;
  const factory QuestEvent.refresh() = _Refresh;
  const factory QuestEvent.clearCompletedQuest() = _ClearCompletedQuest;
}

@freezed
class QuestState with _$QuestState {
  const factory QuestState.initial() = _Initial;
  const factory QuestState.loading() = _Loading;
  const factory QuestState.loaded({
    required List<UserQuest> dailyQuests,
    required List<WeeklyChallenge> weeklyChallenges,
    required UserQuestProgress progress,
    required List<Badge> badges,
    @Default(false) bool isRefreshing,
    UserQuest? lastCompletedQuest,
    int? lastLevel,
  }) = _Loaded;
  const factory QuestState.error(String message) = _Error;
}

class QuestBloc extends Bloc<QuestEvent, QuestState> {
  final QuestRepository _repository;

  QuestBloc(this._repository) : super(const QuestState.initial()) {
    on<_Load>((event, emit) async {
      emit(const QuestState.loading());
      await _loadAll(emit);
    });

    on<_Refresh>((event, emit) async {
      final currentState = state;
      if (currentState is _Loaded) {
        emit(currentState.copyWith(isRefreshing: true));
        await _loadAll(emit, previousState: currentState);
      } else {
        emit(const QuestState.loading());
        await _loadAll(emit);
      }
    });

    on<_ClearCompletedQuest>((event, emit) {
      final currentState = state;
      if (currentState is _Loaded) {
        emit(currentState.copyWith(
          lastCompletedQuest: null,
          lastLevel: null,
        ));
      }
    });

    on<_AcceptQuest>((event, emit) async {
      final currentState = state;
      if (currentState is! _Loaded) return;

      try {
        await _repository.acceptQuest(event.id);
        // Refresh to get updated quest statuses
        await _loadAll(emit, previousState: currentState);
      } catch (e) {
        debugPrint('[QUEST_BLOC] Error accepting quest: $e');
        // Don't emit error — keep showing the current quests
        // The user can try tapping Start again
      }
    });
  }

  Future<void> _loadAll(Emitter<QuestState> emit, {_Loaded? previousState}) async {
    try {
      debugPrint('[QUEST_BLOC] Starting _loadAll data fetch...');
      final results = await Future.wait([
        _repository.getDailyQuests().catchError((e) {
          debugPrint('[QUEST_BLOC] Daily Quests error: $e');
          throw Exception('Daily Quests: $e');
        }),
        _repository.getProgress().catchError((e) {
          debugPrint('[QUEST_BLOC] Progress error: $e');
          throw Exception('Progress: $e');
        }),
        _repository.getBadges().catchError((e) {
          debugPrint('[QUEST_BLOC] Badges error: $e');
          throw Exception('Badges: $e');
        }),
        _repository.getWeeklyChallenges().catchError((e) {
          debugPrint('[QUEST_BLOC] Weekly Challenges error: $e');
          return <WeeklyChallenge>[];
        }),
      ]);

      final dailyQuests = results[0] as List<UserQuest>;
      final progress = results[1] as UserQuestProgress;
      final badges = results[2] as List<Badge>;
      final weeklyChallenges = results[3] as List<WeeklyChallenge>;

      debugPrint('[QUEST_BLOC] Loaded ${dailyQuests.length} quests, ${weeklyChallenges.length} weekly challenges, ${badges.length} badges');

      final currentState = state;
      UserQuest? completedQuest;
      int? prevLevel;

      // Compare against previous state (passed in or from current state)
      final baseState = previousState ?? (currentState is _Loaded ? currentState : null);

      if (baseState != null) {
        prevLevel = baseState.progress.currentLevel;
        for (var q in dailyQuests) {
          final oldQ = baseState.dailyQuests.firstWhere(
            (oq) => oq.id == q.id,
            orElse: () => q,
          );
          if (q.status == 'completed' && oldQ.status != 'completed') {
            completedQuest = q;
            break;
          }
        }
      }

      emit(QuestState.loaded(
        dailyQuests: dailyQuests,
        weeklyChallenges: weeklyChallenges,
        progress: progress,
        badges: badges,
        // Only set lastCompletedQuest if this is a new completion
        lastCompletedQuest: completedQuest,
        lastLevel: prevLevel,
      ));
    } catch (e) {
      debugPrint('[QUEST_BLOC] Error in _loadAll: $e');
      // On error: if we have a previous loaded state, keep it visible
      // instead of showing a blank error screen
      if (previousState != null) {
        emit(previousState.copyWith(isRefreshing: false));
      } else if (state is _Loaded) {
        emit((state as _Loaded).copyWith(isRefreshing: false));
      } else {
        emit(QuestState.error(e.toString()));
      }
    }
  }
}
