import 'package:get_it/get_it.dart';
import '../l10n/locale_controller.dart';

import '../../application/usecases/auth/register_usecase.dart';
import '../../application/usecases/auth/restore_session_usecase.dart';
import '../../application/usecases/auth/sign_in_usecase.dart';
import '../../application/usecases/auth/sign_out_usecase.dart';
import '../../application/usecases/game/game_feedback_usecase.dart';
import '../../application/usecases/game/reveal_hint_usecase.dart';
import '../../application/usecases/game/use_grid_highlight_usecase.dart';
import '../../application/usecases/level/generate_level_usecase.dart';
import '../../application/usecases/level/get_levels_usecase.dart';
import '../../application/usecases/leaderboard/get_leaderboard_usecase.dart';
import '../../application/usecases/music/play_background_music_usecase.dart';
import '../../application/usecases/music/toggle_music_usecase.dart';
import '../../domain/ports/music_service.dart';
import '../../infrastructure/adapters/platform/audio_players_music_adapter.dart';
import '../../domain/ports/leaderboard_repository.dart';
import '../../infrastructure/adapters/http/leaderboard_http_adapter.dart';
import '../../application/usecases/level/load_levels_catalog_usecase.dart';
import '../../application/usecases/lives/consume_life_usecase.dart';
import '../../application/usecases/lives/get_lives_usecase.dart';
import '../../application/usecases/lives/purchase_life_usecase.dart';
import '../../application/usecases/progress/get_stars_by_level_usecase.dart';
import '../../application/usecases/progress/submit_level_result_usecase.dart';
import '../../application/usecases/shop/buy_shop_item_usecase.dart';
import '../../application/usecases/shop/list_shop_items_usecase.dart';
import '../../application/usecases/wallet/award_coins_for_level_usecase.dart';
import '../../application/usecases/wallet/get_wallet_balance_usecase.dart';
import '../../domain/ports/audio_service.dart';
import '../../domain/ports/auth_repository.dart';
import '../../domain/ports/auth_token_storage.dart';
import '../../domain/ports/haptics_service.dart';
import '../../domain/ports/inventory_service.dart';
import '../../domain/ports/level_repository.dart';
import '../../domain/ports/lives_service.dart';
import '../../domain/ports/progress_repository.dart';
import '../../domain/ports/shop_repository.dart';
import '../../domain/ports/wallet_service.dart';
import '../../domain/services/arrow_ray_calculator.dart';
import '../../infrastructure/adapters/http/auth_http_adapter.dart';
import '../../infrastructure/adapters/http/level_http_adapter.dart';
import '../../infrastructure/adapters/http/progress_http_adapter.dart';
import '../../infrastructure/adapters/http/shop_http_adapter.dart';
import '../../infrastructure/adapters/local/dev_level_adapter.dart';
import '../../infrastructure/adapters/local/shared_prefs_inventory_adapter.dart';
import '../../infrastructure/adapters/local/shared_prefs_lives_adapter.dart';
import '../../infrastructure/adapters/local/shared_prefs_token_storage.dart';
import '../../infrastructure/adapters/local/shared_prefs_wallet_adapter.dart';
import '../../infrastructure/adapters/platform/flutter_haptics_adapter.dart';
import '../../infrastructure/adapters/platform/system_sounds_audio_adapter.dart';

/// getIt — the app's single service locator instance.
final getIt = GetIt.instance;

/// setupDI — the composition root. Registers every port with its
/// concrete adapter, then every application use case with its port
/// dependencies. Called once at app start from main().
Future<void> setupDI() async {
  // Locale controller: load the persisted language before any UI mounts,
  // so the app opens in the user's saved language.
  getIt.registerSingleton<LocaleController>(await LocaleController.load());

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
    () => FlutterHapticsAdapter(),
  );
  getIt.registerLazySingleton<IAudioService>(
    () => SystemSoundsAudioAdapter(),
  );
  getIt.registerLazySingleton<IWalletService>(
    () => const SharedPrefsWalletAdapter(),
  );
  getIt.registerLazySingleton<IInventoryService>(
    () => const SharedPrefsInventoryAdapter(),
  );
  getIt.registerLazySingleton<ILivesService>(
    () => const SharedPrefsLivesAdapter(),
  );
  getIt.registerLazySingleton<IShopRepository>(
    () => const ShopHttpAdapter(),
  );
  getIt.registerLazySingleton<ILeaderboardRepository>(
    () => const LeaderboardHttpAdapter(),
  );
  getIt.registerLazySingleton<IMusicService>(
    () => AudioPlayersMusicAdapter(),
  );

  // === Domain services ===
  getIt.registerLazySingleton<ArrowRayCalculator>(
    () => const ArrowRayCalculator(),
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
  getIt.registerFactory(
    () => GenerateLevelUseCase(getIt<ILevelRepository>()),
  );

  // === Application use cases: game ===
  getIt.registerFactory(
    () => GameFeedbackUseCase(
      getIt<IHapticsService>(),
      getIt<IAudioService>(),
    ),
  );
  getIt.registerFactory(
    () => RevealHintUseCase(getIt<IInventoryService>()),
  );
  getIt.registerFactory(
    () => UseGridHighlightUseCase(
      getIt<IInventoryService>(),
      getIt<ArrowRayCalculator>(),
    ),
  );

  // === Application use cases: wallet ===
  getIt.registerFactory(
    () => GetWalletBalanceUseCase(getIt<IWalletService>()),
  );
  getIt.registerFactory(
    () => AwardCoinsForLevelUseCase(getIt<IWalletService>()),
  );

  // === Application use cases: lives ===
  getIt.registerFactory(
    () => GetLivesUseCase(getIt<ILivesService>()),
  );
  getIt.registerFactory(
    () => ConsumeLifeUseCase(getIt<ILivesService>()),
  );
  getIt.registerFactory(
    () => PurchaseLifeUseCase(
      getIt<IWalletService>(),
      getIt<ILivesService>(),
    ),
  );

  // === Application use cases: shop ===
  getIt.registerFactory(
    () => ListShopItemsUseCase(getIt<IShopRepository>()),
  );
  getIt.registerFactory(
    () => BuyShopItemUseCase(
      getIt<IWalletService>(),
      getIt<IInventoryService>(),
      getIt<ILivesService>(),
    ),
  );

  // === Application use cases: leaderboard ===
  getIt.registerFactory(
    () => GetLeaderboardUseCase(getIt<ILeaderboardRepository>()),
  );

  // === Application use cases: music ===
  getIt.registerLazySingleton(
    () => PlayBackgroundMusicUseCase(getIt<IMusicService>()),
  );
  getIt.registerLazySingleton(
    () => ToggleMusicUseCase(getIt<IMusicService>()),
  );
}
