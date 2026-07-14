import '../../../domain/ports/wallet_service.dart';

class GetWalletBalanceUseCase {
  final IWalletService _wallet;

  const GetWalletBalanceUseCase(this._wallet);

  Future<int> call() => _wallet.getBalance();
}
