import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/creative_journey_models.dart';
import '../repositories/creative_journey_repository.dart';

// ── State ──────────────────────────────────────────────────────────────────────

abstract class JourneyMapState {}

class JourneyMapInitial extends JourneyMapState {}

class JourneyMapLoading extends JourneyMapState {}

class JourneyMapLoaded extends JourneyMapState {
  final List<CreativeJourney> journeys;
  final List<NodeProgress> allProgress;
  final int growthStreakDays;

  JourneyMapLoaded({
    required this.journeys,
    this.allProgress = const [],
    this.growthStreakDays = 0,
  });

  /// Returns the completed node count for a given episode
  int completedNodesForEpisode(String episodeId) {
    return allProgress
        .where((p) => p.nodeId.startsWith('bt_') && p.isCompleted)
        .length;
  }
}

class JourneyMapError extends JourneyMapState {
  final String message;
  JourneyMapError(this.message);
}

// ── Cubit ──────────────────────────────────────────────────────────────────────

class JourneyMapCubit extends Cubit<JourneyMapState> {
  final CreativeJourneyRepository _repo;

  JourneyMapCubit(this._repo) : super(JourneyMapInitial());

  Future<void> load() async {
    emit(JourneyMapLoading());
    try {
      final journeys = await _repo.listJourneys();
      final allProgress = await _repo.getMyProgress();
      emit(JourneyMapLoaded(
        journeys: journeys,
        allProgress: allProgress,
        growthStreakDays: 0, // TODO: wire to UserStreak API
      ));
    } catch (e) {
      emit(JourneyMapError(e.toString()));
    }
  }

  void refresh() => load();
}
