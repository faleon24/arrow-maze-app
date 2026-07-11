import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/level_model.dart';
import 'api_config.dart';
/// LevelApi — the data-layer client that talks to the backend's levels
/// endpoint. It performs the HTTP call, checks the status, decodes the
/// JSON, and maps each entry into a LevelModel.
///
/// Base URL and request timeout come from ApiConfig, so a change of
/// backend or of the timeout budget touches one file, not this one.
class LevelApi {
  /// Fetch the published level catalog. Throws if the request times
  /// out (TimeoutException), fails at the socket layer, or the server
  /// responds with a non-200 status.
  Future<List<LevelModel>> fetchLevels() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/levels');
    final response = await http.get(url).timeout(ApiConfig.requestTimeout);
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