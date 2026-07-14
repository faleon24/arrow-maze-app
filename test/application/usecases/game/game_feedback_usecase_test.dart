import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_maze_app/application/usecases/game/game_feedback_usecase.dart';
import 'package:arrow_maze_app/domain/ports/audio_service.dart';
import 'package:arrow_maze_app/domain/ports/haptics_service.dart';

class _FakeHaptics implements IHapticsService {
  int lightTapCount = 0;
  int heavyTapCount = 0;
  int successCount = 0;
  bool _muted = false;

  @override
  bool get isMuted => _muted;
  @override
  Future<bool> readMuted() async => _muted;
  @override
  Future<void> setMuted(bool muted) async {
    _muted = muted;
  }

  @override
  Future<void> lightTap() async => lightTapCount++;

  @override
  Future<void> heavyTap() async => heavyTapCount++;

  @override
  Future<void> success() async => successCount++;
}

class _FakeAudio implements IAudioService {
  int activatedCount = 0;
  int blockedCount = 0;
  int clearedCount = 0;
  bool _muted = false;

  @override
  bool get isMuted => _muted;
  @override
  Future<bool> readMuted() async => _muted;
  @override
  Future<void> setMuted(bool muted) async {
    _muted = muted;
  }

  @override
  Future<void> playArrowActivated() async => activatedCount++;

  @override
  Future<void> playArrowBlocked() async => blockedCount++;

  @override
  Future<void> playLevelCleared() async => clearedCount++;
}

void main() {
  group('GameFeedbackUseCase', () {
    test('should_fire_light_haptic_and_activated_sound_on_arrow_activated',
        () async {
      final haptics = _FakeHaptics();
      final audio = _FakeAudio();
      final useCase = GameFeedbackUseCase(haptics, audio);

      await useCase.arrowActivated();

      expect(haptics.lightTapCount, 1);
      expect(audio.activatedCount, 1);
      expect(haptics.heavyTapCount, 0);
      expect(audio.blockedCount, 0);
    });

    test('should_fire_heavy_haptic_and_blocked_sound_on_arrow_blocked',
        () async {
      final haptics = _FakeHaptics();
      final audio = _FakeAudio();
      final useCase = GameFeedbackUseCase(haptics, audio);

      await useCase.arrowBlocked();

      expect(haptics.heavyTapCount, 1);
      expect(audio.blockedCount, 1);
      expect(haptics.lightTapCount, 0);
    });

    test('should_fire_success_haptic_and_cleared_sound_on_level_cleared',
        () async {
      final haptics = _FakeHaptics();
      final audio = _FakeAudio();
      final useCase = GameFeedbackUseCase(haptics, audio);

      await useCase.levelCleared();

      expect(haptics.successCount, 1);
      expect(audio.clearedCount, 1);
    });

    test('should_fire_heavy_haptic_and_blocked_sound_on_level_failed',
        () async {
      final haptics = _FakeHaptics();
      final audio = _FakeAudio();
      final useCase = GameFeedbackUseCase(haptics, audio);

      await useCase.levelFailed();

      expect(haptics.heavyTapCount, 1);
      expect(audio.blockedCount, 1);
    });
  });
}
