import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../domain/models/shop_item.dart';
import '../../../domain/ports/shop_repository.dart';
import '../../dto/shop_item_dto.dart';
import 'api_config.dart';
import 'api_exception.dart';

/// ShopHttpAdapter — HTTP implementation of IShopRepository.
/// Public endpoint, no auth token required (players can browse
/// before signing in).
class ShopHttpAdapter implements IShopRepository {
  const ShopHttpAdapter();

  @override
  Future<List<ShopItem>> fetchItems() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/shop');
    final response = await http.get(url).timeout(ApiConfig.requestTimeout);
    if (response.statusCode != 200) {
      throw ApiException.fromResponse(response);
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map(
          (item) =>
              ShopItemDto.fromJson(item as Map<String, dynamic>).toDomain(),
        )
        .toList();
  }
}
