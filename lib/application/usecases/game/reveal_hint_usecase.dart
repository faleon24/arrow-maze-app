import 'dart:math';

import '../../../domain/models/power_up_items.dart';
import '../../../domain/ports/inventory_service.dart';

/// RevealHintUseCase — picks one currently activatable arrow at random
/// and consumes a hint from the player's inventory.
///
/// The caller (game screen) computes the activatable ids from its
/// GameSession and passes them in; keeping the pick out of the domain
/// keeps this use case trivially testable and stateless.
///
/// Returns the chosen arrow id, or null if there are no activatable
/// arrows or the player is out of hints (in which case no consumption
/// happens).
class RevealHintUseCase {
  final IInventoryService _inventory;

  const RevealHintUseCase(this._inventory);

  Future<String?> call({
    required List<String> activatableArrowIds,
    Random? rng,
  }) async {
    if (activatableArrowIds.isEmpty) return null;
    final consumed = await _inventory.tryConsume(PowerUpItems.hint, 1);
    if (!consumed) return null;
    final r = rng ?? Random();
    return activatableArrowIds[r.nextInt(activatableArrowIds.length)];
  }
}
