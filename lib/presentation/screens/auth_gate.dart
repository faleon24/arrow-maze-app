import 'package:flutter/material.dart';
import '../../data/auth_storage.dart';
import 'login_screen.dart';
import 'levels_screen.dart';
/// AuthGate — the app's entry point.
///
/// Checks for a stored, non-expired session and routes accordingly:
/// LevelsScreen if a valid token is present, LoginScreen otherwise.
/// If the token is present but its expiry is in the past, the session
/// is cleared before routing — no need to fire a doomed request first.
///
/// A CircularProgressIndicator is shown while the read is in flight;
/// it is quick (SharedPreferences), so the flash is barely visible.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}
class _AuthGateState extends State<AuthGate> {
  final _storage = AuthStorage();
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
      // Locally expired — clear before routing so a subsequent launch
      // does not repeat the check-and-clear dance.
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