/// IAudioService — abstract contract for sound feedback.
///
/// Concrete adapters play a short sound for each semantic gameplay
/// event. Mute state persists across launches so the player's
/// preference survives app restarts.
abstract class IAudioService {
  Future<void> playArrowActivated();
  Future<void> playArrowBlocked();
  Future<void> playLevelCleared();

  /// Load and return the persisted mute preference. Callers that
  /// render UI (e.g., a settings screen) should call this so the
  /// initial state matches storage.
  Future<bool> readMuted();

  /// Persist and apply the mute preference. Muted adapters no-op on
  /// every play* call.
  Future<void> setMuted(bool muted);

  /// Cached mute state; may be stale until [readMuted] has been
  /// called at least once.
  bool get isMuted;
}
