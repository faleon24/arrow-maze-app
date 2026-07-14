import '../../../domain/models/lives_state.dart';
import '../../../domain/ports/lives_service.dart';

class GetLivesUseCase {
  final ILivesService _lives;

  const GetLivesUseCase(this._lives);

  Future<LivesState> call() => _lives.read();
}
