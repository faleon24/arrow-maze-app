import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// AppLocalizations — hand-written localization table for English and
/// Spanish.
///
/// Written explicitly (rather than generated via gen-l10n) so the app
/// has zero dependency on the codegen toolchain and behaves identically
/// across Flutter versions. Each user-facing string is a getter (or a
/// method, when it takes parameters) that branches on the active locale.
/// Adding a language means adding a branch; adding a string means adding
/// a getter.
///
/// Wire-up (in MaterialApp):
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales:       AppLocalizations.supportedLocales,
///   locale:                 (supplied by LocaleController),
/// and read strings with `AppLocalizations.of(context).play`.
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  bool get _es => locale.languageCode == 'es';

  // --- Brand ---------------------------------------------------------
  String get appTitle => 'Arrow Maze';
  String get tagline => _es ? 'Rompecabezas de escape' : 'Escape Puzzle';

  // --- Home ----------------------------------------------------------
  String get play => _es ? 'Jugar' : 'Play';

  // --- Settings ------------------------------------------------------
  String get settings => _es ? 'Ajustes' : 'Settings';
  String get settingsFeedbackSection => _es ? 'Retroalimentación' : 'Feedback';
  String get backgroundMusic => _es ? 'Música de fondo' : 'Background music';
  String get backgroundMusicSubtitle =>
      _es ? 'Suena durante el juego' : 'Loops during play';
  String get soundEffects => _es ? 'Efectos de sonido' : 'Sound effects';
  String get soundEffectsSubtitle =>
      _es ? 'Toques y eventos del juego' : 'Tap and event feedback';
  String get haptics => _es ? 'Vibración' : 'Haptics';
  String get hapticsSubtitle =>
      _es ? 'Vibración en toques y eventos' : 'Vibration on tap and events';
  String get settingsLanguageSection => _es ? 'Idioma' : 'Language';
  String get languageEnglish => _es ? 'Inglés' : 'English';
  String get languageSpanish => _es ? 'Español' : 'Spanish';
  String get settingsAboutSection => _es ? 'Acerca de' : 'About';

  // --- Auth (login / register) ---------------------------------------
  String get signInTitle =>
      _es ? 'Arrow Maze — Iniciar sesión' : 'Arrow Maze — Sign in';
  String get registerTitle =>
      _es ? 'Arrow Maze — Registro' : 'Arrow Maze — Register';
  String get emailLabel => _es ? 'Correo' : 'Email';
  String get passwordLabel => _es ? 'Contraseña' : 'Password';
  String get displayNameLabel => _es ? 'Nombre visible' : 'Display name';
  String get signIn => _es ? 'Iniciar sesión' : 'Sign in';
  String get createAccount => _es ? 'Crear cuenta' : 'Create account';
  String get noAccountRegister =>
      _es ? '¿No tienes cuenta? Regístrate' : "Don't have an account? Register";

  // --- Levels --------------------------------------------------------
  String get levelsTitle => _es ? 'Arrow Maze — Niveles' : 'Arrow Maze — Levels';
  String get alreadyMaxLives =>
      _es ? 'Ya tienes el máximo de vidas' : 'Already at max lives';
  String oneLifeBought(Object cost) =>
      _es ? '+1 vida (-$cost monedas)' : '+1 life (-$cost coins)';
  String notEnoughCoins(Object cost) => _es
      ? 'Monedas insuficientes (necesitas $cost)'
      : 'Not enough coins (need $cost)';
  String get noLivesLeft => _es
      ? 'Sin vidas. Compra una con monedas para jugar.'
      : 'No lives left. Buy one with coins to play.';
  String get generateNewLevelTitle =>
      _es ? 'Generar un nuevo nivel' : 'Generate a new level';
  String get generateNewLevelBody => _es
      ? 'Elige una dificultad y el servidor crea un puzzle resoluble.'
      : 'Pick a difficulty and the server crafts a solvable puzzle.';
  String generatedLevel(Object difficulty, Object number) => _es
      ? 'Nivel $difficulty #$number generado'
      : 'Generated $difficulty level #$number';
  String generationFailed(Object error) =>
      _es ? 'Falló la generación: $error' : 'Generation failed: $error';
  String buyOneLifeTooltip(Object cost) =>
      _es ? 'Comprar 1 vida ($cost monedas)' : 'Buy 1 life ($cost coins)';
  String get signOut => _es ? 'Cerrar sesión' : 'Sign out';
  String get generating => _es ? 'Generando...' : 'Generating...';
  String get generateLevel => _es ? 'Generar nivel' : 'Generate level';
  String errorLoadingLevels(Object error) =>
      _es ? 'Error al cargar niveles:\n$error' : 'Error loading levels:\n$error';
  String get noLevelsPublished =>
      _es ? 'Aún no hay niveles publicados.' : 'No levels published yet.';
  String levelN(Object number) => _es ? 'Nivel $number' : 'Level $number';
  String unlockHint(Object threshold, Object level) => _es
      ? 'Consigue $threshold estrella(s) en el Nivel $level para desbloquear este.'
      : 'Earn $threshold star(s) on Level $level to unlock this one.';

  // --- Shop ----------------------------------------------------------
  String get shop => _es ? 'Tienda' : 'Shop';
  String buyItemTitle(Object name) => _es ? '¿Comprar $name?' : 'Buy $name?';
  String buyItemBody(Object cost) => _es
      ? 'Esto gastará $cost monedas de tu billetera.'
      : 'This will spend $cost coins from your wallet.';
  String get cancel => _es ? 'Cancelar' : 'Cancel';
  String get buy => _es ? 'Comprar' : 'Buy';
  String errorLoadingShop(Object error) =>
      _es ? 'Error al cargar la tienda:\n$error' : 'Error loading shop:\n$error';
  String get shopEmpty => _es ? 'La tienda está vacía.' : 'The shop is empty.';

  // --- Leaderboard ---------------------------------------------------
  String get leaderboard => _es ? 'Clasificación' : 'Leaderboard';
  String leaderboardTitle(Object number) =>
      _es ? 'Clasificación — Nivel $number' : 'Leaderboard — Level $number';
  String errorLoadingLeaderboard(Object error) => _es
      ? 'Error al cargar la clasificación:\n$error'
      : 'Error loading leaderboard:\n$error';
  String get noRunsRecorded => _es
      ? 'Aún no hay partidas. ¡Sé el primero en la tabla!'
      : 'No runs recorded yet. Be the first to top the board!';
  String get viewRanking => _es ? 'Ver clasificación' : 'View ranking';
  String yourRank(Object rank) =>
      _es ? 'Tu puesto: #$rank' : 'Your rank: #$rank';
  String get youBadge => _es ? 'Tú' : 'You';

  // --- Game ----------------------------------------------------------
  String get noActivatableArrows =>
      _es ? 'No hay flechas activables ahora' : 'No activatable arrows right now';
  String get outOfHints => _es ? 'Sin pistas' : 'Out of hints';
  String get outOfGridHighlights =>
      _es ? 'Sin resaltados de cuadrícula' : 'Out of grid highlights';
  String get levelCleared => _es ? '¡Nivel superado!' : 'Level cleared!';
  String get outOfMoves => _es ? 'Sin movimientos' : 'Out of moves';
  String clearedBoardIn(Object moves, Object time) => _es
      ? 'Despejaste el tablero en $moves movimientos ($time).'
      : 'You cleared the board in $moves moves ($time).';
  String starsEarned(Object stars) =>
      _es ? 'Estrellas ganadas: $stars' : 'Stars earned: $stars';
  String coinsEarned(Object coins, Object total) => _es
      ? 'Monedas ganadas: +$coins (total: $total)'
      : 'Coins earned: +$coins (total: $total)';
  String get progressSaved => _es ? 'Progreso guardado.' : 'Progress saved.';
  String couldNotSave(Object error) =>
      _es ? 'No se pudo guardar: $error' : 'Could not save: $error';
  String boardStillHas(Object arrows) => _es
      ? 'Al tablero le quedan $arrows flechas.'
      : 'The board still has $arrows arrows.';
  String get oneLifeSpent => _es ? '-1 vida gastada.' : '-1 life spent.';
  String get backToLevels => _es ? 'Volver a niveles' : 'Back to levels';
  String get playAgain => _es ? 'Jugar de nuevo' : 'Play again';
  String get nextLevel => _es ? 'Siguiente nivel' : 'Next level';
  String gameLevelTitle(Object number, Object difficulty) =>
      _es ? 'Nivel $number - $difficulty' : 'Level $number - $difficulty';
  String get pause => _es ? 'Pausar' : 'Pause';
  String get resume => _es ? 'Reanudar' : 'Resume';
  String get resetZoom => _es ? 'Restablecer zoom' : 'Reset zoom';
  String get paused => _es ? 'EN PAUSA' : 'PAUSED';
  String hintLabel(Object count) => _es ? 'Pista ($count)' : 'Hint ($count)';
  String get tapAnArrow => _es ? 'Toca una flecha' : 'Tap an arrow';
  String gridLabel(Object count) =>
      _es ? 'Cuadrícula ($count)' : 'Grid ($count)';
  String get statArrowsLeft => _es ? 'Flechas' : 'Arrows left';
  String get statMoves => _es ? 'Movimientos' : 'Moves';
  String get statTime => _es ? 'Tiempo' : 'Time';
  String get statAttempts => _es ? 'Intentos' : 'Attempts';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
