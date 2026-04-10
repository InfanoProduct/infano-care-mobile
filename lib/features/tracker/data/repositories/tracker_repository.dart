import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:infano_care_mobile/core/services/calendar_sqflite_cache.dart';
import 'package:infano_care_mobile/features/tracker/data/models/tracker_models.dart';
import 'package:infano_care_mobile/core/services/privacy_service.dart';

@lazySingleton
class TrackerRepository {
  final Dio _dio;
  final PrivacyService _privacyService;

  /// Singleton SQLite cache shared across all calls.
  final CalendarSqfliteCache _cache = CalendarSqfliteCache();

  TrackerRepository(this._dio, this._privacyService);

  // ── Connectivity helper ────────────────────────────────────────────────────

  Future<bool> get _isOnline async {
    final results = await Connectivity().checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }

  // ── Profile ────────────────────────────────────────────────────────────────

  Future<CycleProfileModel?> getProfile() async {
    try {
      final response = await _dio.get('/tracker/profile');
      if (response.statusCode == 200 && response.data != null) {
        return CycleProfileModel.fromJson(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ── Prediction (5-min TTL via SQLite) ─────────────────────────────────────

  Future<PredictionResultModel?> getPrediction() async =>
      getPredictionCached(forceRefresh: false);

  Future<PredictionResultModel?> getPredictionCached({
    bool forceRefresh = false,
  }) async {
    // 1. Fresh from network if online and not forced-cached
    if (!forceRefresh) {
      final cached = await _cache.getPrediction();
      if (cached != null) {
        debugPrint('[Repo] ✅ Prediction from cache');
        return cached;
      }
    }

    // 2. Network
    try {
      final response = await _dio.get('/tracker/prediction');
      if (response.statusCode == 200 && response.data != null) {
        final model = PredictionResultModel.fromJson(response.data);
        await _cache.putPrediction(model);
        return model;
      }
    } catch (e) {
      debugPrint('[Repo] ⚠️ Prediction fetch failed: $e');
    }

    // 3. Stale cache on error
    return _cache.getPrediction();
  }

  // ── Logs – 3-month window (30-min TTL via SQLite) ─────────────────────────

  /// Fetches logs for prev + current + next month window.
  /// [year] and [month] refer to the *current view* month.
  Future<List<CycleLogModel>> getLogsForWindow(
    int year,
    int month, {
    bool forceRefresh = false,
  }) async {
    // Cache is keyed per-month — fetch all 3 and merge
    final months = [
      DateTime(year, month - 1),
      DateTime(year, month),
      DateTime(year, month + 1),
    ];

    final merged = <CycleLogModel>[];

    for (final m in months) {
      final y = m.year;
      final mo = m.month;

      if (!forceRefresh) {
        final cached = await _cache.getLogs(y, mo);
        if (cached != null) {
          debugPrint('[Repo] ✅ Logs $y/$mo from cache (${cached.length} items)');
          merged.addAll(cached);
          continue;
        }
      }

      // Fetch from network
      final from = DateTime(y, mo, 1).toUtc().toIso8601String();
      final to =
          DateTime(y, mo + 1, 0, 23, 59, 59).toUtc().toIso8601String();
      try {
        final response = await _dio.get(
          '/tracker/logs',
          queryParameters: {'from': from, 'to': to},
        );
        if (response.statusCode == 200) {
          var logs = (response.data as List)
              .map((j) => CycleLogModel.fromJson(j))
              .toList();
          if (logs.isEmpty && (_isDemoMode())) logs = _getDummyLogsForMonth(y, mo);
          await _cache.putLogs(y, mo, logs);
          debugPrint('[Repo] 🌐 Logs $y/$mo from network (${logs.length} items)');
          merged.addAll(logs);
        }
      } catch (e) {
        debugPrint('[Repo] ⚠️ Log fetch failed for $y/$mo: $e');
        // Fallback: stale cache (ignore TTL)
        final stale = await _cache.getLogs(y, mo);
        if (stale != null) {
          merged.addAll(stale);
        } else {
          merged.addAll(_getDummyLogsForMonth(y, mo));
        }
      }
    }

    return merged;
  }

  /// Legacy getLogs kept for TrackerBloc compatibility.
  Future<List<CycleLogModel>> getLogs({String? from, String? to}) async {
    try {
      final response = await _dio.get('/tracker/logs', queryParameters: {
        if (from != null) 'from': from,
        if (to != null) 'to': to,
      });

      var logs = (response.data as List)
          .map((json) => CycleLogModel.fromJson(json))
          .toList();
      if (logs.isEmpty) logs = _getDummyLogs();
      return logs;
    } catch (e) {
      return _getDummyLogs();
    }
  }

  /// Evict the SQLite logs table — call after POST /logs.
  Future<void> invalidateLogsCache() => _cache.invalidateLogs();

  // ── Cycles (1-hour TTL via SQLite) ────────────────────────────────────────

  Future<List<CycleRecordModel>> getCyclesCached({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _cache.getCycles();
      if (cached != null) {
        debugPrint('[Repo] ✅ Cycles from cache');
        return cached;
      }
    }

    try {
      final response = await _dio.get('/tracker/history');
      if (response.statusCode == 200 && response.data != null) {
        final cycles = (response.data as List)
            .map((j) => CycleRecordModel.fromJson(j))
            .toList();
        final result = cycles.isEmpty ? _getDummyHistory() : cycles;
        await _cache.putCycles(result);
        return result;
      }
    } catch (e) {
      debugPrint('[Repo] ⚠️ Cycles fetch failed: $e');
    }

    // Stale cache fallback
    return (await _cache.getCycles()) ?? _getDummyHistory();
  }

  /// Legacy getHistory kept for TrackerBloc compatibility.
  Future<List<CycleRecordModel>> getHistory() async {
    try {
      final response = await _dio.get('/tracker/history');
      if (response.statusCode == 200 && response.data != null) {
        var history = (response.data as List)
            .map((json) => CycleRecordModel.fromJson(json))
            .toList();
        if (history.isEmpty) history = _getDummyHistory();
        return history;
      }
      return _getDummyHistory();
    } catch (e) {
      return _getDummyHistory();
    }
  }

  // ── Write operations ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> logDaily(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/tracker/log', data: data);
      // Invalidate logs cache on successful write
      await invalidateLogsCache();
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to log daily data');
    }
  }

  /// Offline-first variant used by [CalendarEditNotifier].
  ///
  /// 1. Writes optimistic [log] into the SQLite patch immediately.
  /// 2. If online: POSTs to API and returns the full response map.
  /// 3. If offline: enqueues the payload and returns an empty map so
  ///    the UI can still show the optimistic result.
  Future<Map<String, dynamic>> logDailyCached({
    required CycleLogModel optimisticLog,
    required Map<String, dynamic> apiPayload,
  }) async {
    // ── Optimistic SQLite patch ────────────────────────────────────────────
    await _cache.patchLog(
      optimisticLog.date.year,
      optimisticLog.date.month,
      optimisticLog,
    );

    final online = await _isOnline;
    if (!online) {
      await _cache.enqueueOfflineLog(apiPayload);
      debugPrint('[Repo] 📵 Offline — queued log for later sync');
      return {};
    }

    // ── Network POST ───────────────────────────────────────────────────────
    try {
      final response = await _dio.post('/tracker/logs', data: apiPayload);
      await invalidateLogsCache(); // full invalidation after confirmed write
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      debugPrint('[Repo] ⚠️ logDailyCached failed: $e');
      // Queue for retry and keep optimistic patch in place
      await _cache.enqueueOfflineLog(apiPayload);
      rethrow;
    }
  }

  /// Selectively invalidate prediction SQLite cache so next read forces network.
  Future<void> invalidatePredictionCache() => _cache.invalidatePrediction();

  /// Selectively invalidate cycles SQLite cache so next read forces network.
  Future<void> invalidateCyclesCache() => _cache.invalidateCycles();

  /// Drain the offline queue, POSTing each entry in order.
  /// Returns the number of items successfully synced.
  Future<int> syncOfflineQueue() async {
    final queue = await _cache.dequeueOfflineLogs();
    if (queue.isEmpty) return 0;
    debugPrint('[Repo] 🔄 Syncing ${queue.length} offline log(s)');

    int synced = 0;
    for (final payload in queue) {
      try {
        await _dio.post('/tracker/logs', data: payload);
        synced++;
      } catch (e) {
        debugPrint('[Repo] ⚠️ Sync failed for $payload: $e');
        // Stop on first failure — queue order must be preserved
        break;
      }
    }

    if (synced > 0) {
      await _cache.clearOfflineQueue();
      await invalidateLogsCache();
    }
    return synced;
  }

  Future<CycleProfileModel> setupTracker(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/tracker/setup', data: data);
      return CycleProfileModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to setup tracker');
    }
  }

  Future<void> updatePeriodRange(DateTime start, DateTime end) async {
    try {
      final startStr =
          "${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}";
      final endStr =
          "${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}";

      await _dio.post('/tracker/period-range', data: {
        'startDate': startStr,
        'endDate': endStr,
      });

      // Invalidate ALL relevant caches to ensure calendar updates correctly
      await invalidateLogsCache();
      await invalidateCyclesCache();
      await invalidatePredictionCache();
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to update period range');
    }
  }

  // ── Demo / Dummy data ──────────────────────────────────────────────────────

  bool _isDemoMode() => false; // Disabled to use real seeded data

  List<CycleLogModel> _getDummyLogsForMonth(int year, int month) {
    final from = DateTime(year, month, 1);
    final to = DateTime(year, month + 1, 0);
    final now = DateTime.now();
    final logs = <CycleLogModel>[];

    for (var d = from;
        !d.isAfter(to) && !d.isAfter(now);
        d = d.add(const Duration(days: 1))) {
      final dayOfCycle = d.difference(now).inDays.abs() % 28;
      String? flow;
      if (dayOfCycle >= 0 && dayOfCycle < 5) {
        flow = dayOfCycle == 0 || dayOfCycle == 4 ? 'light' : 'medium';
      }
      String? mood;
      if (d.day % 3 == 0) mood = 'Happy';
      if (d.day % 7 == 0) mood = 'Calm';

      logs.add(CycleLogModel(
        id: 'dummy_${d.year}_${d.month}_${d.day}',
        date: d,
        flow: flow,
        moodPrimary: mood,
        isRetroactive: d.isBefore(now.subtract(const Duration(days: 1))),
      ));
    }
    return logs;
  }

  List<CycleLogModel> _getDummyLogs() {
    final now = DateTime.now();
    final logs = <CycleLogModel>[];
    for (int i = 0; i < 90; i++) {
      final date = now.subtract(Duration(days: i));
      final dayOfCycle = i % 28;
      String? flow;
      if (dayOfCycle >= 0 && dayOfCycle < 5) {
        flow = dayOfCycle == 0 || dayOfCycle == 4 ? 'light' : 'medium';
      }
      String? mood;
      if (i % 3 == 0) mood = 'Happy';
      if (i % 7 == 0) mood = 'Calm';
      logs.add(CycleLogModel(
        id: 'dummy_$i',
        date: date,
        flow: flow,
        moodPrimary: mood,
        isRetroactive: i > 0,
      ));
    }
    return logs;
  }

  List<CycleRecordModel> _getDummyHistory() {
    final now = DateTime.now();
    return [
      CycleRecordModel(
        id: 'h1',
        cycleNumber: 1,
        startDate: now.subtract(const Duration(days: 28)),
        periodStartDate: now.subtract(const Duration(days: 28)),
        periodEndDate: now.subtract(const Duration(days: 23)),
        cycleLengthDays: 28,
        periodDurationDays: 5,
        isComplete: true,
      ),
      CycleRecordModel(
        id: 'h2',
        cycleNumber: 2,
        startDate: now.subtract(const Duration(days: 56)),
        periodStartDate: now.subtract(const Duration(days: 56)),
        periodEndDate: now.subtract(const Duration(days: 51)),
        cycleLengthDays: 28,
        periodDurationDays: 5,
        isComplete: true,
      ),
    ];
  }
}
