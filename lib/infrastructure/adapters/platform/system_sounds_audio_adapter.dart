import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/ports/audio_service.dart';

/// SystemSoundsAudioAdapter — plays the OS's stock click via
/// Flutter's SystemSound platform channel. No bundled assets, no
/// audioplayers dep. A richer adapter with real SFX can drop in
/// behind IAudioService later.
///
/// Stateful (holds mute flag + prefs cache), so DI registers this
/// as a singleton.
class SystemSoundsAudioAdapter implements IAudioService {
  static const String _mutedKey = 'audio_muted';

  bool _muted = false;
  bool _mutedLoaded = false;

  SystemSoundsAudioAdapter();

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
  Future<void> setMuted(bool muted) async {
    _muted = muted;
    _mutedLoaded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_mutedKey, muted);
  }

  @override
  Future<void> playArrowActivated() async {
    await _ensureMutedLoaded();
    if (_muted) return;
    await SystemSound.play(SystemSoundType.click);
  }

  @override
  Future<void> playArrowBlocked() async {
    await _ensureMutedLoaded();
    if (_muted) return;
    await SystemSound.play(SystemSoundType.alert);
  }

  @override
  Future<void> playLevelCleared() async {
    await _ensureMutedLoaded();
    if (_muted) return;
    await SystemSound.play(SystemSoundType.click);
  }
}
