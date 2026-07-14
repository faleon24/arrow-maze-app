import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_maze_app/application/usecases/lives/consume_life_usecase.dart';
import 'package:arrow_maze_app/domain/models/lives_state.dart';
import 'package:arrow_maze_app/domain/ports/lives_service.dart';

class _FakeLives implements ILivesService {
  LivesState state = const LivesState(current: 3, max: 5);

  @override
  Future<LivesState> read() async => state;

  @override
  Future<bool> tryConsume() async {
    if (state.current <= 0) return false;
    state = LivesState(current: state.current - 1, max: state.max);
    return true;
  }

  @override
  Future<void> add(int amount) async {
    final capped = (state.current + amount).clamp(0, state.max);
    state = LivesState(current: capped, max: state.max);
  }
}

void main() {
  group('ConsumeLifeUseCase', () {
    test('should_return_true_and_decrement_when_lives_available',
        () async {
      final port = _FakeLives()..state = const LivesState(current: 3, max: 5);
      final useCase = ConsumeLifeUseCase(port);

      final consumed = await useCase();

      expect(consumed, isTrue);
      expect(port.state.current, 2);
    });

    test('should_return_false_when_no_lives_left', () async {
      final port = _FakeLives()..state = const LivesState(current: 0, max: 5);
      final useCase = ConsumeLifeUseCase(port);

      final consumed = await useCase();

      expect(consumed, isFalse);
      expect(port.state.current, 0);
    });
  });
}
