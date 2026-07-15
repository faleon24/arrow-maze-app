import 'dart:async';

import 'package:flutter/material.dart';

import 'application/usecases/music/play_background_music_usecase.dart';
import 'core/di/service_locator.dart';
import 'presentation/auth_guard.dart';
import 'presentation/screens/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDI();
  // Fire-and-forget: music kicks in as the UI mounts. If the asset
  // is missing or platform lacks audio, the adapter silently no-ops
  // so this call never blocks or crashes launch.
  unawaited(getIt<PlayBackgroundMusicUseCase>()());
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
      debugShowCheckedModeBanner:false,
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
