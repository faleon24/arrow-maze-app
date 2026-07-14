import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_maze_app/application/usecases/wallet/award_coins_for_level_usecase.dart';
import 'package:arrow_maze_app/domain/ports/wallet_service.dart';

class _FakeWallet implements IWalletService {
  int balance = 0;
  int creditCount = 0;

  @override
  Future<int> getBalance() async => balance;

  @override
  Future<void> credit(int amount) async {
    balance += amount;
    creditCount++;
  }

  @override
  Future<bool> tryDebit(int amount) async {
    throw UnimplementedError();
  }
}

void main() {
  group('AwardCoinsForLevelUseCase', () {
    test('should_credit_base_plus_bonus_when_awarded_one_star', () async {
      // Arrange
      final wallet = _FakeWallet();
      final useCase = AwardCoinsForLevelUseCase(wallet);

      // Act — 10 base + 5 * 1 star = 15
      final awarded = await useCase(stars: 1);

      // Assert
      expect(awarded, 15);
      expect(wallet.balance, 15);
      expect(wallet.creditCount, 1);
    });

    test('should_credit_base_plus_bonus_when_awarded_three_stars', () async {
      // Arrange
      final wallet = _FakeWallet();
      final useCase = AwardCoinsForLevelUseCase(wallet);

      // Act — 10 base + 5 * 3 stars = 25
      final awarded = await useCase(stars: 3);

      // Assert
      expect(awarded, 25);
      expect(wallet.balance, 25);
    });
  });
}
