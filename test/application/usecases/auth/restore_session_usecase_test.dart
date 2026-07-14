import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_maze_app/application/usecases/auth/restore_session_usecase.dart';
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
  group('RestoreSessionUseCase', () {
    test('should_return_session_when_stored_and_not_expired', () async {
      // Arrange
      final storage = _FakeTokenStorage()
        ..storedToken = 'jwt-x'
        ..storedExpiresAt = DateTime.utc(2030, 1, 1);
      final useCase = RestoreSessionUseCase(storage);

      // Act
      final session = await useCase(now: DateTime.utc(2025, 1, 1));

      // Assert
      expect(session, isNotNull);
      expect(session!.token, 'jwt-x');
      expect(storage.clearCount, 0);
    });

    test('should_return_null_when_no_token_stored', () async {
      // Arrange
      final storage = _FakeTokenStorage();
      final useCase = RestoreSessionUseCase(storage);

      // Act
      final session = await useCase(now: DateTime.utc(2025, 1, 1));

      // Assert
      expect(session, isNull);
      expect(storage.clearCount, 0);
    });

    test('should_return_null_and_clear_when_token_stored_but_expired',
        () async {
      // Arrange
      final storage = _FakeTokenStorage()
        ..storedToken = 'jwt-old'
        ..storedExpiresAt = DateTime.utc(2020, 1, 1);
      final useCase = RestoreSessionUseCase(storage);

      // Act
      final session = await useCase(now: DateTime.utc(2025, 1, 1));

      // Assert
      expect(session, isNull);
      expect(storage.storedToken, isNull);
      expect(storage.clearCount, 1);
    });

    test('should_return_null_and_clear_when_expiry_missing', () async {
      // Arrange
      final storage = _FakeTokenStorage()..storedToken = 'jwt-orphan';
      final useCase = RestoreSessionUseCase(storage);

      // Act
      final session = await useCase(now: DateTime.utc(2025, 1, 1));

      // Assert
      expect(session, isNull);
      expect(storage.storedToken, isNull);
      expect(storage.clearCount, 1);
    });
  });
}
