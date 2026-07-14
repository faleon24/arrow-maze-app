import '../../../domain/models/board.dart';
import '../../../domain/models/position.dart';
import '../../../domain/models/power_up_items.dart';
import '../../../domain/ports/inventory_service.dart';
import '../../../domain/services/arrow_ray_calculator.dart';

/// UseGridHighlightUseCase — consumes a grid-highlight power-up and
/// returns the cells the arrow's ray would traverse. Returns null if
/// the player is out of highlights (no consumption in that case).
class UseGridHighlightUseCase {
  final IInventoryService _inventory;
  final ArrowRayCalculator _calculator;

  const UseGridHighlightUseCase(this._inventory, this._calculator);

  Future<List<Position>?> call({
    required Board board,
    required String arrowId,
  }) async {
    final consumed = await _inventory.tryConsume(
      PowerUpItems.gridHighlight,
      1,
    );
    if (!consumed) return null;
    return _calculator.rayCells(board, arrowId);
  }
}
