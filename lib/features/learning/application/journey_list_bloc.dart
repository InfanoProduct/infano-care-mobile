import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../models/learning_models.dart';
import '../repositories/learning_repository.dart';

part 'journey_list_bloc.freezed.dart';

@freezed
class JourneyListEvent with _$JourneyListEvent {
  const factory JourneyListEvent.loadJourneys({String? ageBand}) = _LoadJourneys;
}

@freezed
class JourneyListState with _$JourneyListState {
  const factory JourneyListState.initial() = _Initial;
  const factory JourneyListState.loading() = _Loading;
  const factory JourneyListState.loaded(List<LearningJourney> journeys) = _Loaded;
  const factory JourneyListState.error(String message) = _Error;
}

class JourneyListBloc extends Bloc<JourneyListEvent, JourneyListState> {
  final LearningRepository _repository;

  JourneyListBloc(this._repository) : super(const JourneyListState.initial()) {
    on<_LoadJourneys>((event, emit) async {
      emit(const JourneyListState.loading());
      try {
        final journeys = await _repository.listJourneys(ageBand: event.ageBand);
        emit(JourneyListState.loaded(journeys));
      } catch (e) {
        emit(JourneyListState.error(e.toString()));
      }
    });
  }
}
