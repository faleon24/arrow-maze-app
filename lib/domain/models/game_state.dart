/// GameState — State pattern (GoF, behavioral).
///
/// GameSession holds one instance of GameState and swaps concrete
/// subclasses at lifecycle transitions. Consumers (UI + tap logic)
/// query [allowsTaps] and [label] instead of scattering
/// `if (session.isCleared || session.isFailed || session.isPaused)`
/// checks — the state itself answers.
///
/// Concrete states:
///   * PlayingState  — normal turn, taps processed.
///   * PausedState   — input ignored, timer frozen at the UI layer.
///   * ClearedState  — terminal, level won. Taps no-op.
///   * FailedState   — terminal, level lost. Taps no-op.
///
/// All states are stateless singletons — const constructors, no
/// fields — so a GameSession can `_state = const PlayingState()` at
/// any point without allocating.
abstract class GameState {
  const GameState();

  /// True when a cell tap should mutate the session (activate an
  /// arrow, decrement lives on block, etc.).
  bool get allowsTaps;

  /// True when the state is a terminal (game over) leaf.
  bool get isTerminal;

  /// Machine-readable identifier for UI + tests.
  String get label;
}

class PlayingState extends GameState {
  const PlayingState();

  @override
  bool get allowsTaps => true;

  @override
  bool get isTerminal => false;

  @override
  String get label => 'PLAYING';
}

class PausedState extends GameState {
  const PausedState();

  @override
  bool get allowsTaps => false;

  @override
  bool get isTerminal => false;

  @override
  String get label => 'PAUSED';
}

class ClearedState extends GameState {
  const ClearedState();

  @override
  bool get allowsTaps => false;

  @override
  bool get isTerminal => true;

  @override
  String get label => 'CLEARED';
}

class FailedState extends GameState {
  const FailedState();

  @override
  bool get allowsTaps => false;

  @override
  bool get isTerminal => true;

  @override
  String get label => 'FAILED';
}
