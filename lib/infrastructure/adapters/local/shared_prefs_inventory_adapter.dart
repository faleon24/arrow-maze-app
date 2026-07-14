import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/models/power_up_items.dart';
import '../../../domain/ports/inventory_service.dart';

/// SharedPrefsInventoryAdapter — persists item counts locally, one
/// preferences key per item id. First read seeds each known item with
/// its default so a fresh install has power-ups to try.
class SharedPrefsInventoryAdapter implements IInventoryService {
  static const Map<String, int> _defaults = {
    PowerUpItems.hint: 5,
    PowerUpItems.gridHighlight: 5,
  };

  const SharedPrefsInventoryAdapter();

  String _keyOf(String itemId) => 'inventory_$itemId';

  int _defaultOf(String itemId) => _defaults[itemId] ?? 0;

  @override
  Future<int> getCount(String itemId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyOf(itemId)) ?? _defaultOf(itemId);
  }

  @override
  Future<void> add(String itemId, int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_keyOf(itemId)) ?? _defaultOf(itemId);
    await prefs.setInt(_keyOf(itemId), current + amount);
  }

  @override
  Future<bool> tryConsume(String itemId, int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_keyOf(itemId)) ?? _defaultOf(itemId);
    if (current < amount) return false;
    await prefs.setInt(_keyOf(itemId), current - amount);
    return true;
  }
}
