import 'package:flutter/material.dart';

import '../../data/auth_storage.dart';
import 'login_screen.dart';
import 'levels_screen.dart';

/// AuthGate — the app's entry point. It checks for a stored token and
/// routes accordingly: straight to the levels screen if the user is
/// already signed in, or to login if not. Shows a spinner while the
/// token is read.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _storage = AuthStorage();
  late Future<String?> _tokenFuture;

  @override
  void initState() {
    super.initState();
    _tokenFuture = _storage.readToken();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _tokenFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final token = snapshot.data;
        if (token != null && token.isNotEmpty) {
          return const LevelsScreen();
        }
        return const LoginScreen();
      },
    );
  }
}