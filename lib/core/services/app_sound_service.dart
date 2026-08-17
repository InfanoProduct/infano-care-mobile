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
