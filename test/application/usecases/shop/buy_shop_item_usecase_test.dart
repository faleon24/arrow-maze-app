import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_maze_app/application/usecases/shop/buy_shop_item_usecase.dart';
import 'package:arrow_maze_app/domain/models/lives_state.dart';
import 'package:arrow_maze_app/domain/models/power_up_items.dart';
import 'package:arrow_maze_app/domain/models/shop_item.dart';
import 'package:arrow_maze_app/domain/ports/inventory_service.dart';
import 'package:arrow_maze_app/domain/ports/lives_service.dart';
import 'package:arrow_maze_app/domain/ports/wallet_service.dart';

class _FakeWallet implements IWalletService {
  int balance = 100;
  @override
  Future<int> getBalance() async => balance;
  @override
  Future<void> credit(int amount) async {
    balance += amount;
  }
  @override
  Future<bool> tryDebit(int amount) async {
    if (balance < amount) return false;
    balance -= amount;
    return true;
  }
}

class _FakeInventory implements IInventoryService {
  final Map<String, int> counts = {};
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

class _FakeLives implements ILivesService {
  LivesState state = const LivesState(current: 3, max: 5);
  @override
  Future<LivesState> read() async => state;
  @override
  Future<bool> tryConsume() async {
    if (state.current <= 0) return false;
    state = LivesState(current: state.current - 1, max: state.max);
    return true;
  }
  @override
  Future<void> add(int amount) async {
    final capped = (state.current + amount).clamp(0, state.max);
    state = LivesState(current: capped, max: state.max);
  }
}

ShopItem _hintItem() => const ShopItem(
      id: BuyShopItemUseCase.hintRevealItemId,
      name: 'Hint Reveal',
      costCoins: 20,
      kind: 'POWERUP',
    );

ShopItem _lifeItem() => const ShopItem(
      id: BuyShopItemUseCase.extraLifeItemId,
      name: 'Extra Life',
      costCoins: 50,
      kind: 'POWERUP',
    );

ShopItem _cosmeticItem() => const ShopItem(
      id: '44444444-4444-4444-8444-444444444444',
      name: 'Neon Pink Theme',
      costCoins: 100,
      kind: 'COSMETIC',
    );

void main() {
  group('BuyShopItemUseCase', () {
    test('should_debit_wallet_and_credit_inventory_when_buying_hint',
        () async {
      final wallet = _FakeWallet()..balance = 50;
      final inv = _FakeInventory();
      final lives = _FakeLives();
      final useCase = BuyShopItemUseCase(wallet, inv, lives);

      final result = await useCase(item: _hintItem());

      expect(result.success, isTrue);
      expect(wallet.balance, 30);
      expect(inv.counts[PowerUpItems.hint], 1);
    });

    test('should_debit_wallet_and_add_life_when_buying_extra_life', () async {
      final wallet = _FakeWallet()..balance = 60;
      final inv = _FakeInventory();
      final lives = _FakeLives()
        ..state = const LivesState(current: 2, max: 5);
      final useCase = BuyShopItemUseCase(wallet, inv, lives);

      final result = await useCase(item: _lifeItem());

      expect(result.success, isTrue);
      expect(wallet.balance, 10);
      expect(lives.state.current, 3);
    });

    test('should_debit_wallet_but_grant_no_effect_when_buying_cosmetic',
        () async {
      final wallet = _FakeWallet()..balance = 150;
      final inv = _FakeInventory();
      final lives = _FakeLives();
      final useCase = BuyShopItemUseCase(wallet, inv, lives);

      final result = await useCase(item: _cosmeticItem());

      expect(result.success, isTrue);
      expect(result.message, contains('Cosmetic'));
      expect(wallet.balance, 50);
      expect(inv.counts, isEmpty);
      expect(lives.state.current, 3);
    });

    test('should_return_insufficient_when_wallet_lacks_coins', () async {
      final wallet = _FakeWallet()..balance = 5;
      final inv = _FakeInventory();
      final lives = _FakeLives();
      final useCase = BuyShopItemUseCase(wallet, inv, lives);

      final result = await useCase(item: _hintItem());

      expect(result.success, isFalse);
      expect(result.message, contains('Not enough coins'));
      expect(wallet.balance, 5);
      expect(inv.counts, isEmpty);
    });
  });
}
