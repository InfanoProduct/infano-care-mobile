import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:infano_care_mobile/features/tracker/data/models/tracker_models.dart';
import 'package:infano_care_mobile/features/tracker/data/repositories/tracker_repository.dart';

part 'tracker_bloc.freezed.dart';

@freezed
class TrackerEvent with _$TrackerEvent {
  const factory TrackerEvent.load() = _Load;
  const factory TrackerEvent.logDaily(Map<String, dynamic> data) = _LogDaily;
  const factory TrackerEvent.setup(Map<String, dynamic> data) = _Setup;
}

@freezed
class TrackerState with _$TrackerState {
  const factory TrackerState.initial() = _Initial;
  const factory TrackerState.loading() = _Loading;
  const factory TrackerState.loaded({
    required CycleProfileModel profile,
    PredictionResultModel? prediction,
    @Default([]) List<CycleLogModel> recentLogs,
    String? milestone,
  }) = _Loaded;
  const factory TrackerState.error(String message) = _Error;
}

class TrackerBloc extends Bloc<TrackerEvent, TrackerState> {
  final TrackerRepository _repository;

  TrackerBloc(this._repository) : super(const TrackerState.initial()) {
    on<_Load>((event, emit) async {
      emit(const TrackerState.loading());
      try {
        final profile = await _repository.getProfile();
        if (profile == null) {
          emit(const TrackerState.error('No cycle profile found'));
          return;
        }

        final prediction = await _repository.getPrediction();
        final logs = await _repository.getLogs();

        emit(TrackerState.loaded(
          profile: profile,
          prediction: prediction,
          recentLogs: logs,
        ));
      } catch (e) {
        emit(TrackerState.error(e.toString()));
      }
    });

    on<_LogDaily>((event, emit) async {
      final currentState = state;
      if (currentState is! _Loaded) return;

      try {
        final result = await _repository.logDaily(event.data);
        final profile = await _repository.getProfile();
        final prediction = await _repository.getPrediction();
        final logs = await _repository.getLogs();

        if (profile != null) {
          emit(TrackerState.loaded(
            profile: profile,
            prediction: prediction,
            recentLogs: logs,
            milestone: result['milestone'], // Pass milestone to UI
          ));
        }
      } catch (e) {
        // Handle error toast in UI
      }
    });

    on<_Setup>((event, emit) async {
      emit(const TrackerState.loading());
      try {
        await _repository.setupTracker(event.data);
        add(const TrackerEvent.load());
      } catch (e) {
        emit(TrackerState.error(e.toString()));
      }
    });
  }
}
