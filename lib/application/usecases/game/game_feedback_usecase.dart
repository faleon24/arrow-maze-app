import '../../../domain/ports/audio_service.dart';
import '../../../domain/ports/haptics_service.dart';

/// GameFeedbackUseCase — coordinates haptic and audio feedback for
/// gameplay events. Screens call the appropriate method after
/// mutating the GameSession; the use case fires both ports in
/// parallel so neither blocks the other, and neither blocks the UI.
///
/// This is the first application use case that composes two service
/// ports rather than a repository — a natural fit for the pattern
/// because there is genuine coordination logic ("fire tactile + sound
/// together") that would otherwise be duplicated in every screen
/// that reacts to gameplay events.
class GameFeedbackUseCase {
  final IHapticsService _haptics;
  final IAudioService _audio;

  const GameFeedbackUseCase(this._haptics, this._audio);

  Future<void> arrowActivated() async {
    await Future.wait([
      _haptics.lightTap(),
      _audio.playArrowActivated(),
    ]);
  }

  Future<void> arrowBlocked() async {
    await Future.wait([
      _haptics.heavyTap(),
      _audio.playArrowBlocked(),
    ]);
  }

  Future<void> levelCleared() async {
    await Future.wait([
      _haptics.success(),
      _audio.playLevelCleared(),
    ]);
  }

  Future<void> levelFailed() async {
    await Future.wait([
      _haptics.heavyTap(),
      _audio.playArrowBlocked(),
    ]);
  }
}
