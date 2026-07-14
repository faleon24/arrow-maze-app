import 'package:flutter/services.dart';

import '../../../domain/ports/audio_service.dart';

/// SystemSoundsAudioAdapter — implements IAudioService using Flutter's
/// SystemSound platform channel, which plays the OS's stock click
/// sound. Chosen so the app ships audio without bundling any assets
/// or adding the audioplayers package; a richer adapter with real
/// SFX can drop in later behind the same port.
class SystemSoundsAudioAdapter implements IAudioService {
  const SystemSoundsAudioAdapter();

  @override
  Future<void> playArrowActivated() =>
      SystemSound.play(SystemSoundType.click);

  @override
  Future<void> playArrowBlocked() =>
      SystemSound.play(SystemSoundType.alert);

  @override
  Future<void> playLevelCleared() =>
      SystemSound.play(SystemSoundType.click);
}
