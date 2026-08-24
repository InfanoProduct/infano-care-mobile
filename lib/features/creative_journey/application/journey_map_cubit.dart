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
  final bool isRefreshing;

  JourneyMapLoaded({
    required this.journeys,
    this.allProgress = const [],
    this.growthStreakDays = 0,
    this.isRefreshing = false,
  });

  JourneyMapLoaded copyWith({
    List<CreativeJourney>? journeys,
    List<NodeProgress>? allProgress,
    int? growthStreakDays,
    bool? isRefreshing,
  }) {
    return JourneyMapLoaded(
      journeys: journeys ?? this.journeys,
      allProgress: allProgress ?? this.allProgress,
      growthStreakDays: growthStreakDays ?? this.growthStreakDays,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  /// Returns the completed node count for a given episode
  int completedNodesForEpisode(String episodeId) {
    return allProgress
        .where((p) => (p.episodeId == episodeId || p.nodeId.startsWith(_getPrefix(episodeId))) && p.isCompleted)
        .length;
  }

  String _getPrefix(String episodeId) {
    switch (episodeId) {
      case 'ce_body_timeline':
        return 'bt_';
      case 'ce_growing_pains':
        return 'gp_';
      case 'ce_skin_stories':
        return 'ss_';
      case 'ce_period_preview':
        return 'pp_';
      case 'ce_bra_basics':
        return 'bb_';
      case 'ce_body_image':
        return 'bi_';
      case 'ce_cycle_basics':
        return 'cb_';
      default:
        return episodeId.replaceAll('ce_', '');
    }
  }
}

class JourneyMapError extends JourneyMapState {
  final String message;
  JourneyMapError(this.message);
}

// ── Cubit ──────────────────────────────────────────────────────────────────────

class JourneyMapCubit extends Cubit<JourneyMapState> {
  final CreativeJourneyRepository _repo;

  static List<CreativeJourney>? _cachedJourneys;
  static List<NodeProgress>? _cachedProgress;

  JourneyMapCubit(this._repo) : super(JourneyMapInitial());

  Future<void> load({bool isRefresh = false}) async {
    final currentState = state;

    if (currentState is JourneyMapLoaded) {
      emit(currentState.copyWith(isRefreshing: true));
    } else if (_cachedJourneys != null && _cachedProgress != null) {
      emit(JourneyMapLoaded(
        journeys: _cachedJourneys!,
        allProgress: _cachedProgress!,
        isRefreshing: true,
      ));
    } else if (!isRefresh) {
      emit(JourneyMapLoading());
    }

    try {
      final results = await Future.wait([
        _repo.listJourneys(),
        _repo.getMyProgress(),
      ]);

      final journeys = results[0] as List<CreativeJourney>;
      final allProgress = results[1] as List<NodeProgress>;

      _cachedJourneys = journeys;
      _cachedProgress = allProgress;

      emit(JourneyMapLoaded(
        journeys: journeys,
        allProgress: allProgress,
        growthStreakDays: 0,
        isRefreshing: false,
      ));
    } catch (e) {
      if (currentState is JourneyMapLoaded) {
        emit(currentState.copyWith(isRefreshing: false));
      } else if (_cachedJourneys != null && _cachedProgress != null) {
        emit(JourneyMapLoaded(
          journeys: _cachedJourneys!,
          allProgress: _cachedProgress!,
          isRefreshing: false,
        ));
      } else {
        emit(JourneyMapError(e.toString()));
      }
    }
  }

  void refresh() => load(isRefresh: true);
}
