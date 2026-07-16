import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// AppLocalizations — hand-written localization table for English and
/// Spanish.
///
/// Written explicitly (rather than generated via gen-l10n) so the app
/// has zero dependency on the codegen toolchain and behaves identically
/// across Flutter versions. Each user-facing string is a getter that
/// branches on the active locale. Adding a language means adding a
/// branch; adding a string means adding a getter.
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

  /// The locales this app ships translations for.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// Delegates to plug into MaterialApp: our table plus Flutter's own
  /// Material/Widgets/Cupertino translations (so date pickers, tooltips,
  /// and semantics are localized too).
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
