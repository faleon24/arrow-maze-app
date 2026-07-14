/// IMusicService — abstract contract for looped background music.
abstract class IMusicService {
  Future<void> playLoop(String assetPath);
  Future<void> stop();
  Future<void> pause();
  Future<void> resume();

  /// Load and return the persisted mute preference.
  Future<bool> readMuted();

  Future<void> setMuted(bool muted);

  /// Cached mute state; may be stale until [readMuted] or a first
  /// [playLoop] has been called.
  bool get isMuted;
}
