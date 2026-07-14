/// IHapticsService — abstract contract for tactile feedback.
///
/// Concrete adapters map these semantic events to platform vibration
/// APIs. Mute state persists across launches so the player's
/// preference survives app restarts.
abstract class IHapticsService {
  Future<void> lightTap();
  Future<void> heavyTap();
  Future<void> success();

  /// Load and return the persisted mute preference.
  Future<bool> readMuted();

  /// Persist and apply the mute preference. Muted adapters no-op on
  /// every tap*/success call.
  Future<void> setMuted(bool muted);

  /// Cached mute state; may be stale until [readMuted] has been
  /// called at least once.
  bool get isMuted;
}
