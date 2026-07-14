import '../models/shop_item.dart';

/// IShopRepository — the domain-facing contract for the shop catalog.
///
/// Read-only from the app's perspective — the backend owns the
/// authoritative list of purchasable items. Actual purchases (debit
/// wallet, grant local effect) happen through BuyShopItemUseCase
/// which composes this port with IWalletService, IInventoryService,
/// and ILivesService.
abstract class IShopRepository {
  Future<List<ShopItem>> fetchItems();
}
