import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Central Sound & Haptic Service for interactive gamified audio feedback
class AppSoundService {
  static final AppSoundService instance = AppSoundService._internal();
  AppSoundService._internal() {
    _initPlayer();
  }

  final AudioPlayer _player = AudioPlayer();
  String? _tempDir;

  Future<void> _initPlayer() async {
    try {
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.setPlayerMode(PlayerMode.lowLatency);
    } catch (_) {}
  }

  Future<String> _getTempPath(String filename) async {
    _tempDir ??= (await getTemporaryDirectory()).path;
    return '$_tempDir/$filename';
  }

  /// Play realistic multi-note metallic coin cascade sound effect when coins are collected
  Future<void> playBunchOfCoinsSound() async {
    try {
      HapticFeedback.mediumImpact();
      final path = await _getTempPath('coin_bunch_cascade.wav');
      final file = File(path);
      if (!await file.exists()) {
        final bytes = _generateCoinBunchWav();
        await file.writeAsBytes(bytes);
      }
      await _player.stop();
      await _player.play(DeviceFileSource(path));
    } catch (_) {
      HapticFeedback.vibrate();
    }
  }

  /// Play metallic coin collection sequence
  Future<void> playCoinChime() async {
    try {
      HapticFeedback.lightImpact();
      final path = await _getTempPath('coin_chime.wav');
      final file = File(path);
      if (!await file.exists()) {
        final bytes = _generateChimeWav(frequencies: [987.77, 1318.51, 1567.98, 1975.53], durationMs: 280);
        await file.writeAsBytes(bytes);
      }
      await _player.stop();
      await _player.play(DeviceFileSource(path));
    } catch (_) {
      HapticFeedback.mediumImpact();
    }
  }

  /// Play cheerful "Ting" chime tone for correct answers
  Future<void> playCorrect() async {
    try {
      HapticFeedback.mediumImpact();
      final path = await _getTempPath('ting.wav');
      final file = File(path);
      if (!await file.exists()) {
        final bytes = _generateChimeWav(frequencies: [880, 1320], durationMs: 250);
        await file.writeAsBytes(bytes);
      }
      await _player.stop();
      await _player.play(DeviceFileSource(path));
    } catch (_) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  /// Play double "Buzz" error tone for incorrect answers
  Future<void> playIncorrect() async {
    try {
      HapticFeedback.heavyImpact();
      final path = await _getTempPath('buzz.wav');
      final file = File(path);
      if (!await file.exists()) {
        final bytes = _generateBuzzWav(freq: 140, durationMs: 300);
        await file.writeAsBytes(bytes);
      }
      await _player.stop();
      await _player.play(DeviceFileSource(path));
    } catch (_) {
      HapticFeedback.vibrate();
    }
  }

  /// Play crisp "Pop" tap tone for selections / drag-and-drop
  Future<void> playPop() async {
    try {
      HapticFeedback.selectionClick();
      final path = await _getTempPath('pop.wav');
      final file = File(path);
      if (!await file.exists()) {
        final bytes = _generatePopWav(freq: 600, durationMs: 80);
        await file.writeAsBytes(bytes);
      }
      await _player.stop();
      await _player.play(DeviceFileSource(path));
    } catch (_) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  /// Play classy celebratory fanfare when confetti or ceremony opens
  Future<void> playFanfare() async {
    try {
      HapticFeedback.vibrate();
      final path = await _getTempPath('fanfare.wav');
      final file = File(path);
      final bytes = _generateArpeggioWav(
        frequencies: [523.25, 659.25, 783.99, 1046.50, 1318.51],
        durationPerNoteMs: 140,
      );
      await file.writeAsBytes(bytes);
      await _player.stop();
      await _player.play(DeviceFileSource(path));
    } catch (_) {
      HapticFeedback.vibrate();
    }
  }

  // ── Synthesized PCM Audio Generators ────────────────────────────────────────

  static Uint8List _generateChimeWav({required List<double> frequencies, required int durationMs}) {
    const sampleRate = 22050;
    final totalSamples = (sampleRate * (durationMs / 1000)).round();
    final pcmData = Int16List(totalSamples);

    final samplesPerNote = totalSamples ~/ frequencies.length;
    for (int i = 0; i < totalSamples; i++) {
      final noteIndex = (i ~/ samplesPerNote).clamp(0, frequencies.length - 1);
      final freq = frequencies[noteIndex];
      final t = i / sampleRate;

      final noteT = (i % samplesPerNote) / sampleRate;
      final envelope = exp(-noteT * 12);
      final sampleVal = (sin(2 * pi * freq * t) * 24000 * envelope).round();
      pcmData[i] = sampleVal.clamp(-32768, 32767);
    }
    return _buildWavHeader(pcmData, sampleRate);
  }

  static Uint8List _generateBuzzWav({required double freq, required int durationMs}) {
    const sampleRate = 22050;
    final totalSamples = (sampleRate * (durationMs / 1000)).round();
    final pcmData = Int16List(totalSamples);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final rawWave = (sin(2 * pi * freq * t) > 0 ? 1.0 : -1.0) * 0.7 + sin(2 * pi * (freq * 0.5) * t) * 0.3;
      final envelope = (1 - (i / totalSamples));
      final sampleVal = (rawWave * 20000 * envelope).round();
      pcmData[i] = sampleVal.clamp(-32768, 32767);
    }
    return _buildWavHeader(pcmData, sampleRate);
  }

  static Uint8List _generatePopWav({required double freq, required int durationMs}) {
    const sampleRate = 22050;
    final totalSamples = (sampleRate * (durationMs / 1000)).round();
    final pcmData = Int16List(totalSamples);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / sampleRate;
      final envelope = exp(-t * 40);
      final sampleVal = (sin(2 * pi * freq * t) * 26000 * envelope).round();
      pcmData[i] = sampleVal.clamp(-32768, 32767);
    }
    return _buildWavHeader(pcmData, sampleRate);
  }

  static Uint8List _generateArpeggioWav({required List<double> frequencies, required int durationPerNoteMs}) {
    const sampleRate = 22050;
    final samplesPerNote = (sampleRate * (durationPerNoteMs / 1000)).round();
    final totalSamples = samplesPerNote * frequencies.length;
    final pcmData = Int16List(totalSamples);

    for (int i = 0; i < totalSamples; i++) {
      final noteIndex = (i ~/ samplesPerNote).clamp(0, frequencies.length - 1);
      final freq = frequencies[noteIndex];
      final t = i / sampleRate;
      final noteT = (i % samplesPerNote) / sampleRate;

      final envelope = (1 - (noteT / (durationPerNoteMs / 1000))) * exp(-noteT * 4);
      final sampleVal = ((sin(2 * pi * freq * t) + 0.3 * sin(2 * pi * freq * 2 * t)) * 18000 * envelope).round();
      pcmData[i] = sampleVal.clamp(-32768, 32767);
    }
    return _buildWavHeader(pcmData, sampleRate);
  }

  static Uint8List _generateCoinBunchWav() {
    const sampleRate = 22050;
    const durationMs = 450;
    final totalSamples = (sampleRate * (durationMs / 1000)).round();
    final pcmData = Int16List(totalSamples);

    final coinClinks = [
      {'startMs': 0, 'freq': 1174.66, 'decay': 35.0},
      {'startMs': 40, 'freq': 1567.98, 'decay': 30.0},
      {'startMs': 80, 'freq': 1760.00, 'decay': 32.0},
      {'startMs': 120, 'freq': 2093.00, 'decay': 28.0},
      {'startMs': 160, 'freq': 2349.32, 'decay': 30.0},
      {'startMs': 200, 'freq': 2637.02, 'decay': 25.0},
      {'startMs': 250, 'freq': 3135.96, 'decay': 22.0},
    ];

    for (final clink in coinClinks) {
      final startSample = ((clink['startMs'] as int) * sampleRate / 1000).round();
      final freq = clink['freq'] as double;
      final decay = clink['decay'] as double;

      for (int i = startSample; i < totalSamples; i++) {
        final t = (i - startSample) / sampleRate;
        final env = exp(-t * decay);
        if (env < 0.001) break;

        final sampleVal = ((sin(2 * pi * freq * t) + 0.4 * sin(2 * pi * (freq * 2.4) * t)) * 14000 * env).round();
        pcmData[i] = (pcmData[i] + sampleVal).clamp(-32768, 32767);
      }
    }

    return _buildWavHeader(pcmData, sampleRate);
  }

  static Uint8List _buildWavHeader(Int16List pcmData, int sampleRate) {
    const bytesPerSample = 2;
    final dataSize = pcmData.length * bytesPerSample;
    final fileSize = 36 + dataSize;

    final buffer = Uint8List(44 + dataSize);
    final byteData = ByteData.view(buffer.buffer);

    buffer.setRange(0, 4, 'RIFF'.codeUnits);
    byteData.setUint32(4, fileSize, Endian.little);
    buffer.setRange(8, 12, 'WAVE'.codeUnits);

    buffer.setRange(12, 16, 'fmt '.codeUnits);
    byteData.setUint32(16, 16, Endian.little);
    byteData.setUint16(20, 1, Endian.little);
    byteData.setUint16(22, 1, Endian.little);
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, sampleRate * bytesPerSample, Endian.little);
    byteData.setUint16(32, bytesPerSample, Endian.little);
    byteData.setUint16(34, 16, Endian.little);

    buffer.setRange(36, 40, 'data'.codeUnits);
    byteData.setUint32(40, dataSize, Endian.little);

    for (int i = 0; i < pcmData.length; i++) {
      byteData.setInt16(44 + (i * 2), pcmData[i], Endian.little);
    }

    return buffer;
  }
}
