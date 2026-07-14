import 'package:flutter/material.dart';
import '../application/usecases/auth/sign_out_usecase.dart';
import '../core/di/service_locator.dart';
import 'screens/login_screen.dart';

/// AuthGuard — global 401 / UnauthorizedException handler.
///
/// Any authenticated screen that catches an UnauthorizedException
/// should call AuthGuard.signOut() from that catch block. Delegates
/// the actual session clearing to SignOutUseCase; the guard's only
/// responsibility is the navigation reset.
class AuthGuard {
  AuthGuard._();
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static Future<void> signOut() async {
    await getIt<SignOutUseCase>()();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}
