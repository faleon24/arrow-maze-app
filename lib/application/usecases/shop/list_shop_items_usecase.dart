import '../../../domain/models/shop_item.dart';
import '../../../domain/ports/shop_repository.dart';

class ListShopItemsUseCase {
  final IShopRepository _shopRepo;

  const ListShopItemsUseCase(this._shopRepo);

  Future<List<ShopItem>> call() => _shopRepo.fetchItems();
}
