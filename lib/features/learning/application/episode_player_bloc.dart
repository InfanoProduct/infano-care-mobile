import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../models/learning_models.dart';
import '../repositories/learning_repository.dart';

part 'episode_player_bloc.freezed.dart';

@freezed
class EpisodePlayerEvent with _$EpisodePlayerEvent {
  const factory EpisodePlayerEvent.loadEpisode(String episodeId) = _LoadEpisode;
  const factory EpisodePlayerEvent.nextSegment() = _NextSegment;
  const factory EpisodePlayerEvent.previousSegment() = _PreviousSegment;

  /// Navigate only to already-unlocked segments (index <= currentSegmentIndex).
  const factory EpisodePlayerEvent.jumpToSegment(int index) = _JumpToSegment;

  const factory EpisodePlayerEvent.answerQuestion({
    required bool isCorrect,
    required int questionIndex,
    required int answerIndex,
  }) = _AnswerQuestion;
  const factory EpisodePlayerEvent.updateReflection(
      {required String mode, String? content}) = _UpdateReflection;
  const factory EpisodePlayerEvent.completeEpisode(
      {@Default(false) bool isBingeBonus}) = _CompleteEpisode;
  const factory EpisodePlayerEvent.syncHistory(Map<String, dynamic> history) = _SyncHistory;
}

@freezed
class EpisodePlayerState with _$EpisodePlayerState {
  const factory EpisodePlayerState.initial() = _Initial;
  const factory EpisodePlayerState.loading() = _Loading;
  const factory EpisodePlayerState.loaded({
    required Episode episode,
    @Default(0) int currentSegmentIndex,
    @Default(0) int correctAnswers,
    @Default(0) int questionsAnswered,
    @Default('private') String reflectionMode,
    String? reflectionContent,
    @Default(false) bool isCompleting,

    /// Backend-reported completed segment indices (0-4).
    @Default([]) List<int> completedSegmentIndices,
    @Default({}) Map<String, dynamic> history,

    /// Points breakdown from backend episode content, e.g.
    /// {'hook': 0, 'story': 30, 'knowledgeCheck': 20, 'reflection': 10, 'summary': 25}
    @Default({}) Map<String, int> segmentPoints,
  }) = _EpisodePlayerLoaded;
  const factory EpisodePlayerState.completed({
    required int pointsEarned,

    /// Full breakdown map returned by backend (may be empty).
    @Default({}) Map<String, int> pointsBreakdown,
  }) = _Completed;
  const factory EpisodePlayerState.error(String message) = _Error;
}

class EpisodePlayerBloc extends Bloc<EpisodePlayerEvent, EpisodePlayerState> {
  final LearningRepository _repository;

  EpisodePlayerBloc(this._repository) : super(const EpisodePlayerState.initial()) {
    // ── Load ──────────────────────────────────────────────────────────────────
    on<_LoadEpisode>((event, emit) async {
      emit(const EpisodePlayerState.loading());
      try {
        final episode = await _repository.getEpisode(event.episodeId);
        final progressList = await _repository.getMyProgress();

        int resumeIndex = 0;
        List<int> completedIndices = [];

        Map<String, dynamic> history = {};
        int correctAnswers = 0;
        int questionsAnswered = 0;
        String reflectionMode = 'private';
        String? reflectionContent;

        try {
          final progress =
              progressList.firstWhere((p) => p.episodeId == event.episodeId);

          // Backend sends completedItems as a list of segment indices (ints).
          completedIndices = (progress.completedItems as List<dynamic>)
              .map((e) => int.tryParse(e.toString()) ?? -1)
              .where((i) => i >= 0 && i <= 4)
              .toList();

          // Restore History
          if (progress.history != null && progress.history is Map) {
            history = Map<String, dynamic>.from(progress.history);
            
            // Restore Quiz Stats from history
            if (history.containsKey('quiz')) {
              final quizHistory = history['quiz'] as Map<String, dynamic>;
              correctAnswers = quizHistory['correctAnswers'] ?? 0;
              questionsAnswered = quizHistory['questionsAnswered'] ?? 0;
            }

            // Restore Reflection from history
            if (history.containsKey('reflection')) {
              final refHistory = history['reflection'] as Map<String, dynamic>;
              reflectionMode = refHistory['mode'] ?? 'private';
              reflectionContent = refHistory['content'];
            }
          }

          // Enhanced resume logic: Prioritize lastViewedItemId even if completed is true,
          // so users aren't jarringly sent to the start on hot reload.
          if (progress.lastViewedItemId != null && progress.lastViewedItemId!.startsWith('segment_')) {
            final parts = progress.lastViewedItemId!.split('_');
            if (parts.length >= 2) {
              resumeIndex = int.tryParse(parts[1]) ?? 0;
            }
          }
          
          // If no lastViewedItemId but completed, then we can default to 0 for replaying.
          if (resumeIndex == 0 && progress.completed == true) {
             resumeIndex = 0; 
          }
        } catch (_) {
          // No prior progress – start from beginning.
        }

        // Parse per-segment point values from episode.content if available.
        final segmentPoints = _parseSegmentPoints(episode);

        emit(EpisodePlayerState.loaded(
          episode: episode,
          currentSegmentIndex: resumeIndex,
          completedSegmentIndices: completedIndices,
          segmentPoints: segmentPoints,
          history: history,
          correctAnswers: correctAnswers,
          questionsAnswered: questionsAnswered,
          reflectionMode: reflectionMode,
          reflectionContent: reflectionContent,
        ));
      } catch (e) {
        emit(EpisodePlayerState.error(e.toString()));
      }
    });

    // ── Next Segment ──────────────────────────────────────────────────────────
    on<_NextSegment>((event, emit) async {
      final s = state;
      if (s is! _EpisodePlayerLoaded) return;
      if (s.currentSegmentIndex >= 4) return;

      final nextIndex = s.currentSegmentIndex + 1;
      final updatedCompleted = [
        ...s.completedSegmentIndices,
        if (!s.completedSegmentIndices.contains(s.currentSegmentIndex))
          s.currentSegmentIndex,
      ];

      emit(s.copyWith(
        currentSegmentIndex: nextIndex,
        completedSegmentIndices: updatedCompleted,
      ));

      // Sync to backend – include history.
      _repository.updateEpisodeProgress(
        episodeId: s.episode.id,
        completedSegments: updatedCompleted,
        lastViewedItemId: 'segment_$nextIndex',
        history: s.history,
      );
    });

    // ── Previous Segment ──────────────────────────────────────────────────────
    on<_PreviousSegment>((event, emit) {
      final s = state;
      if (s is! _EpisodePlayerLoaded) return;
      if (s.currentSegmentIndex > 0) {
        emit(s.copyWith(currentSegmentIndex: s.currentSegmentIndex - 1));
      }
    });

    // ── Jump To Segment (drawer nav) ──────────────────────────────────────────
    on<_JumpToSegment>((event, emit) {
      final s = state;
      if (s is! _EpisodePlayerLoaded) return;
      
      // A segment is unlocked if it's the first one OR if its predecessor is completed.
      final isUnlocked = event.index == 0 || s.completedSegmentIndices.contains(event.index - 1);
      if (event.index < 0 || !isUnlocked) return;

      emit(s.copyWith(currentSegmentIndex: event.index));
      _repository.updateEpisodeProgress(
        episodeId: s.episode.id,
        completedSegments: s.completedSegmentIndices,
        lastViewedItemId: 'segment_${event.index}',
        history: s.history,
      );
    });

    // ── Answer Question ───────────────────────────────────────────────────────
    on<_AnswerQuestion>((event, emit) {
      final s = state;
      if (s is! _EpisodePlayerLoaded) return;
      
      final correctCount = s.correctAnswers + (event.isCorrect ? 1 : 0);
      final totalCount = s.questionsAnswered + 1;
      
      final updatedHistory = Map<String, dynamic>.from(s.history);
      
      // 1. Update granular answers
      final currentAnswers = Map<String, dynamic>.from(updatedHistory['quiz_answers'] ?? {});
      currentAnswers[event.questionIndex.toString()] = event.answerIndex;
      updatedHistory['quiz_answers'] = currentAnswers;
      
      // 2. Update scoring metadata
      updatedHistory['quiz'] = {
        'correctAnswers': correctCount,
        'questionsAnswered': totalCount,
      };

      emit(s.copyWith(
        correctAnswers: correctCount,
        questionsAnswered: totalCount,
        history: updatedHistory,
      ));
      
      // Update progress immediately so quiz state survives exit
      _repository.updateEpisodeProgress(
        episodeId: s.episode.id,
        completedSegments: s.completedSegmentIndices,
        lastViewedItemId: 'segment_${s.currentSegmentIndex}',
        history: updatedHistory,
      );
    });

    // ── Update Reflection ─────────────────────────────────────────────────────
    on<_UpdateReflection>((event, emit) {
      final s = state;
      if (s is! _EpisodePlayerLoaded) return;
      
      final updatedHistory = Map<String, dynamic>.from(s.history);
      updatedHistory['reflection'] = {
        'mode': event.mode,
        'content': event.content,
      };

      emit(s.copyWith(
        reflectionMode: event.mode,
        reflectionContent: event.content,
        history: updatedHistory,
      ));
      
      _repository.updateEpisodeProgress(
        episodeId: s.episode.id,
        completedSegments: s.completedSegmentIndices,
        lastViewedItemId: 'segment_${s.currentSegmentIndex}',
        history: updatedHistory,
      );
    });

    // ── Complete Episode ──────────────────────────────────────────────────────
    on<_CompleteEpisode>((event, emit) async {
      final s = state;
      if (s is! _EpisodePlayerLoaded) return;

      emit(s.copyWith(isCompleting: true));
      try {
        final result = await _repository.completeEpisode(
          episodeId: s.episode.id,
          knowledgeCheckAccuracy: s.correctAnswers,
          reflectionMode: s.reflectionMode,
          reflectionContent: s.reflectionContent,
          isBingeBonus: event.isBingeBonus,
        );

        // Backend returns pointsEarned (int) and optionally a breakdown map.
        final pointsEarned = result['pointsEarned'] as int? ?? 0;
        final rawBreakdown = result['breakdown'] as Map<String, dynamic>?;
        final breakdown = rawBreakdown != null
            ? rawBreakdown.map((k, v) => MapEntry(k, (v as num).toInt()))
            : <String, int>{};

        emit(EpisodePlayerState.completed(
          pointsEarned: pointsEarned,
          pointsBreakdown: breakdown,
        ));
      } catch (e) {
        emit(EpisodePlayerState.error(e.toString()));
      }
    });
    
    // ── Sync History ─────────────────────────────────────────────────────────
    on<_SyncHistory>((event, emit) {
      final s = state;
      if (s is! _EpisodePlayerLoaded) return;
      
      final updatedHistory = Map<String, dynamic>.from(s.history)..addAll(event.history);
      
      emit(s.copyWith(history: updatedHistory));
      
      _repository.updateEpisodeProgress(
        episodeId: s.episode.id,
        completedSegments: s.completedSegmentIndices,
        lastViewedItemId: 'segment_${s.currentSegmentIndex}',
        history: updatedHistory,
      );
    });
  }

  /// Extracts per-segment XP values from `episode.content['points']` map.
  /// Falls back to sensible defaults if not present.
  Map<String, int> _parseSegmentPoints(Episode episode) {
    try {
      final content = episode.content as Map<String, dynamic>;
      final pts = content['points'] as Map<String, dynamic>?;
      if (pts != null) {
        return pts.map((k, v) => MapEntry(k, (v as num).toInt()));
      }
    } catch (_) {}
    // Defaults (fallback only – authoritative values come from backend on complete).
    return const {
      'story': 30,
      'knowledgeCheck': 20,
      'reflection': 10,
      'summary': 25,
    };
  }
}
