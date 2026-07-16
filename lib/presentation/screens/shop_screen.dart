import 'package:flutter/material.dart';
import '../../application/usecases/shop/buy_shop_item_usecase.dart';
import '../../application/usecases/shop/list_shop_items_usecase.dart';
import '../../application/usecases/wallet/get_wallet_balance_usecase.dart';
import '../../core/di/service_locator.dart';
import '../../domain/models/shop_item.dart';
import '../../l10n/app_localizations.dart';

/// ShopScreen — browse the backend shop catalog and buy items with
/// the local wallet balance. Purchase applies its effect locally
/// (see BuyShopItemUseCase); the backend records the purchase for
/// audit.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});
  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final ListShopItemsUseCase _listItems = getIt<ListShopItemsUseCase>();
  final BuyShopItemUseCase _buyItem = getIt<BuyShopItemUseCase>();
  final GetWalletBalanceUseCase _getBalance =
      getIt<GetWalletBalanceUseCase>();
  late Future<List<ShopItem>> _itemsFuture;
  int _coins = 0;
  bool _purchasing = false;

  @override
  void initState() {
    super.initState();
    _itemsFuture = _listItems();
    _refreshBalance();
  }

  Future<void> _refreshBalance() async {
    final balance = await _getBalance();
    if (!mounted) return;
    setState(() => _coins = balance);
  }

  Future<void> _confirmAndBuy(ShopItem item) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.buyItemTitle(item.name)),
        content: Text(l10n.buyItemBody(item.costCoins)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(l10n.buy),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _purchasing = true);
    final result = await _buyItem(item: item);
    if (!mounted) return;
    setState(() => _purchasing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (result.success) await _refreshBalance();
  }

  IconData _iconFor(ShopItem item) {
    if (item.id == BuyShopItemUseCase.hintRevealItemId) {
      return Icons.lightbulb_outline;
    }
    if (item.id == BuyShopItemUseCase.extraLifeItemId) {
      return Icons.favorite;
    }
    if (item.kind == 'COSMETIC') return Icons.palette_outlined;
    return Icons.shopping_bag_outlined;
  }

  Color _iconColorFor(ShopItem item) {
    if (item.id == BuyShopItemUseCase.hintRevealItemId) return Colors.amber;
    if (item.id == BuyShopItemUseCase.extraLifeItemId) return Colors.redAccent;
    if (item.kind == 'COSMETIC') return Colors.pinkAccent;
    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.shop),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  '$_coins',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<ShopItem>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.errorLoadingShop(snapshot.error!)),
              ),
            );
          }
          final items = snapshot.data ?? <ShopItem>[];
          if (items.isEmpty) {
            return Center(child: Text(l10n.shopEmpty));
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final item = items[i];
              final canAfford = _coins >= item.costCoins;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _iconColorFor(item).withValues(alpha: 0.2),
                  child: Icon(_iconFor(item), color: _iconColorFor(item)),
                ),
                title: Text(item.name),
                subtitle: Text(item.kind),
                trailing: FilledButton.tonalIcon(
                  onPressed: canAfford && !_purchasing
                      ? () => _confirmAndBuy(item)
                      : null,
                  icon: const Icon(Icons.monetization_on, size: 18),
                  label: Text('${item.costCoins}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
