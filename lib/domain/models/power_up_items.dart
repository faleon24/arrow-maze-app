/// PowerUpItems — whitelist of item IDs a player can hold in inventory
/// and consume during play.
///
/// String constants instead of an enum (project constraint). Adapters
/// and use cases must reference these values, never a raw literal.
class PowerUpItems {
  PowerUpItems._();

  /// Hint: reveals one currently activatable arrow.
  static const String hint = 'HINT';

  /// Grid highlight: shows the ray path an arrow would traverse
  /// without activating it.
  static const String gridHighlight = 'GRID_HIGHLIGHT';

  /// Every known item id — useful for iteration in tests and adapters.
  static const List<String> all = [hint, gridHighlight];
}
