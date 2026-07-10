import 'package:flutter/material.dart';

import 'presentation/screens/auth_gate.dart';

void main() {
  runApp(const ArrowMazeApp());
}

/// Root widget of the Arrow Maze app. Sets up the app-wide theme and
/// points the home to the levels screen.
class ArrowMazeApp extends StatelessWidget {
  const ArrowMazeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arrow Maze',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}