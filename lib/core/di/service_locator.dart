import 'package:get_it/get_it.dart';

import '../../domain/ports/auth_repository.dart';
import '../../domain/ports/auth_token_storage.dart';
import '../../domain/ports/level_repository.dart';
import '../../domain/ports/progress_repository.dart';
import '../../infrastructure/adapters/http/auth_http_adapter.dart';
import '../../infrastructure/adapters/http/level_http_adapter.dart';
import '../../infrastructure/adapters/http/progress_http_adapter.dart';
import '../../infrastructure/adapters/local/dev_level_adapter.dart';
import '../../infrastructure/adapters/local/shared_prefs_token_storage.dart';

/// getIt — the app's single service locator instance.
///
/// Screens and other consumers resolve dependencies via `getIt<T>()` to
/// stay decoupled from concrete implementations. All bindings live in
/// [setupDI], which is called once from main() before runApp.
final getIt = GetIt.instance;

/// setupDI — the composition root. Registers every port with its
/// concrete adapter. Called once at app start.
///
/// The USE_DEV_LEVELS compile-time flag switches the ILevelRepository
/// binding to the bundled fixture adapter, so the app can run without
/// the backend during demos or offline playtesting.
Future<void> setupDI() async {
  getIt.registerLazySingleton<IAuthTokenStorage>(
    () => const SharedPrefsTokenStorage(),
  );

  getIt.registerLazySingleton<IAuthRepository>(
    () => const AuthHttpAdapter(),
  );

  const useDevLevels =
      bool.fromEnvironment('USE_DEV_LEVELS', defaultValue: false);
  if (useDevLevels) {
    getIt.registerLazySingleton<ILevelRepository>(
      () => const DevLevelAdapter(),
    );
  } else {
    getIt.registerLazySingleton<ILevelRepository>(
      () => const LevelHttpAdapter(),
    );
  }

  getIt.registerLazySingleton<IProgressRepository>(
    () => ProgressHttpAdapter(getIt<IAuthTokenStorage>()),
  );
}
