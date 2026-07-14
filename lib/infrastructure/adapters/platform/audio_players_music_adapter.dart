import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/ports/music_service.dart';

/// AudioPlayersMusicAdapter — implements IMusicService using the
/// audioplayers package. Loops a bundled asset at a low volume, and
/// persists the mute preference across app launches via
/// shared_preferences.
///
/// Stateful (holds an AudioPlayer instance + the current asset +
/// mute flag), so DI registers this as a singleton.
class AudioPlayersMusicAdapter implements IMusicService {
  static const String _mutedKey = 'music_muted';
  static const double _volume = 0.35;

  final AudioPlayer _player = AudioPlayer();
  bool _muted = false;
  bool _mutedLoaded = false;
  String? _currentAsset;
  bool _isPlaying = false;

  AudioPlayersMusicAdapter();

  @override
  bool get isMuted => _muted;

  @override
  Future<void> playLoop(String assetPath) async {
    _currentAsset = assetPath;
    if (!_mutedLoaded) {
      final prefs = await SharedPreferences.getInstance();
      _muted = prefs.getBool(_mutedKey) ?? false;
      _mutedLoaded = true;
    }
    if (_muted || _isPlaying) return;
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(_volume);
      await _player.play(AssetSource(assetPath));
      _isPlaying = true;
    } catch (_) {
      // Asset missing or platform lacking audio — silently skip so
      // the game still runs.
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {
      // Ignore — nothing was playing.
    }
    _isPlaying = false;
  }

  @override
  Future<void> setMuted(bool muted) async {
    _muted = muted;
    _mutedLoaded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_mutedKey, muted);
    if (muted) {
      await stop();
    } else if (_currentAsset != null && !_isPlaying) {
      try {
        await _player.setReleaseMode(ReleaseMode.loop);
        await _player.setVolume(_volume);
        await _player.play(AssetSource(_currentAsset!));
        _isPlaying = true;
      } catch (_) {
        // Ignore.
      }
    }
  }
}
