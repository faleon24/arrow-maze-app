import '../../../domain/models/game_observer.dart';
import '../../../domain/ports/audio_service.dart';
import '../../../domain/ports/haptics_service.dart';

/// GameFeedbackUseCase — Observer over GameSession events (Observer
/// pattern, GoF). Composes the audio and haptics ports.
///
/// GameSession fires onArrowActivated / onArrowBlocked / onLevelCleared
/// / onLevelFailed as tap outcomes resolve; this class subscribes via
/// GameSession.addObserver and fans out each event to both feedback
/// channels in parallel. Screens no longer need to call the feedback
/// methods directly — registering the observer once at session start
/// is enough.
class GameFeedbackUseCase extends GameObserver {
  final IHapticsService _haptics;
  final IAudioService _audio;

  GameFeedbackUseCase(this._haptics, this._audio);

  @override
  Future<void> onArrowActivated() async {
    await Future.wait([
      _haptics.lightTap(),
      _audio.playArrowActivated(),
    ]);
  }

  @override
  Future<void> onArrowBlocked() async {
    await Future.wait([
      _haptics.heavyTap(),
      _audio.playArrowBlocked(),
    ]);
  }

  @override
  Future<void> onLevelCleared() async {
    await Future.wait([
      _haptics.success(),
      _audio.playLevelCleared(),
    ]);
  }

  @override
  Future<void> onLevelFailed() async {
    await Future.wait([
      _haptics.heavyTap(),
      _audio.playArrowBlocked(),
    ]);
  }
}
