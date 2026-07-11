import 'package:flutter/material.dart';
import '../data/auth_storage.dart';
import 'screens/login_screen.dart';
/// AuthGuard — global 401 / UnauthorizedException handler.
///
/// Any authenticated screen that catches an UnauthorizedException
/// should call AuthGuard.signOut() from that catch block. The guard:
///   1. Clears the persisted session so the next launch lands on
///      the login screen.
///   2. Pushes LoginScreen as the sole route on the navigator stack,
///      so whatever screen the user was on (mid-game, deep in the
///      shop, etc.) is unmounted.
///
/// The guard holds a `GlobalKey<NavigatorState>` so it can navigate
/// from anywhere — including background futures that no longer have
/// a live BuildContext. That key is wired into MaterialApp.navigatorKey
/// in main.dart, which is the single line that grants global reach.
///
/// Login and register screens intentionally do NOT call signOut on
/// their own 401s: for them "unauthorized" means "wrong credentials",
/// not "your session expired", so they show the message inline via
/// their generic ApiException catch and stay on-screen.
class AuthGuard {
  AuthGuard._();
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static Future<void> signOut() async {
    await AuthStorage().clearSession();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}