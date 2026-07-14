import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_maze_app/application/usecases/auth/sign_out_usecase.dart';
import 'package:arrow_maze_app/domain/ports/auth_token_storage.dart';

class _FakeTokenStorage implements IAuthTokenStorage {
  String? storedToken;
  DateTime? storedExpiresAt;
  int clearCount = 0;

  @override
  Future<void> saveSession({
    required String token,
    required DateTime expiresAt,
  }) async {
    storedToken = token;
    storedExpiresAt = expiresAt;
  }

  @override
  Future<String?> readToken() async => storedToken;

  @override
  Future<DateTime?> readExpiresAt() async => storedExpiresAt;

  @override
  Future<void> clearSession() async {
    storedToken = null;
    storedExpiresAt = null;
    clearCount++;
  }
}

void main() {
  group('SignOutUseCase', () {
    test('should_clear_persisted_session_when_called', () async {
      // Arrange
      final storage = _FakeTokenStorage()
        ..storedToken = 'jwt-x'
        ..storedExpiresAt = DateTime.utc(2030, 1, 1);
      final useCase = SignOutUseCase(storage);

      // Act
      await useCase();

      // Assert
      expect(storage.storedToken, isNull);
      expect(storage.storedExpiresAt, isNull);
      expect(storage.clearCount, 1);
    });
  });
}
