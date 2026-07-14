import 'package:get_it/get_it.dart';

import '../../application/usecases/auth/register_usecase.dart';
import '../../application/usecases/auth/restore_session_usecase.dart';
import '../../application/usecases/auth/sign_in_usecase.dart';
import '../../application/usecases/auth/sign_out_usecase.dart';
import '../../application/usecases/game/game_feedback_usecase.dart';
import '../../application/usecases/level/get_levels_usecase.dart';
import '../../application/usecases/level/load_levels_catalog_usecase.dart';
import '../../application/usecases/progress/get_stars_by_level_usecase.dart';
import '../../application/usecases/progress/submit_level_result_usecase.dart';
import '../../domain/ports/audio_service.dart';
import '../../domain/ports/auth_repository.dart';
import '../../domain/ports/auth_token_storage.dart';
import '../../domain/ports/haptics_service.dart';
import '../../domain/ports/level_repository.dart';
import '../../domain/ports/progress_repository.dart';
import '../../infrastructure/adapters/http/auth_http_adapter.dart';
import '../../infrastructure/adapters/http/level_http_adapter.dart';
import '../../infrastructure/adapters/http/progress_http_adapter.dart';
import '../../infrastructure/adapters/local/dev_level_adapter.dart';
import '../../infrastructure/adapters/local/shared_prefs_token_storage.dart';
import '../../infrastructure/adapters/platform/flutter_haptics_adapter.dart';
import '../../infrastructure/adapters/platform/system_sounds_audio_adapter.dart';

/// getIt — the app's single service locator instance.
final getIt = GetIt.instance;

/// setupDI — the composition root. Registers every port with its
/// concrete adapter, then every application use case with its port
/// dependencies. Called once at app start from main().
Future<void> setupDI() async {
  // === Infrastructure (adapters bound to ports) ===
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
  getIt.registerLazySingleton<IHapticsService>(
    () => const FlutterHapticsAdapter(),
  );
  getIt.registerLazySingleton<IAudioService>(
    () => const SystemSoundsAudioAdapter(),
  );

  // === Application use cases: auth ===
  getIt.registerFactory(
    () => SignInUseCase(
      getIt<IAuthRepository>(),
      getIt<IAuthTokenStorage>(),
    ),
  );
  getIt.registerFactory(
    () => RegisterUseCase(
      getIt<IAuthRepository>(),
      getIt<IAuthTokenStorage>(),
    ),
  );
  getIt.registerFactory(
    () => SignOutUseCase(getIt<IAuthTokenStorage>()),
  );
  getIt.registerFactory(
    () => RestoreSessionUseCase(getIt<IAuthTokenStorage>()),
  );

  // === Application use cases: level + progress ===
  getIt.registerFactory(
    () => GetLevelsUseCase(getIt<ILevelRepository>()),
  );
  getIt.registerFactory(
    () => GetStarsByLevelUseCase(getIt<IProgressRepository>()),
  );
  getIt.registerFactory(
    () => SubmitLevelResultUseCase(getIt<IProgressRepository>()),
  );
  getIt.registerFactory(
    () => LoadLevelsCatalogUseCase(
      getIt<GetLevelsUseCase>(),
      getIt<GetStarsByLevelUseCase>(),
    ),
  );

  // === Application use cases: game ===
  getIt.registerFactory(
    () => GameFeedbackUseCase(
      getIt<IHapticsService>(),
      getIt<IAudioService>(),
    ),
  );
}
