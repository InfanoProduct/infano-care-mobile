import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:infano_care_mobile/features/tracker/data/models/tracker_models.dart';
import 'package:infano_care_mobile/features/tracker/data/models/insight_models.dart';
import 'package:infano_care_mobile/features/tracker/data/repositories/tracker_repository.dart';

import 'package:infano_care_mobile/core/services/local_storage_service.dart';

part 'tracker_bloc.freezed.dart';

@freezed
class TrackerEvent with _$TrackerEvent {
  const factory TrackerEvent.load({@Default(false) bool isRefresh}) = _Load;
  const factory TrackerEvent.logDaily(Map<String, dynamic> data) = _LogDaily;
  const factory TrackerEvent.setup(Map<String, dynamic> data) = _Setup;
  const factory TrackerEvent.updatePeriodRange(DateTime start, DateTime end) = _UpdatePeriodRange;
}

@freezed
class TrackerState with _$TrackerState {
  const factory TrackerState.initial() = _Initial;
  const factory TrackerState.loading() = _Loading;
  const factory TrackerState.loaded({
    required CycleProfileModel profile,
    PredictionResultModel? prediction,
    @Default([]) List<CycleLogModel> recentLogs,
    @Default([]) List<CycleRecordModel> history,
    @Default([]) List<DailyInsight> dailyInsights,
    @Default([]) List<Map<String, String>> recommendedArticles,
    String? milestone,
    @Default(false) bool isRefreshing,
  }) = _Loaded;
  const factory TrackerState.notStarted() = _NotStarted;
  const factory TrackerState.error(String message) = _Error;
}


class TrackerBloc extends Bloc<TrackerEvent, TrackerState> {
  final TrackerRepository _repository;
  final LocalStorageService _storage;

  TrackerBloc(this._repository, this._storage) : super(const TrackerState.initial()) {
    on<_Load>((event, emit) async {
      final currentState = state;
      if (event.isRefresh && currentState is _Loaded) {
        emit(currentState.copyWith(isRefreshing: true));
      } else {
        emit(const TrackerState.loading());
      }
      try {
        final profile = await _repository.getProfile();
        if (profile == null) {
          emit(const TrackerState.notStarted());
          return;
        }

        // If we found a profile, the user IS onboarded for the tracker
        if (!_storage.isOnboarded) {
          await _storage.setIsOnboarded(true);
          await _storage.setStepComplete('13'); // Completed all steps
        }

        final prediction = await _repository.getPrediction();
        final logs = await _repository.getLogs();
        final history = await _repository.getHistory();
        final insightsData = await _repository.getDailyInsights();

        final dailyInsights = (insightsData['insights'] as List? ?? [])
            .map((i) => DailyInsight.fromJson(i as Map<String, dynamic>))
            .toList();

        final articles = (insightsData['articles'] as List? ?? [])
            .map((a) => Map<String, String>.from(a as Map))
            .toList();

        emit(TrackerState.loaded(
          profile: profile,
          prediction: prediction,
          recentLogs: logs,
          history: history,
          dailyInsights: dailyInsights,
          recommendedArticles: articles,
          isRefreshing: false,
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
        final history = await _repository.getHistory();

        if (profile != null) {
          emit(TrackerState.loaded(
            profile: profile,
            prediction: prediction,
            recentLogs: logs,
            history: history,
            dailyInsights: currentState.dailyInsights,
            recommendedArticles: currentState.recommendedArticles,
            milestone: result['milestone'],
          ));
        }
      } catch (e) {
        // Emit error so the UI can show a toast, then restore the previous state
        emit(TrackerState.error(e.toString()));
        await Future.delayed(const Duration(milliseconds: 100));
        emit(currentState);
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

    on<_UpdatePeriodRange>((event, emit) async {
      final currentState = state;
      if (currentState is! _Loaded) return;

      try {
        await _repository.updatePeriodRange(event.start, event.end);
        add(const TrackerEvent.load());
      } catch (e) {
        // Handle error in UI
      }
    });
  }
}
