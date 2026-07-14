import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_maze_app/application/usecases/auth/sign_in_usecase.dart';
import 'package:arrow_maze_app/domain/models/user_session.dart';
import 'package:arrow_maze_app/domain/ports/auth_repository.dart';
import 'package:arrow_maze_app/domain/ports/auth_token_storage.dart';

class _FakeAuthRepository implements IAuthRepository {
  UserSession? nextResult;
  Object? nextError;
  String? capturedEmail;
  String? capturedPassword;

  @override
  Future<UserSession> login({
    required String email,
    required String password,
  }) async {
    capturedEmail = email;
    capturedPassword = password;
    if (nextError != null) throw nextError!;
    return nextResult!;
  }

  @override
  Future<UserSession> register({
    required String email,
    required String password,
    required String displayName,
  }) {
    throw UnimplementedError();
  }
}

class _FakeTokenStorage implements IAuthTokenStorage {
  String? storedToken;
  DateTime? storedExpiresAt;
  int saveCount = 0;
  int clearCount = 0;

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
    clearCount++;
  }
}

void main() {
  group('SignInUseCase', () {
    test('should_persist_session_when_repository_returns_valid_credentials',
        () async {
      // Arrange
      final expiresAt = DateTime.utc(2030, 1, 1);
      final repo = _FakeAuthRepository()
        ..nextResult = UserSession(token: 'jwt-abc', expiresAt: expiresAt);
      final storage = _FakeTokenStorage();
      final useCase = SignInUseCase(repo, storage);

      // Act
      final session = await useCase(email: 'a@b.com', password: 'pw');

      // Assert
      expect(session.token, 'jwt-abc');
      expect(storage.storedToken, 'jwt-abc');
      expect(storage.storedExpiresAt, expiresAt);
      expect(storage.saveCount, 1);
      expect(repo.capturedEmail, 'a@b.com');
      expect(repo.capturedPassword, 'pw');
    });

    test('should_not_persist_when_repository_throws', () async {
      // Arrange
      final repo = _FakeAuthRepository()..nextError = Exception('bad creds');
      final storage = _FakeTokenStorage();
      final useCase = SignInUseCase(repo, storage);

      // Act + Assert
      await expectLater(
        useCase(email: 'a@b.com', password: 'wrong'),
        throwsException,
      );
      expect(storage.saveCount, 0);
      expect(storage.storedToken, isNull);
    });
  });
}
