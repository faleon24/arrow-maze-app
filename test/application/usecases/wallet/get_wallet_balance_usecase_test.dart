import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_maze_app/application/usecases/wallet/get_wallet_balance_usecase.dart';
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

void main() {
  group('GetWalletBalanceUseCase', () {
    test('should_return_wallet_balance_when_called', () async {
      final wallet = _FakeWallet()..balance = 250;
      final useCase = GetWalletBalanceUseCase(wallet);

      final result = await useCase();

      expect(result, 250);
    });
  });
}
