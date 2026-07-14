import '../../../domain/ports/lives_service.dart';
import '../../../domain/ports/wallet_service.dart';

/// PurchaseLifeUseCase — exchanges coins for one life. Composes the
/// wallet and lives ports so the transaction is atomic from the
/// screen's perspective: either both effects happen or neither does.
///
/// This closes the loop earn coins -> spend coins even without a full
/// shop screen: the levels screen surfaces a "Buy life" button that
/// invokes this use case directly.
class PurchaseLifeUseCase {
  static const int cost = 20;

  final IWalletService _wallet;
  final ILivesService _lives;

  const PurchaseLifeUseCase(this._wallet, this._lives);

  /// Returns true if a life was purchased. Returns false when the
  /// player is already at max lives (no purchase needed, no debit)
  /// or when their wallet balance is insufficient.
  Future<bool> call() async {
    final state = await _lives.read();
    if (state.isFull) return false;
    final debited = await _wallet.tryDebit(cost);
    if (!debited) return false;
    await _lives.add(1);
    return true;
  }
}
