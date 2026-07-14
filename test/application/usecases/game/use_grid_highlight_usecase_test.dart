import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_maze_app/application/usecases/game/use_grid_highlight_usecase.dart';
import 'package:arrow_maze_app/domain/models/board.dart';
import 'package:arrow_maze_app/domain/models/collectible.dart';
import 'package:arrow_maze_app/domain/models/position.dart';
import 'package:arrow_maze_app/domain/models/power_up_items.dart';
import 'package:arrow_maze_app/domain/ports/inventory_service.dart';
import 'package:arrow_maze_app/domain/services/arrow_ray_calculator.dart';

class _FakeInventory implements IInventoryService {
  final Map<String, int> counts;

  _FakeInventory(this.counts);

  @override
  Future<int> getCount(String itemId) async => counts[itemId] ?? 0;

  @override
  Future<void> add(String itemId, int amount) async {
    counts[itemId] = (counts[itemId] ?? 0) + amount;
  }

  @override
  Future<bool> tryConsume(String itemId, int amount) async {
    final current = counts[itemId] ?? 0;
    if (current < amount) return false;
    counts[itemId] = current - amount;
    return true;
  }
}

void main() {
  group('UseGridHighlightUseCase', () {
    test('should_return_null_when_out_of_highlights', () async {
      // Arrange
      final inv = _FakeInventory({PowerUpItems.gridHighlight: 0});
      final useCase = UseGridHighlightUseCase(
        inv,
        const ArrowRayCalculator(),
      );
      final board = Board(
        rows: 1,
        cols: 1,
        arrows: const [],
        walls: <Position>{},
        collectibles: <Position, Collectible>{},
      );

      // Act
      final result = await useCase(board: board, arrowId: 'nonexistent');

      // Assert
      expect(result, isNull);
      expect(inv.counts[PowerUpItems.gridHighlight], 0);
    });

    test('should_return_empty_list_when_arrow_id_unknown_but_stock_available',
        () async {
      // Arrange
      final inv = _FakeInventory({PowerUpItems.gridHighlight: 2});
      final useCase = UseGridHighlightUseCase(
        inv,
        const ArrowRayCalculator(),
      );
      final board = Board(
        rows: 1,
        cols: 1,
        arrows: const [],
        walls: <Position>{},
        collectibles: <Position, Collectible>{},
      );

      // Act
      final result = await useCase(board: board, arrowId: 'missing');

      // Assert — highlight consumed even though the ray is empty; the
      // caller is responsible for validating the arrow id before using
      // a power-up. Documents the contract explicitly.
      expect(result, isEmpty);
      expect(inv.counts[PowerUpItems.gridHighlight], 1);
    });
  });
}
