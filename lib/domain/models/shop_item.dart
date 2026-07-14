/// ShopItem — the domain entity for a purchasable catalog item.
///
/// Fields mirror the backend's ShopItemResponseDto: id (UUID), name,
/// costCoins (price in the player's wallet currency), kind (whitelist
/// string: 'COSMETIC' or 'POWERUP').
class ShopItem {
  final String id;
  final String name;
  final int costCoins;
  final String kind;

  const ShopItem({
    required this.id,
    required this.name,
    required this.costCoins,
    required this.kind,
  });
}
