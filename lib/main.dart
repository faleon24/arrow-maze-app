import 'package:flutter/material.dart';
import 'presentation/auth_guard.dart';
import 'presentation/screens/auth_gate.dart';
void main() {
  runApp(const ArrowMazeApp());
}
/// Root widget of the Arrow Maze app. Sets up the app-wide theme and
/// wires the AuthGuard's navigator key into MaterialApp so any catch
/// block anywhere in the app can force a sign-out without holding a
/// BuildContext.
class ArrowMazeApp extends StatelessWidget {
  const ArrowMazeApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: AuthGuard.navigatorKey,
      title: 'Arrow Maze',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}