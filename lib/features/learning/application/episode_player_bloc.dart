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

  const factory EpisodePlayerEvent.answerQuestion({required bool isCorrect}) =
      _AnswerQuestion;
  const factory EpisodePlayerEvent.updateReflection(
      {required String mode, String? content}) = _UpdateReflection;
  const factory EpisodePlayerEvent.completeEpisode(
      {@Default(false) bool isBingeBonus}) = _CompleteEpisode;
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

    /// Points breakdown from backend episode content, e.g.
    /// {'hook': 0, 'story': 30, 'knowledgeCheck': 20, 'reflection': 10, 'quest': 15}
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

        try {
          final progress =
              progressList.firstWhere((p) => p.episodeId == event.episodeId);

          // Backend sends completedItems as a list of segment indices (ints).
          completedIndices = (progress.completedItems as List<dynamic>)
              .map((e) => int.tryParse(e.toString()) ?? -1)
              .where((i) => i >= 0 && i <= 4)
              .toList();

          // If episode was already fully completed, restart from Hook (index 0)
          // so the user can replay freely. Otherwise resume where they left off.
          if (progress.completed) {
            resumeIndex = 0;
          } else if (progress.lastViewedItemId != null &&
              progress.lastViewedItemId!.startsWith('segment_')) {
            resumeIndex =
                int.tryParse(progress.lastViewedItemId!.split('_').last) ?? 0;
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

      // Sync to backend – never compute completion locally.
      _repository.updateEpisodeProgress(
        episodeId: s.episode.id,
        completedSegments: updatedCompleted,
        lastViewedItemId: 'segment_$nextIndex',
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
      // Only allow jumping to already-reached segments.
      if (event.index < 0 || event.index > s.currentSegmentIndex) return;

      emit(s.copyWith(currentSegmentIndex: event.index));
      _repository.updateEpisodeProgress(
        episodeId: s.episode.id,
        completedSegments: s.completedSegmentIndices,
        lastViewedItemId: 'segment_${event.index}',
      );
    });

    // ── Answer Question ───────────────────────────────────────────────────────
    on<_AnswerQuestion>((event, emit) {
      final s = state;
      if (s is! _EpisodePlayerLoaded) return;
      emit(s.copyWith(
        correctAnswers: s.correctAnswers + (event.isCorrect ? 1 : 0),
        questionsAnswered: s.questionsAnswered + 1,
      ));
    });

    // ── Update Reflection ─────────────────────────────────────────────────────
    on<_UpdateReflection>((event, emit) {
      final s = state;
      if (s is! _EpisodePlayerLoaded) return;
      emit(s.copyWith(
        reflectionMode: event.mode,
        reflectionContent: event.content,
      ));
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
      'quest': 15,
    };
  }
}
