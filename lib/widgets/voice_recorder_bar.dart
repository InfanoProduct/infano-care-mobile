import 'dart:async';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';

class VoiceRecorderBar extends StatefulWidget {
  final Function(String filePath, int durationSeconds) onRecordingFinished;
  final VoidCallback onCancel;
  final Color primaryColor;

  const VoiceRecorderBar({
    super.key,
    required this.onRecordingFinished,
    required this.onCancel,
    this.primaryColor = const Color(0xFF6D28D9),
  });

  @override
  State<VoiceRecorderBar> createState() => _VoiceRecorderBarState();
}

class _VoiceRecorderBarState extends State<VoiceRecorderBar> with SingleTickerProviderStateMixin {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordingPath;
  Timer? _timer;
  int _seconds = 0;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _startRecording();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission is required to record voice notes.')),
          );
          widget.onCancel();
        }
        return;
      }

      final dir = await getTemporaryDirectory();
      _recordingPath = '${dir.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';

      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      );

      await _audioRecorder.start(config, path: _recordingPath!);

      setState(() {
        _isRecording = true;
        _seconds = 0;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() => _seconds++);
        }
      });
    } catch (e) {
      debugPrint('[VoiceRecorderBar] Error starting recording: $e');
      if (mounted) widget.onCancel();
    }
  }

  Future<void> _stopAndSend() async {
    try {
      _timer?.cancel();
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);

      if (path != null && _seconds >= 1) {
        widget.onRecordingFinished(path, _seconds);
      } else {
        widget.onCancel();
      }
    } catch (e) {
      debugPrint('[VoiceRecorderBar] Error stopping recording: $e');
      widget.onCancel();
    }
  }

  Future<void> _cancelRecording() async {
    try {
      _timer?.cancel();
      await _audioRecorder.stop();
      setState(() => _isRecording = false);
    } catch (_) {}
    widget.onCancel();
  }

  String _formatTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: widget.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: widget.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          // Pulsing red recording dot
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withValues(alpha: 0.4 + (_pulseController.value * 0.6)),
                ),
              );
            },
          ),
          const SizedBox(width: 8),

          // Duration Timer
          Text(
            _formatTime(_seconds),
            style: GoogleFonts.nunito(
              color: Colors.red.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 12),

          // Waveform bars simulation
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(12, (index) {
                final height = (8.0 + ((index * 7 + _seconds * 5) % 18)).toDouble();
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  width: 3,
                  height: height,
                  decoration: BoxDecoration(
                    color: widget.primaryColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),

          // Cancel / Delete Button
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey, size: 22),
            onPressed: _cancelRecording,
            tooltip: 'Cancel recording',
          ),

          const SizedBox(width: 4),

          // Send Button
          Container(
            decoration: BoxDecoration(
              color: widget.primaryColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
              onPressed: _stopAndSend,
              tooltip: 'Send voice note',
            ),
          ),
        ],
      ),
    );
  }
}
