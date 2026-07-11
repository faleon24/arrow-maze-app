import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/level_model.dart';
import 'api_config.dart';
import 'api_exception.dart';
/// LevelApi — the data-layer client that talks to the backend's levels
/// endpoint. Public route: no token required.
class LevelApi {
  /// Fetch the published level catalog. Throws ApiException on any
  /// non-200 response; TimeoutException if the request exceeds
  /// ApiConfig.requestTimeout.
  Future<List<LevelModel>> fetchLevels() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/levels');
    final response = await http.get(url).timeout(ApiConfig.requestTimeout);
    if (response.statusCode != 200) {
      throw ApiException.fromResponse(response);
    }
    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => LevelModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}