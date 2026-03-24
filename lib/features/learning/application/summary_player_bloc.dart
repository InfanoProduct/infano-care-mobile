import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../models/learning_models.dart';
import '../repositories/learning_repository.dart';

part 'summary_player_bloc.freezed.dart';

@freezed
class SummaryPlayerEvent with _$SummaryPlayerEvent {
  const factory SummaryPlayerEvent.loadSummary(String journeyId) = _LoadSummary;
  const factory SummaryPlayerEvent.completeItem(String itemId, dynamic data) = _CompleteItem;
  const factory SummaryPlayerEvent.submitSummary(String summaryId) = _SubmitSummary;
}

@freezed
class SummaryPlayerState with _$SummaryPlayerState {
  const factory SummaryPlayerState.initial() = _Initial;
  const factory SummaryPlayerState.loading() = _Loading;
  const factory SummaryPlayerState.loaded(LearningJourney journey) = _Loaded;
  const factory SummaryPlayerState.submitting() = _Submitting;
  const factory SummaryPlayerState.completed() = _Completed;
  const factory SummaryPlayerState.error(String message) = _Error;
}

class SummaryPlayerBloc extends Bloc<SummaryPlayerEvent, SummaryPlayerState> {
  final LearningRepository _repository;
  final List<dynamic> _completedItems = [];
  String? _lastViewedItemId;

  SummaryPlayerBloc(this._repository) : super(const SummaryPlayerState.initial()) {
    on<_LoadSummary>((event, emit) async {
      emit(const SummaryPlayerState.loading());
      try {
        final journey = await _repository.getJourney(event.journeyId);
        emit(SummaryPlayerState.loaded(journey));
      } catch (e) {
        emit(SummaryPlayerState.error(e.toString()));
      }
    });

    on<_CompleteItem>((event, emit) {
      _completedItems.add({'itemId': event.itemId, 'data': event.data, 'completedAt': DateTime.now().toIso8601String()});
      _lastViewedItemId = event.itemId;
    });

    on<_SubmitSummary>((event, emit) async {
      final currentState = state;
      if (currentState is! _Loaded) return;
      
      emit(const SummaryPlayerState.submitting());
      try {
        await _repository.completeSummary(
          summaryId: event.summaryId,
          completedItems: _completedItems,
          lastViewedItemId: _lastViewedItemId,
        );
        emit(const SummaryPlayerState.completed());
      } catch (e) {
        emit(SummaryPlayerState.error(e.toString()));
      }
    });
  }
}
