import 'package:flutter/material.dart';
import '../core/di/service_locator.dart';
import '../domain/ports/auth_token_storage.dart';
import 'screens/login_screen.dart';

/// AuthGuard — global 401 / UnauthorizedException handler.
///
/// Any authenticated screen that catches an UnauthorizedException
/// should call AuthGuard.signOut() from that catch block. The guard
/// clears the persisted session and pushes LoginScreen as the sole
/// route on the navigator stack.
class AuthGuard {
  AuthGuard._();
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static Future<void> signOut() async {
    await getIt<IAuthTokenStorage>().clearSession();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}
