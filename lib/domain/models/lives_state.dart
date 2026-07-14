/// LivesState — the player's current and maximum lives, read in one
/// snapshot. Immutable value object.
class LivesState {
  final int current;
  final int max;

  const LivesState({required this.current, required this.max});

  bool get isEmpty => current <= 0;
  bool get isFull => current >= max;
}
