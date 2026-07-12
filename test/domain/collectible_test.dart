import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_maze_app/domain/models/collectible.dart';
import 'package:arrow_maze_app/domain/models/position.dart';

void main() {
  group('Collectible', () {
    test('should_accept_star_kind_when_constructed', () {
      final c = Collectible(position: Position(2, 3), kind: 'STAR');

      expect(c.position, Position(2, 3));
      expect(c.kind, 'STAR');
    });

    test('should_throw_format_exception_when_kind_is_unknown', () {
      expect(
        () => Collectible(position: Position(0, 0), kind: 'COIN'),
        throwsA(isA<FormatException>()),
      );
    });

    test('should_be_equal_when_position_and_kind_match', () {
      final a = Collectible(position: Position(1, 1), kind: 'STAR');
      final b = Collectible(position: Position(1, 1), kind: 'STAR');

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}