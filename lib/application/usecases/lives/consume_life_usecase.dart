import '../../../domain/ports/lives_service.dart';

/// ConsumeLifeUseCase — spends one life. Called by the game screen
/// when a match ends without a clear (failure or player leaves mid-
/// match). Returns true if a life was actually consumed.
class ConsumeLifeUseCase {
  final ILivesService _lives;

  const ConsumeLifeUseCase(this._lives);

  Future<bool> call() => _lives.tryConsume();
}
