import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/ports/haptics_service.dart';

/// FlutterHapticsAdapter — implements IHapticsService using Flutter's
/// HapticFeedback platform channel. Respects the OS-level haptics
/// setting AND an in-app mute (persisted via shared_preferences)
/// so the player can silence vibration without touching device
/// settings.
///
/// Stateful (mute flag + prefs cache), registered as singleton.
class FlutterHapticsAdapter implements IHapticsService {
  static const String _mutedKey = 'haptics_muted';

  bool _muted = false;
  bool _mutedLoaded = false;

  FlutterHapticsAdapter();

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
  Future<void> lightTap() async {
    await _ensureMutedLoaded();
    if (_muted) return;
    await HapticFeedback.lightImpact();
  }

  @override
  Future<void> heavyTap() async {
    await _ensureMutedLoaded();
    if (_muted) return;
    await HapticFeedback.heavyImpact();
  }

  @override
  Future<void> success() async {
    await _ensureMutedLoaded();
    if (_muted) return;
    await HapticFeedback.mediumImpact();
  }
}
