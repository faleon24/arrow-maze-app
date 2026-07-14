import 'package:flutter/material.dart';
import '../../application/usecases/auth/restore_session_usecase.dart';
import '../../core/di/service_locator.dart';
import 'login_screen.dart';
import 'levels_screen.dart';

/// AuthGate — the app's entry point.
///
/// Delegates the "do I have a valid session on disk?" question to the
/// RestoreSessionUseCase. If a session is returned, the levels screen
/// is mounted; otherwise the login screen. A CircularProgressIndicator
/// is shown while the check is in flight.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final RestoreSessionUseCase _restoreSession =
      getIt<RestoreSessionUseCase>();
  late Future<bool> _hasValidSessionFuture;

  @override
  void initState() {
    super.initState();
    _hasValidSessionFuture = _hasValidSession();
  }

  Future<bool> _hasValidSession() async {
    final session = await _restoreSession();
    return session != null;
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
