import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_maze_app/application/usecases/lives/purchase_life_usecase.dart';
import 'package:arrow_maze_app/domain/models/lives_state.dart';
import 'package:arrow_maze_app/domain/ports/lives_service.dart';
import 'package:arrow_maze_app/domain/ports/wallet_service.dart';

class _FakeWallet implements IWalletService {
  int balance = 0;

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

void main() {
  group('PurchaseLifeUseCase', () {
    test('should_debit_and_add_life_when_below_max_and_wallet_has_coins',
        () async {
      final wallet = _FakeWallet()..balance = 50;
      final lives = _FakeLives()
        ..state = const LivesState(current: 2, max: 5);
      final useCase = PurchaseLifeUseCase(wallet, lives);

      final result = await useCase();

      expect(result, isTrue);
      expect(wallet.balance, 30);
      expect(lives.state.current, 3);
    });

    test('should_return_false_when_at_max_lives', () async {
      final wallet = _FakeWallet()..balance = 100;
      final lives = _FakeLives()
        ..state = const LivesState(current: 5, max: 5);
      final useCase = PurchaseLifeUseCase(wallet, lives);

      final result = await useCase();

      expect(result, isFalse);
      expect(wallet.balance, 100);
      expect(lives.state.current, 5);
    });

    test('should_return_false_when_wallet_insufficient', () async {
      final wallet = _FakeWallet()..balance = 5;
      final lives = _FakeLives()
        ..state = const LivesState(current: 2, max: 5);
      final useCase = PurchaseLifeUseCase(wallet, lives);

      final result = await useCase();

      expect(result, isFalse);
      expect(wallet.balance, 5);
      expect(lives.state.current, 2);
    });
  });
}
