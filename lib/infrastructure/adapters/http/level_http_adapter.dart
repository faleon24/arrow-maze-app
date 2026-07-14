import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../domain/models/level.dart';
import '../../../domain/ports/level_repository.dart';
import '../../dto/level_dto.dart';
import 'api_config.dart';
import 'api_exception.dart';

/// LevelHttpAdapter — HTTP implementation of ILevelRepository.
/// Public endpoint, no token required.
class LevelHttpAdapter implements ILevelRepository {
  const LevelHttpAdapter();

  @override
  Future<List<Level>> fetchLevels() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/levels');
    final response = await http.get(url).timeout(ApiConfig.requestTimeout);
    if (response.statusCode != 200) {
      throw ApiException.fromResponse(response);
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map(
          (item) =>
              LevelDto.fromJson(item as Map<String, dynamic>).toDomain(),
        )
        .toList();
  }
}
