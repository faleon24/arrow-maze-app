import '../models/lives_state.dart';

/// ILivesService — abstract contract for the player's global lives
/// balance (separate from GameSession's per-session attempt counter).
///
/// One life is spent per match the player starts and doesn't clear.
/// Lives can be refilled by purchase (see PurchaseLifeUseCase) — a
/// future adapter may also implement time-based regeneration behind
/// the same port.
abstract class ILivesService {
  Future<LivesState> read();

  /// Decrements 1 life atomically. Returns true if a life was
  /// consumed, false if the player had none.
  Future<bool> tryConsume();

  /// Adds [amount] lives, clamped to the maximum.
  Future<void> add(int amount);
}
