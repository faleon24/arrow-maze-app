import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_maze_app/application/usecases/music/toggle_music_usecase.dart';
import 'package:arrow_maze_app/domain/ports/music_service.dart';

class _FakeMusicService implements IMusicService {
  bool _muted = false;
  int setMutedCalls = 0;
  int playCalls = 0;
  int stopCalls = 0;
  int pauseCalls = 0;
  int resumeCalls = 0;

  @override
  bool get isMuted => _muted;

  @override
  Future<void> playLoop(String assetPath) async {
    playCalls++;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
  }

  @override
  Future<void> pause() async {
    pauseCalls++;
  }

  @override
  Future<void> resume() async {
    resumeCalls++;
  }

  @override
  Future<void> setMuted(bool muted) async {
    setMutedCalls++;
    _muted = muted;
  }
}

void main() {
  group('ToggleMusicUseCase', () {
    test('should_flip_from_unmuted_to_muted_and_return_true', () async {
      final service = _FakeMusicService();
      final useCase = ToggleMusicUseCase(service);

      final newMuted = await useCase();

      expect(newMuted, isTrue);
      expect(service.isMuted, isTrue);
      expect(service.setMutedCalls, 1);
    });

    test('should_flip_from_muted_back_to_unmuted_and_return_false',
        () async {
      final service = _FakeMusicService();
      await service.setMuted(true);
      final useCase = ToggleMusicUseCase(service);

      final newMuted = await useCase();

      expect(newMuted, isFalse);
      expect(service.isMuted, isFalse);
    });

    test('should_expose_current_mute_state_via_isMuted_getter', () async {
      final service = _FakeMusicService();
      final useCase = ToggleMusicUseCase(service);

      expect(useCase.isMuted, isFalse);
      await useCase();
      expect(useCase.isMuted, isTrue);
    });
  });
}
