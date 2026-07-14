import '../../domain/models/shop_item.dart';

/// ShopItemDto — transport shape for a shop catalog entry from
/// GET /shop. Mirrors the backend's ShopItemResponseDto exactly.
class ShopItemDto {
  final String id;
  final String name;
  final int costCoins;
  final String kind;

  const ShopItemDto({
    required this.id,
    required this.name,
    required this.costCoins,
    required this.kind,
  });

  factory ShopItemDto.fromJson(Map<String, dynamic> json) {
    return ShopItemDto(
      id: json['id'] as String,
      name: json['name'] as String,
      costCoins: json['costCoins'] as int,
      kind: json['kind'] as String,
    );
  }

  ShopItem toDomain() => ShopItem(
        id: id,
        name: name,
        costCoins: costCoins,
        kind: kind,
      );
}
