import '../../../domain/ports/music_service.dart';

/// ToggleMusicUseCase — flips the music mute state and persists it.
/// Returns the new muted value so the caller can update UI in one
/// round-trip.
class ToggleMusicUseCase {
  final IMusicService _music;

  const ToggleMusicUseCase(this._music);

  bool get isMuted => _music.isMuted;

  Future<bool> call() async {
    await _music.setMuted(!_music.isMuted);
    return _music.isMuted;
  }
}
