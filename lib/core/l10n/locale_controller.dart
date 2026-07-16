import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// LocaleController — holds the app's active language and persists the
/// user's choice across launches.
///
/// A [ChangeNotifier] so the root widget can rebuild `MaterialApp` (via
/// `ListenableBuilder`) the instant the language changes, with no
/// restart. Registered as a singleton in the service locator and loaded
/// once at startup so the app opens in the saved language.
class LocaleController extends ChangeNotifier {
  LocaleController(this._locale);

  static const String _prefsKey = 'app_locale';
  static const Locale fallback = Locale('en');

  Locale _locale;
  Locale get locale => _locale;

  /// Reads the persisted language code (default English) and builds the
  /// controller. Called from setupDI before the first frame.
  static Future<LocaleController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    final locale = (code == null) ? fallback : Locale(code);
    return LocaleController(locale);
  }

  /// Switches language, notifies listeners immediately, then persists.
  Future<void> setLocale(Locale locale) async {
    if (locale.languageCode == _locale.languageCode) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
  }
}
