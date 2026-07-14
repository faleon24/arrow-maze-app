import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_maze_app/application/usecases/auth/register_usecase.dart';
import 'package:arrow_maze_app/domain/models/user_session.dart';
import 'package:arrow_maze_app/domain/ports/auth_repository.dart';
import 'package:arrow_maze_app/domain/ports/auth_token_storage.dart';

class _FakeAuthRepository implements IAuthRepository {
  UserSession? nextResult;
  Object? nextError;
  String? capturedEmail;
  String? capturedPassword;
  String? capturedDisplayName;

  @override
  Future<UserSession> login({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<UserSession> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    capturedEmail = email;
    capturedPassword = password;
    capturedDisplayName = displayName;
    if (nextError != null) throw nextError!;
    return nextResult!;
  }
}

class _FakeTokenStorage implements IAuthTokenStorage {
  String? storedToken;
  DateTime? storedExpiresAt;
  int saveCount = 0;

  @override
  Future<void> saveSession({
    required String token,
    required DateTime expiresAt,
  }) async {
    storedToken = token;
    storedExpiresAt = expiresAt;
    saveCount++;
  }

  @override
  Future<String?> readToken() async => storedToken;

  @override
  Future<DateTime?> readExpiresAt() async => storedExpiresAt;

  @override
  Future<void> clearSession() async {
    storedToken = null;
    storedExpiresAt = null;
  }
}

void main() {
  group('RegisterUseCase', () {
    test('should_persist_session_when_repository_accepts_registration',
        () async {
      // Arrange
      final expiresAt = DateTime.utc(2030, 1, 1);
      final repo = _FakeAuthRepository()
        ..nextResult = UserSession(token: 'jwt-new', expiresAt: expiresAt);
      final storage = _FakeTokenStorage();
      final useCase = RegisterUseCase(repo, storage);

      // Act
      final session = await useCase(
        email: 'new@b.com',
        password: 'pw',
        displayName: 'New User',
      );

      // Assert
      expect(session.token, 'jwt-new');
      expect(storage.storedToken, 'jwt-new');
      expect(storage.saveCount, 1);
      expect(repo.capturedEmail, 'new@b.com');
      expect(repo.capturedDisplayName, 'New User');
    });

    test('should_not_persist_when_repository_rejects_registration', () async {
      // Arrange
      final repo = _FakeAuthRepository()
        ..nextError = Exception('email in use');
      final storage = _FakeTokenStorage();
      final useCase = RegisterUseCase(repo, storage);

      // Act + Assert
      await expectLater(
        useCase(
          email: 'dup@b.com',
          password: 'pw',
          displayName: 'Dup',
        ),
        throwsException,
      );
      expect(storage.saveCount, 0);
    });
  });
}
