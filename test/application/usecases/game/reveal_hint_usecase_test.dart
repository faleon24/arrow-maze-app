import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_maze_app/application/usecases/game/reveal_hint_usecase.dart';
import 'package:arrow_maze_app/domain/models/power_up_items.dart';
import 'package:arrow_maze_app/domain/ports/inventory_service.dart';

class _FakeInventory implements IInventoryService {
  final Map<String, int> counts;
  int consumeCount = 0;

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
    consumeCount++;
    return true;
  }
}

void main() {
  group('RevealHintUseCase', () {
    test('should_return_null_when_no_activatable_arrows', () async {
      // Arrange
      final inv = _FakeInventory({PowerUpItems.hint: 5});
      final useCase = RevealHintUseCase(inv);

      // Act
      final result = await useCase(activatableArrowIds: const []);

      // Assert
      expect(result, isNull);
      expect(inv.consumeCount, 0);
      expect(inv.counts[PowerUpItems.hint], 5);
    });

    test('should_return_null_when_out_of_hints', () async {
      // Arrange
      final inv = _FakeInventory({PowerUpItems.hint: 0});
      final useCase = RevealHintUseCase(inv);

      // Act
      final result = await useCase(
        activatableArrowIds: const ['a', 'b'],
      );

      // Assert
      expect(result, isNull);
      expect(inv.consumeCount, 0);
    });

    test('should_return_arrow_id_from_activatable_and_consume_one_hint',
        () async {
      // Arrange
      final inv = _FakeInventory({PowerUpItems.hint: 3});
      final useCase = RevealHintUseCase(inv);

      // Act — Random(42) makes the pick deterministic
      final result = await useCase(
        activatableArrowIds: const ['a', 'b', 'c'],
        rng: Random(42),
      );

      // Assert
      expect(result, isNotNull);
      expect(const ['a', 'b', 'c'], contains(result));
      expect(inv.counts[PowerUpItems.hint], 2);
      expect(inv.consumeCount, 1);
    });
  });
}
