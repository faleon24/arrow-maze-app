import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/ports/music_service.dart';

/// AudioPlayersMusicAdapter — implements IMusicService using the
/// audioplayers package. Loops a bundled asset at a low volume, and
/// persists the mute preference across app launches via
/// shared_preferences.
///
/// Stateful (AudioPlayer + current asset + mute flag), singleton in DI.
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

  Future<void> _ensureMutedLoaded() async {
    if (_mutedLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    _muted = prefs.getBool(_mutedKey) ?? false;
    _mutedLoaded = true;
  }

  @override
  Future<bool> readMuted() async {
    await _ensureMutedLoaded();
    return _muted;
  }

  @override
  Future<void> playLoop(String assetPath) async {
    _currentAsset = assetPath;
    await _ensureMutedLoaded();
    if (_muted || _isPlaying) return;
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(_volume);
      await _player.play(AssetSource(assetPath));
      _isPlaying = true;
    } catch (_) {}
  }

  @override
  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
    _isPlaying = false;
  }

  @override
  Future<void> pause() async {
    if (!_isPlaying) return;
    try {
      await _player.pause();
    } catch (_) {}
  }

  @override
  Future<void> resume() async {
    if (_muted || !_isPlaying) return;
    try {
      await _player.resume();
    } catch (_) {}
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
      } catch (_) {}
    }
  }
}
