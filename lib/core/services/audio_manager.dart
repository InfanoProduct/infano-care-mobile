import 'package:audioplayers/audioplayers.dart';

/// Centralized audio manager that ensures only one voice note plays at any time.
class AudioManager {
  AudioManager._();
  static final AudioManager instance = AudioManager._();

  AudioPlayer? _activePlayer;
  String? _activeUrl;

  AudioPlayer? get activePlayer => _activePlayer;
  String? get activeUrl => _activeUrl;

  Future<void> registerAndPlay(AudioPlayer player, String url, Source source) async {
    if (_activePlayer != null && _activePlayer != player) {
      try {
        await _activePlayer?.pause();
      } catch (_) {}
    }
    _activePlayer = player;
    _activeUrl = url;
    await player.play(source);
  }

  void stopIfActive(AudioPlayer player) {
    if (_activePlayer == player) {
      _activePlayer = null;
      _activeUrl = null;
    }
  }
}
