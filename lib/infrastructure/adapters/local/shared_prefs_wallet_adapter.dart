import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/ports/wallet_service.dart';

/// SharedPrefsWalletAdapter — persists the coin balance locally via
/// shared_preferences. First read seeds the balance with
/// [_defaultBalance] so a fresh install has something to spend.
class SharedPrefsWalletAdapter implements IWalletService {
  static const String _balanceKey = 'wallet_balance';
  static const int _defaultBalance = 100;

  const SharedPrefsWalletAdapter();

  @override
  Future<int> getBalance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_balanceKey) ?? _defaultBalance;
  }

  @override
  Future<void> credit(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_balanceKey) ?? _defaultBalance;
    await prefs.setInt(_balanceKey, current + amount);
  }

  @override
  Future<bool> tryDebit(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_balanceKey) ?? _defaultBalance;
    if (current < amount) return false;
    await prefs.setInt(_balanceKey, current - amount);
    return true;
  }
}
