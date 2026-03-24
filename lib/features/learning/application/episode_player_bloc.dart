import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../models/learning_models.dart';
import '../repositories/learning_repository.dart';

part 'episode_player_bloc.freezed.dart';

@freezed
class EpisodePlayerEvent with _$EpisodePlayerEvent {
  const factory EpisodePlayerEvent.loadJourney(String journeyId) = _LoadJourney;
  const factory EpisodePlayerEvent.updateProgress(String itemId, dynamic data) = _UpdateProgress;
  const factory EpisodePlayerEvent.completeEpisode({
    required String episodeId,
    required int knowledgeCheckAccuracy,
    required String reflectionMode,
    String? reflectionContent,
    String? voiceUrl,
  }) = _CompleteEpisode;
}

@freezed
class EpisodePlayerState with _$EpisodePlayerState {
  const factory EpisodePlayerState.initial() = _Initial;
  const factory EpisodePlayerState.loading() = _Loading;
  const factory EpisodePlayerState.loaded(LearningJourney journey) = _Loaded;
  const factory EpisodePlayerState.submitting() = _Submitting;
  const factory EpisodePlayerState.completed({required int pointsEarned}) = _Completed;
  const factory EpisodePlayerState.error(String message) = _Error;
}

class EpisodePlayerBloc extends Bloc<EpisodePlayerEvent, EpisodePlayerState> {
  final LearningRepository _repository;
  final List<dynamic> _completedItems = [];
  String? _lastViewedItemId;

  EpisodePlayerBloc(this._repository) : super(const EpisodePlayerState.initial()) {
    on<_LoadJourney>((event, emit) async {
      emit(const EpisodePlayerState.loading());
      try {
        final journey = await _repository.getJourney(event.journeyId);
        emit(EpisodePlayerState.loaded(journey));
      } catch (e) {
        emit(EpisodePlayerState.error(e.toString()));
      }
    });

    on<_UpdateProgress>((event, emit) {
      _completedItems.add({
        'itemId': event.itemId,
        'data': event.data,
        'completedAt': DateTime.now().toIso8601String()
      });
      _lastViewedItemId = event.itemId;
    });

    on<_CompleteEpisode>((event, emit) async {
      emit(const EpisodePlayerState.submitting());
      try {
        await _repository.completeEpisode(
          episodeId: event.episodeId,
          knowledgeCheckAccuracy: event.knowledgeCheckAccuracy,
          reflectionMode: event.reflectionMode,
          reflectionContent: event.reflectionContent,
          voiceUrl: event.voiceUrl,
        );
        emit(const EpisodePlayerState.completed(pointsEarned: 0));
      } catch (e) {
        emit(EpisodePlayerState.error(e.toString()));
      }
    });
  }
}
