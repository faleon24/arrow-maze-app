import 'dart:convert';

import 'package:flutter/services.dart';

import 'models/level_model.dart';

/// DevLevelSource — loads the bundled level catalog from
/// `assets/fixtures/levels_dev.json` so the app can run without the
/// backend during development, demos, or offline playtesting.
///
/// Mirrors [LevelApi.fetchLevels]'s return signature so it's drop-in
/// where the API is used. Selection between the two is a wiring
/// concern (Fase 5.4) — likely a `--dart-define` compile-time flag or
/// a small toggle on the levels screen.
class DevLevelSource {
  static const String _assetPath = 'assets/fixtures/levels_dev.json';

  /// Read, parse, and validate the bundled dev catalog. Boards go
  /// through BoardBuilder via [LevelModel.fromJson] so a stale fixture
  /// fails fast with the same FormatException prod code would raise.
  static Future<List<LevelModel>> load() async {
    final raw = await rootBundle.loadString(_assetPath);
    final data = jsonDecode(raw) as List<dynamic>;
    return data
        .map((item) => LevelModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}