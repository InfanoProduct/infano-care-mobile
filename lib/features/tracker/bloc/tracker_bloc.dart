import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:infano_care_mobile/core/services/local_storage_service.dart';
import 'package:infano_care_mobile/features/tracker/data/models/tracker_models.dart';
import 'package:infano_care_mobile/features/tracker/data/models/insight_models.dart';
import 'package:infano_care_mobile/features/tracker/data/repositories/tracker_repository.dart';

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
  const factory TrackerState.notStarted() = _NotStarted;
  const factory TrackerState.loaded({
    required CycleProfileModel profile,
    required PredictionResultModel? prediction,
    required List<CycleLogModel> recentLogs,
    required List<CycleRecordModel> history,
    required List<DailyInsight> dailyInsights,
    required List<Map<String, String>> recommendedArticles,
    String? milestone,
    @Default(0) int pointsEarned,
    @Default(false) bool isRefreshing,
  }) = _Loaded;
  const factory TrackerState.error(String message) = _Error;
}

class TrackerBloc extends Bloc<TrackerEvent, TrackerState> {
  final TrackerRepository _repository;
  final LocalStorageService _storage;

  TrackerBloc(this._repository, this._storage) : super(const TrackerState.initial()) {
    on<_Load>((event, emit) async {
      final currentState = state;
      if (currentState is _Loaded) {
        emit(currentState.copyWith(isRefreshing: true));
      } else if (!event.isRefresh) {
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
          await _storage.setStepComplete('11');
        }

        // Parallel API execution for maximum performance speedup (~150ms total)
        final results = await Future.wait([
          _repository.getPrediction(),
          _repository.getLogs(),
          _repository.getHistory(),
          _repository.getDailyInsights(),
        ]);

        final prediction = results[0] as PredictionResultModel?;
        final logs = (results[1] as List).cast<CycleLogModel>();
        final history = (results[2] as List).cast<CycleRecordModel>();
        final insightsData = results[3] as Map<String, dynamic>;

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
        if (currentState is _Loaded) {
          emit(currentState.copyWith(isRefreshing: false));
        } else {
          emit(TrackerState.error(e.toString()));
        }
      }
    });

    on<_LogDaily>((event, emit) async {
      final currentState = state;
      if (currentState is! _Loaded) return;

      try {
        final result = await _repository.logDaily(event.data);
        await _repository.invalidatePredictionCache();
        await _repository.invalidateCyclesCache();
        
        // Parallel API re-fetch on daily log
        final results = await Future.wait([
          _repository.getProfile(),
          _repository.getPrediction(),
          _repository.getLogs(),
          _repository.getHistory(),
        ]);

        final profile = results[0] as CycleProfileModel?;
        final prediction = results[1] as PredictionResultModel?;
        final logs = (results[2] as List).cast<CycleLogModel>();
        final history = (results[3] as List).cast<CycleRecordModel>();

        if (profile != null) {
          emit(TrackerState.loaded(
            profile: profile,
            prediction: prediction,
            recentLogs: logs,
            history: history,
            dailyInsights: currentState.dailyInsights,
            recommendedArticles: currentState.recommendedArticles,
            milestone: result['milestone'],
            pointsEarned: (result['points_earned'] as num?)?.toInt() ?? 0,
          ));
        }
      } catch (e) {
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

      emit(currentState.copyWith(milestone: "updating_tracker"));

      try {
        await _repository.updatePeriodRange(event.start, event.end);
        add(const TrackerEvent.load());
      } catch (e) {
        emit(currentState.copyWith(milestone: null));
      }
    });
  }
}
