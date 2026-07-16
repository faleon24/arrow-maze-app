import 'dart:async';
import 'package:flutter/material.dart';
import 'application/usecases/music/play_background_music_usecase.dart';
import 'core/di/service_locator.dart';
import 'core/l10n/locale_controller.dart';
import 'l10n/app_localizations.dart';
import 'presentation/auth_guard.dart';
import 'presentation/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDI();
  // Fire-and-forget: music kicks in as the UI mounts. If the asset
  // is missing or platform lacks audio, the adapter silently no-ops
  // so this call never blocks or crashes launch.
  unawaited(getIt<PlayBackgroundMusicUseCase>()());
  runApp(const ArrowMazeApp());
}

/// Root widget of the Arrow Maze app. Wires the app-wide theme, the
/// AuthGuard navigator key, and localization. The whole MaterialApp is
/// rebuilt through a ListenableBuilder on the LocaleController, so a
/// language switch in Settings takes effect immediately with no restart.
class ArrowMazeApp extends StatelessWidget {
  const ArrowMazeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeController = getIt<LocaleController>();
    return ListenableBuilder(
      listenable: localeController,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: AuthGuard.navigatorKey,
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          locale: localeController.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}
