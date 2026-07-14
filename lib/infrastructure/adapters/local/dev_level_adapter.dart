import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../domain/models/level.dart';
import '../../../domain/ports/level_repository.dart';
import '../../dto/level_dto.dart';

/// DevLevelAdapter — loads the bundled level catalog from
/// assets/fixtures/levels_dev.json. Bound in DI when USE_DEV_LEVELS
/// is set. Same ILevelRepository contract as the HTTP adapter for
/// reads; generation is not supported here because there is no
/// server to procedurally create a puzzle.
class DevLevelAdapter implements ILevelRepository {
  static const String _assetPath = 'assets/fixtures/levels_dev.json';

  const DevLevelAdapter();

  @override
  Future<List<Level>> fetchLevels() async {
    final raw = await rootBundle.loadString(_assetPath);
    final data = jsonDecode(raw) as List<dynamic>;
    return data
        .map(
          (item) =>
              LevelDto.fromJson(item as Map<String, dynamic>).toDomain(),
        )
        .toList();
  }

  @override
  Future<Level> generate({required String difficulty}) {
    throw UnsupportedError(
      'DevLevelAdapter cannot generate levels — offline fixture only.',
    );
  }
}
