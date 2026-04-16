import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../models/learning_models.dart';
import '../repositories/learning_repository.dart';

part 'journey_detail_bloc.freezed.dart';

@freezed
class JourneyDetailEvent with _$JourneyDetailEvent {
  const factory JourneyDetailEvent.loadJourney(String journeyId) = _LoadJourney;
}

@freezed
class JourneyDetailState with _$JourneyDetailState {
  const factory JourneyDetailState.initial() = _Initial;
  const factory JourneyDetailState.loading() = _Loading;
  const factory JourneyDetailState.loaded(LearningJourney journey, List<UserProgress> userProgress) = _JourneyDetailLoaded;
  const factory JourneyDetailState.error(String message) = _Error;
}

class JourneyDetailBloc extends Bloc<JourneyDetailEvent, JourneyDetailState> {
  final LearningRepository _repository;

  JourneyDetailBloc(this._repository) : super(const JourneyDetailState.initial()) {
    on<_LoadJourney>((event, emit) async {
      emit(const JourneyDetailState.loading());
      try {
        final journey = await _repository.getJourney(event.journeyId);
        final progress = await _repository.getMyProgress();
        emit(JourneyDetailState.loaded(journey, progress));
      } catch (e) {
        emit(JourneyDetailState.error(e.toString()));
      }
    });
  }
}
