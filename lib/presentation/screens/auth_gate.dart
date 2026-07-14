import 'package:flutter/material.dart';
import '../../core/di/service_locator.dart';
import '../../domain/ports/auth_token_storage.dart';
import 'login_screen.dart';
import 'levels_screen.dart';

/// AuthGate — the app's entry point.
///
/// Checks for a stored, non-expired session and routes accordingly:
/// LevelsScreen if a valid token is present, LoginScreen otherwise.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final IAuthTokenStorage _storage = getIt<IAuthTokenStorage>();
  late Future<bool> _hasValidSessionFuture;

  @override
  void initState() {
    super.initState();
    _hasValidSessionFuture = _hasValidSession();
  }

  Future<bool> _hasValidSession() async {
    final token = await _storage.readToken();
    if (token == null || token.isEmpty) return false;
    final expiresAt = await _storage.readExpiresAt();
    if (expiresAt == null || DateTime.now().isAfter(expiresAt)) {
      await _storage.clearSession();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasValidSessionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == true) {
          return const LevelsScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
