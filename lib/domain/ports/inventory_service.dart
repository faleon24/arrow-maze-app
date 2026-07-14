/// IInventoryService — abstract contract for the player's owned
/// power-up items (hints, grid highlights, etc.).
///
/// Item ids are whitelist strings from [PowerUpItems]. Callers should
/// never pass a raw literal.
abstract class IInventoryService {
  Future<int> getCount(String itemId);

  Future<void> add(String itemId, int amount);

  /// Consumes [amount] of [itemId] atomically. Returns true if the
  /// inventory had enough (and the consumption happened), false
  /// otherwise.
  Future<bool> tryConsume(String itemId, int amount);
}
