import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/level_model.dart';

/// LevelApi — the data-layer client that talks to the backend's levels
/// endpoint. It performs the HTTP call, checks the status, decodes the
/// JSON, and maps each entry into a LevelModel.
///
/// The base URL points at the locally running NestJS backend. When the
/// app runs in Chrome or the iOS simulator, localhost resolves to the
/// same machine, so this works as-is during development.
class LevelApi {
  // The backend runs on port 3000 with a global /api prefix.
  static const String _baseUrl = 'http://localhost:3000/api';

  /// Fetch the published level catalog. Throws if the request fails or
  /// the server responds with a non-200 status.
  Future<List<LevelModel>> fetchLevels() async {
    final url = Uri.parse('$_baseUrl/levels');

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load levels: HTTP ${response.statusCode}',
      );
    }

    // The body is a JSON array; decode it into a List of maps, then map
    // each one through LevelModel.fromJson.
    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => LevelModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}