/// IWalletService — abstract contract for the player's coin balance.
///
/// Local persistence (SharedPreferences) is the default binding today.
/// A server-backed adapter can drop in behind the same port to sync
/// balances across devices without changing any consumer.
abstract class IWalletService {
  Future<int> getBalance();

  Future<void> credit(int amount);

  /// Debits [amount] atomically. Returns true if the balance was
  /// sufficient (and the debit happened), false otherwise.
  Future<bool> tryDebit(int amount);
}
