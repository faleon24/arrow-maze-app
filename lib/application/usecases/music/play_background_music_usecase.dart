import '../../../domain/ports/music_service.dart';

/// PlayBackgroundMusicUseCase — kicks off the app's background music
/// loop. Called once from main() after setupDI, fire-and-forget.
class PlayBackgroundMusicUseCase {
  /// Asset path (relative to the bundled `assets/` root, per the
  /// audioplayers convention).
  static const String assetPath = 'audio/background.mp3';

  final IMusicService _music;

  const PlayBackgroundMusicUseCase(this._music);

  Future<void> call() => _music.playLoop(assetPath);
}
