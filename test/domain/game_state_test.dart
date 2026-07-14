import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_maze_app/domain/models/game_state.dart';

void main() {
  group('GameState hierarchy', () {
    test('PlayingState allows taps and is non-terminal', () {
      const state = PlayingState();
      expect(state.allowsTaps, isTrue);
      expect(state.isTerminal, isFalse);
      expect(state.label, 'PLAYING');
    });

    test('PausedState blocks taps and is non-terminal', () {
      const state = PausedState();
      expect(state.allowsTaps, isFalse);
      expect(state.isTerminal, isFalse);
      expect(state.label, 'PAUSED');
    });

    test('ClearedState blocks taps and is terminal', () {
      const state = ClearedState();
      expect(state.allowsTaps, isFalse);
      expect(state.isTerminal, isTrue);
      expect(state.label, 'CLEARED');
    });

    test('FailedState blocks taps and is terminal', () {
      const state = FailedState();
      expect(state.allowsTaps, isFalse);
      expect(state.isTerminal, isTrue);
      expect(state.label, 'FAILED');
    });
  });
}
