import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_maze_app/data/dev_level_source.dart';

void main() {
  // rootBundle needs the test binding initialized to serve the app's
  // asset manifest during flutter test.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DevLevelSource.load', () {
    test('should_load_three_levels_from_bundled_fixture_asset', () async {
      final levels = await DevLevelSource.load();

      expect(levels.length, 3);
    });

    test('should_parse_multi_cell_arrow_path_in_level_three', () async {
      final levels = await DevLevelSource.load();

      final hasMultiCell =
          levels[2].board.arrows.any((a) => a.cells.length >= 3);
      expect(hasMultiCell, isTrue);
    });

    test('should_expose_time_limit_when_fixture_provides_it', () async {
      final levels = await DevLevelSource.load();

      for (final level in levels) {
        expect(level.timeLimitMs, isNotNull);
      }
    });
  });
}