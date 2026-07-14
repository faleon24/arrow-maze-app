/// IMusicService — abstract contract for looped background music.
///
/// Concrete adapters manage the audio player instance and mute
/// persistence. Application-level use cases fire these methods; the
/// domain and application layers stay ignorant of the audio backend
/// (audioplayers, just_audio, etc.).
abstract class IMusicService {
  /// Start looping [assetPath] (relative to the bundled `assets/`).
  /// No-op if music is muted; silently no-op if the asset is missing
  /// so the game still runs.
  Future<void> playLoop(String assetPath);

  Future<void> stop();

  /// Pause playback without releasing the source. Cheap enough to
  /// call whenever the game pauses; [resume] picks up from the same
  /// position.
  Future<void> pause();

  /// Resume playback if [pause] was called. No-op if music is muted
  /// or nothing was ever started.
  Future<void> resume();

  /// Persist and apply the mute preference across app launches.
  Future<void> setMuted(bool muted);

  /// Current mute state (last applied via [setMuted] or restored from
  /// persistence at first [playLoop]).
  bool get isMuted;
}
