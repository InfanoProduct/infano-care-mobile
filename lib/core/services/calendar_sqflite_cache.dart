import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:infano_care_mobile/features/tracker/data/models/tracker_models.dart';

/// SQLite-backed cache for the period tracker calendar.
///
/// Three tables, one per data type — each row stores a JSON payload
/// and an [expiresAt] epoch-millisecond timestamp.
///
///  - logs       key = `year_month`    TTL = 30 min
///  - prediction key = `latest`        TTL =  5 min
///  - cycles     key = `latest`        TTL = 60 min
class CalendarSqfliteCache {
  static const _dbName = 'infano_calendar_cache.db';
  static const _dbVersion = 1;

  static const _tableLogs = 'logs_cache';
  static const _tablePrediction = 'prediction_cache';
  static const _tableCycles = 'cycles_cache';
  static const _tableOfflineQueue = 'offline_queue';

  static const _ttlLogs = Duration(minutes: 30);
  static const _ttlPrediction = Duration(minutes: 5);
  static const _ttlCycles = Duration(hours: 1);

  Database? _db;

  Future<Database> get _database async {
    _db ??= await _openDb();
    return _db!;
  }

  Future<Database> _openDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE $_tableLogs (
            key TEXT PRIMARY KEY,
            payload TEXT NOT NULL,
            expires_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE $_tablePrediction (
            key TEXT PRIMARY KEY,
            payload TEXT NOT NULL,
            expires_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE $_tableCycles (
            key TEXT PRIMARY KEY,
            payload TEXT NOT NULL,
            expires_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE $_tableOfflineQueue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            endpoint TEXT NOT NULL,
            payload TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  // ── Logs ───────────────────────────────────────────────────────────────────

  /// Returns cached logs for a given [year]/[month] window, or null if
  /// missing / expired.
  Future<List<CycleLogModel>?> getLogs(int year, int month) async {
    final key = '${year}_$month';
    return _getList<CycleLogModel>(
      _tableLogs,
      key,
      (j) => CycleLogModel.fromJson(j),
    );
  }

  Future<void> putLogs(int year, int month, List<CycleLogModel> logs) async {
    final key = '${year}_$month';
    await _putList(
      _tableLogs,
      key,
      logs.map((l) => l.toJson()).toList(),
      _ttlLogs,
    );
  }

  /// Evict all cached log windows (called after POST /logs).
  Future<void> invalidateLogs() async {
    final db = await _database;
    await db.delete(_tableLogs);
    debugPrint('[Cache] 🗑 Logs cache invalidated');
  }

  /// Optimistic patch: upsert a single [log] inside the cached JSON list
  /// for a given [year]/[month] without invalidating the whole window.
  ///
  /// If the month is not cached yet, this is a no-op (next full fetch will
  /// hydrate it from the network).
  Future<void> patchLog(int year, int month, CycleLogModel log) async {
    final key = '${year}_$month';
    final db  = await _database;
    final rows = await db.query(_tableLogs,
        where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return; // cache miss — nothing to patch

    final row = rows.first;
    // If TTL already expired, leave it — next fetch will refresh anyway
    if (_isExpired(row['expires_at'] as int)) return;

    List<dynamic> list;
    try {
      list = jsonDecode(row['payload'] as String) as List<dynamic>;
    } catch (_) {
      return;
    }

    final logJson = log.toJson();
    final logDate = log.date.toIso8601String().split('T').first;

    // Replace existing entry for this date or append
    final idx = list.indexWhere((e) {
      final d = (e as Map<String, dynamic>)['date'] as String? ?? '';
      return d.startsWith(logDate);
    });
    if (idx >= 0) {
      list[idx] = logJson;
    } else {
      list.add(logJson);
    }

    await db.update(
      _tableLogs,
      {'payload': jsonEncode(list)},
      where: 'key = ?',
      whereArgs: [key],
    );
    debugPrint('[Cache] 🩹 Patched log for $logDate in $key');
  }

  // ── Prediction ─────────────────────────────────────────────────────────────

  Future<PredictionResultModel?> getPrediction() async {
    final db = await _database;
    final rows = await db.query(
      _tablePrediction,
      where: 'key = ?',
      whereArgs: ['latest'],
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    if (_isExpired(row['expires_at'] as int)) {
      await db.delete(_tablePrediction, where: 'key = ?', whereArgs: ['latest']);
      return null;
    }
    try {
      return PredictionResultModel.fromJson(
        jsonDecode(row['payload'] as String) as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('[Cache] ⚠️ Failed to decode prediction: $e');
      return null;
    }
  }

  Future<void> putPrediction(PredictionResultModel prediction) async {
    final db = await _database;
    await db.insert(
      _tablePrediction,
      {
        'key': 'latest',
        'payload': jsonEncode(prediction.toJson()),
        'expires_at': _expiresAt(_ttlPrediction),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Force-evict the prediction row so the next [getPrediction] goes to network.
  Future<void> invalidatePrediction() async {
    final db = await _database;
    await db.delete(_tablePrediction, where: 'key = ?', whereArgs: ['latest']);
    debugPrint('[Cache] 🗑 Prediction cache invalidated');
  }

  /// Force-evict the cycles row.
  Future<void> invalidateCycles() async {
    final db = await _database;
    await db.delete(_tableCycles, where: 'key = ?', whereArgs: ['latest']);
    debugPrint('[Cache] 🗑 Cycles cache invalidated');
  }

  // ── Cycles ─────────────────────────────────────────────────────────────────

  Future<List<CycleRecordModel>?> getCycles() async {
    return _getList<CycleRecordModel>(
      _tableCycles,
      'latest',
      (j) => CycleRecordModel.fromJson(j),
    );
  }

  Future<void> putCycles(List<CycleRecordModel> cycles) async {
    await _putList(
      _tableCycles,
      'latest',
      cycles.map((c) => c.toJson()).toList(),
      _ttlCycles,
    );
  }

  // ── Offline queue ──────────────────────────────────────────────────────────

  /// Enqueue a failed POST body to be retried on reconnect.
  Future<void> enqueueOfflineLog(Map<String, dynamic> payload) async {
    final db = await _database;
    await db.insert(_tableOfflineQueue, {
      'endpoint': '/tracker/logs',
      'payload': jsonEncode(payload),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    debugPrint('[Cache] 📥 Queued offline log: $payload');
  }

  /// Return all pending offline items ordered oldest-first.
  Future<List<Map<String, dynamic>>> dequeueOfflineLogs() async {
    final db = await _database;
    final rows = await db.query(
      _tableOfflineQueue,
      orderBy: 'created_at ASC',
    );
    return rows.map((r) {
      return jsonDecode(r['payload'] as String) as Map<String, dynamic>;
    }).toList();
  }

  /// Remove all offline queue entries (called after successful sync).
  Future<void> clearOfflineQueue() async {
    final db = await _database;
    final count = await db.delete(_tableOfflineQueue);
    debugPrint('[Cache] ✅ Cleared $count offline queued items');
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<List<T>?> _getList<T>(
    String table,
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final db = await _database;
    final rows = await db.query(table, where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    final row = rows.first;
    if (_isExpired(row['expires_at'] as int)) {
      await db.delete(table, where: 'key = ?', whereArgs: [key]);
      return null;
    }
    try {
      final list = jsonDecode(row['payload'] as String) as List<dynamic>;
      return list.map((j) => fromJson(j as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('[Cache] ⚠️ Failed to decode $table/$key: $e');
      return null;
    }
  }

  Future<void> _putList(
    String table,
    String key,
    List<Map<String, dynamic>> items,
    Duration ttl,
  ) async {
    final db = await _database;
    await db.insert(
      table,
      {
        'key': key,
        'payload': jsonEncode(items),
        'expires_at': _expiresAt(ttl),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  bool _isExpired(int expiresAtMs) =>
      DateTime.now().millisecondsSinceEpoch >= expiresAtMs;

  int _expiresAt(Duration ttl) =>
      DateTime.now().add(ttl).millisecondsSinceEpoch;

  Future<void> dispose() async {
    await _db?.close();
    _db = null;
  }
}
