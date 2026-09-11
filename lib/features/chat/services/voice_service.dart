import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class GigiMobileVoiceService {
  static final GigiMobileVoiceService _instance = GigiMobileVoiceService._internal();
  factory GigiMobileVoiceService() => _instance;
  GigiMobileVoiceService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isSpeechInitialized = false;
  bool _isTtsInitialized = false;
  bool _isListening = false;
  bool _isSpeaking = false;

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;

  // Clean text for speech synthesis (strip tags, links, options, emojis)
  static String cleanTextForSpeech(String text) {
    if (text.isEmpty) return '';
    return text
        .replaceAll(RegExp(r'\[\s*link\s*:\s*[^\]]+?\]'), '')
        .replaceAll(RegExp(r'\[\s*option\s*:\s*([^\]]+?)\]'), '')
        .replaceAll(RegExp(r'[*_#`~>]'), '')
        .replaceAll(
          RegExp(
            r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]',
            unicode: true,
          ),
          '',
        )
        .trim();
  }

  // Initialize Speech-to-Text
  Future<bool> initSpeech() async {
    if (_isSpeechInitialized) return true;
    try {
      _isSpeechInitialized = await _speech.initialize(
        onError: (val) {
          debugPrint('[GigiVoice] Speech error: $val');
          _isListening = false;
        },
        onStatus: (val) {
          debugPrint('[GigiVoice] Speech status: $val');
          if (val == 'done' || val == 'notListening') {
            _isListening = false;
          }
        },
      );
      return _isSpeechInitialized;
    } catch (e) {
      debugPrint('[GigiVoice] Failed to init speech: $e');
      return false;
    }
  }

  // Initialize TTS
  Future<void> initTts() async {
    if (_isTtsInitialized) return;
    try {
      await _tts.setLanguage('en-IN');
      await _tts.setPitch(1.05);
      await _tts.setSpeechRate(0.48);

      _tts.setStartHandler(() {
        _isSpeaking = true;
      });

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
      });

      _tts.setErrorHandler((msg) {
        debugPrint('[GigiVoice] TTS error: $msg');
        _isSpeaking = false;
      });

      _isTtsInitialized = true;
    } catch (e) {
      debugPrint('[GigiVoice] Failed to init TTS: $e');
    }
  }

  // Start listening to microphone
  Future<void> startListening({
    required Function(String text, bool isFinal) onResult,
    Function()? onStart,
    Function()? onEnd,
  }) async {
    stopSpeaking();

    final available = await initSpeech();
    if (!available) {
      debugPrint('[GigiVoice] Speech recognition not available');
      return;
    }

    _isListening = true;
    onStart?.call();

    try {
      await _speech.listen(
        onResult: (result) {
          onResult(result.recognizedWords, result.finalResult);
          if (result.finalResult) {
            _isListening = false;
            onEnd?.call();
          }
        },
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_IN',
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
        ),
      );
    } catch (e) {
      debugPrint('[GigiVoice] Error starting listen: $e');
      _isListening = false;
      onEnd?.call();
    }
  }

  // Stop listening
  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }

  // Speak response
  Future<void> speak(
    String text, {
    VoidCallback? onStart,
    VoidCallback? onComplete,
  }) async {
    await initTts();
    await stopSpeaking();

    final cleaned = cleanTextForSpeech(text);
    if (cleaned.isEmpty) {
      onComplete?.call();
      return;
    }

    _isSpeaking = true;
    onStart?.call();

    _tts.setCompletionHandler(() {
      _isSpeaking = false;
      onComplete?.call();
    });

    _tts.setErrorHandler((_) {
      _isSpeaking = false;
      onComplete?.call();
    });

    await _tts.speak(cleaned);
  }

  // Stop speaking
  Future<void> stopSpeaking() async {
    if (_isSpeaking) {
      await _tts.stop();
      _isSpeaking = false;
    }
  }
}
