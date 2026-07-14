import '../../../domain/models/power_up_items.dart';
import '../../../domain/models/shop_item.dart';
import '../../../domain/ports/inventory_service.dart';
import '../../../domain/ports/lives_service.dart';
import '../../../domain/ports/wallet_service.dart';

/// BuyShopItemResult — outcome of a purchase attempt.
class BuyShopItemResult {
  final bool success;
  final String message;

  const BuyShopItemResult._({required this.success, required this.message});

  static const insufficientCoins = BuyShopItemResult._(
    success: false,
    message: 'Not enough coins',
  );

  static const succeeded = BuyShopItemResult._(
    success: true,
    message: 'Purchase successful',
  );

  static const cosmeticApplied = BuyShopItemResult._(
    success: true,
    message: 'Cosmetic unlocked (visual not shipped yet)',
  );
}

/// BuyShopItemUseCase — atomic purchase: debit wallet, then apply
/// the local effect for known item ids. Composes IWalletService,
/// IInventoryService and ILivesService.
///
/// The mapping from backend UUIDs to local effects is intentionally
/// hardcoded here because it is the seam between the two economies
/// (backend shop catalog + local wallet/inventory/lives). A future
/// revision could push the effect metadata into the ShopItem itself
/// (kind='HINT_REVEAL' with amount=1, etc.), but for MVP the three
/// known items keep it simple.
class BuyShopItemUseCase {
  /// Seeded UUID for the "Extra Life" shop item.
  static const String extraLifeItemId =
      '55555555-5555-4555-8555-555555555555';

  /// Seeded UUID for the "Hint Reveal" shop item.
  static const String hintRevealItemId =
      '66666666-6666-4666-8666-666666666666';

  final IWalletService _wallet;
  final IInventoryService _inventory;
  final ILivesService _lives;

  const BuyShopItemUseCase(this._wallet, this._inventory, this._lives);

  Future<BuyShopItemResult> call({required ShopItem item}) async {
    final debited = await _wallet.tryDebit(item.costCoins);
    if (!debited) return BuyShopItemResult.insufficientCoins;
    return _applyEffect(item);
  }

  Future<BuyShopItemResult> _applyEffect(ShopItem item) async {
    if (item.id == hintRevealItemId) {
      await _inventory.add(PowerUpItems.hint, 1);
      return BuyShopItemResult.succeeded;
    }
    if (item.id == extraLifeItemId) {
      await _lives.add(1);
      return BuyShopItemResult.succeeded;
    }
    // Cosmetic or unknown item: purchase completes but there's
    // nothing local to grant. Surface a friendlier message so the
    // player understands the theme isn't yet visible.
    if (item.kind == 'COSMETIC') {
      return BuyShopItemResult.cosmeticApplied;
    }
    return BuyShopItemResult.succeeded;
  }
}
