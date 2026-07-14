import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_maze_app/domain/models/level.dart';

void main() {
  group('Level.unlockThresholdFor', () {
    test('should_return_one_when_difficulty_is_easy', () {
      expect(Level.unlockThresholdFor('EASY'), 1);
    });

    test('should_return_two_when_difficulty_is_medium', () {
      expect(Level.unlockThresholdFor('MEDIUM'), 2);
    });

    test('should_return_three_when_difficulty_is_hard', () {
      expect(Level.unlockThresholdFor('HARD'), 3);
    });

    test('should_normalize_case_before_matching', () {
      expect(Level.unlockThresholdFor('easy'), 1);
      expect(Level.unlockThresholdFor('Medium'), 2);
    });

    test('should_default_to_three_for_unknown_difficulty', () {
      expect(Level.unlockThresholdFor('LEGENDARY'), 3);
      expect(Level.unlockThresholdFor(''), 3);
    });
  });
}
