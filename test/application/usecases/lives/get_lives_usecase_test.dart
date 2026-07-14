import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_maze_app/application/usecases/lives/get_lives_usecase.dart';
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
  group('GetLivesUseCase', () {
    test('should_return_current_lives_state_when_called', () async {
      final port = _FakeLives()..state = const LivesState(current: 2, max: 5);
      final useCase = GetLivesUseCase(port);

      final result = await useCase();

      expect(result.current, 2);
      expect(result.max, 5);
    });
  });
}
