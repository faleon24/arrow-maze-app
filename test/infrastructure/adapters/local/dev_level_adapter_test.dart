import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_maze_app/infrastructure/adapters/local/dev_level_adapter.dart';

void main() {
  // rootBundle needs the test binding initialized to serve the app's
  // asset manifest during flutter test.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DevLevelAdapter.fetchLevels', () {
    test('should_load_three_levels_from_bundled_fixture_asset', () async {
      final levels = await const DevLevelAdapter().fetchLevels();

      expect(levels.length, 3);
    });

    test('should_parse_multi_cell_arrow_path_in_level_three', () async {
      final levels = await const DevLevelAdapter().fetchLevels();

      final hasMultiCell =
          levels[2].board.arrows.any((a) => a.cells.length >= 3);
      expect(hasMultiCell, isTrue);
    });

    test('should_expose_time_limit_when_fixture_provides_it', () async {
      final levels = await const DevLevelAdapter().fetchLevels();

      for (final level in levels) {
        expect(level.timeLimitMs, isNotNull);
      }
    });
  });
}
