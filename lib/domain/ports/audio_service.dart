/// IAudioService — abstract contract for sound feedback.
///
/// Concrete adapters play a short sound for each semantic gameplay
/// event. The default binding today uses Flutter's SystemSound (a
/// short click), which requires no bundled assets. A richer adapter
/// backed by mp3/wav SFX can drop in behind the same port without
/// touching any consumer.
abstract class IAudioService {
  Future<void> playArrowActivated();
  Future<void> playArrowBlocked();
  Future<void> playLevelCleared();
}
