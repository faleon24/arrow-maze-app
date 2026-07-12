import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_maze_app/domain/models/board_builder.dart';

/// Guards the dev-level fixture against drift. Every board must parse
/// through the same BoardBuilder pipeline production levels use, so a
/// broken fixture surfaces as a red test rather than a runtime crash
/// during play-testing.
void main() {
  group('assets/fixtures/levels_dev.json', () {
    late List<Map<String, dynamic>> levels;

    setUpAll(() {
      final file = File('assets/fixtures/levels_dev.json');
      final content = file.readAsStringSync();
      levels =
          (jsonDecode(content) as List).cast<Map<String, dynamic>>();
    });

    test('should_contain_three_dev_levels', () {
      expect(levels.length, 3);
    });

    test('should_parse_every_board_via_BoardBuilder_without_throwing', () {
      for (final level in levels) {
        // Any FormatException here means the fixture drifted from the
        // v2 board contract — a Format error surfaces the offending
        // piece by name in its message.
        BoardBuilder.fromJson(level['board'] as Map<String, dynamic>);
      }
    });

    test('should_include_a_multi_cell_arrow_path_in_level_three', () {
      final board = BoardBuilder.fromJson(
        levels[2]['board'] as Map<String, dynamic>,
      );
      final hasMultiCell = board.arrows.any((a) => a.cells.length >= 3);
      expect(hasMultiCell, isTrue);
    });
  });
}