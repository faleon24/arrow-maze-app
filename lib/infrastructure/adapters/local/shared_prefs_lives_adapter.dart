import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/models/lives_state.dart';
import '../../../domain/ports/lives_service.dart';

/// SharedPrefsLivesAdapter — persists the current life count locally.
/// The maximum is a compile-time constant (game balance decision);
/// first read seeds current with max so a fresh install can play
/// immediately.
class SharedPrefsLivesAdapter implements ILivesService {
  static const String _livesKey = 'lives_current';
  static const int _maxLives = 5;

  const SharedPrefsLivesAdapter();

  @override
  Future<LivesState> read() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_livesKey) ?? _maxLives;
    return LivesState(current: current, max: _maxLives);
  }

  @override
  Future<bool> tryConsume() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_livesKey) ?? _maxLives;
    if (current <= 0) return false;
    await prefs.setInt(_livesKey, current - 1);
    return true;
  }

  @override
  Future<void> add(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_livesKey) ?? _maxLives;
    final capped = (current + amount).clamp(0, _maxLives);
    await prefs.setInt(_livesKey, capped);
  }
}
