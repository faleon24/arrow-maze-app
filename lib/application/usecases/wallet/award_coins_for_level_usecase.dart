import '../../../domain/ports/wallet_service.dart';

/// AwardCoinsForLevelUseCase — credits the wallet after a cleared
/// level. Base reward plus a per-star bonus. Formula intentionally
/// simple; can be tuned later without touching consumers.
class AwardCoinsForLevelUseCase {
  static const int _baseReward = 10;
  static const int _perStarBonus = 5;

  final IWalletService _wallet;

  const AwardCoinsForLevelUseCase(this._wallet);

  Future<int> call({required int stars}) async {
    final amount = _baseReward + (_perStarBonus * stars);
    await _wallet.credit(amount);
    return amount;
  }
}
