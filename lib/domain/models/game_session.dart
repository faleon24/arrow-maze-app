import 'arrow_path.dart';
import 'board.dart';
import 'collectible.dart';
import 'game_observer.dart';
import 'game_state.dart';
import 'position.dart';

/// TapOutcome — what a tap resolved to. Modeled as a small hierarchy
/// (project constraint: no enums).
class TapOutcome {
  final String value;
  const TapOutcome._(this.value);
  static const cleared = TapOutcome._('CLEARED');
  static const blocked = TapOutcome._('BLOCKED');
  static const notAnArrow = TapOutcome._('NOT_AN_ARROW');
}

/// GameSession — v2 state and rules of a single play-through.
///
/// v2 changes: holds an explicit [GameState] (State pattern) and a
/// list of [GameObserver] subscribers (Observer pattern). Tap
/// handling first checks `state.allowsTaps`, then executes the
/// existing ray-clearing logic, then transitions state and fans out
/// notifications to observers so audio, haptics, analytics etc. react
/// automatically without the session knowing about them.
class GameSession {
  Board board;
  final int moveLimit;
  final int maxLives;
  int movesUsed;
  int lives;

  final Set<Position> collectedPositions;

  GameState _state;
  final List<GameObserver> _observers;

  GameSession({
    required this.board,
    required this.moveLimit,
    this.maxLives = 3,
  })  : movesUsed = 0,
        lives = maxLives,
        collectedPositions = <Position>{},
        _state = const PlayingState(),
        _observers = <GameObserver>[];

  /// Current lifecycle state. UI reads `state.allowsTaps` and
  /// `state.label` instead of composing isCleared/isFailed/isPaused
  /// checks.
  GameState get state => _state;

  /// Register [observer] to receive gameplay callbacks.
  void addObserver(GameObserver observer) {
    _observers.add(observer);
  }

  /// Unregister a previously added observer. No-op if not present.
  void removeObserver(GameObserver observer) {
    _observers.remove(observer);
  }

  /// Transition to PausedState. Only valid from PlayingState; other
  /// states silently ignore the call.
  void pause() {
    if (_state is PlayingState) _state = const PausedState();
  }

  /// Transition back to PlayingState. Only valid from PausedState.
  void resume() {
    if (_state is PausedState) _state = const PlayingState();
  }

  /// Is the arrow with [arrowId] free to fire? True only if a ray from
  /// its head, stepping in its direction, reaches the grid edge without
  /// hitting a wall or another arrow's cells.
  bool isActivatable(String arrowId) {
    final arrow = _findArrow(arrowId);
    if (arrow == null) return false;
    var next = arrow.direction.apply(arrow.head);
    while (board.contains(next)) {
      if (board.isWall(next)) return false;
      final foreign = board.arrowAt(next);
      if (foreign != null && foreign.id != arrowId) return false;
      next = arrow.direction.apply(next);
    }
    return true;
  }

  /// Tap a board position. Returns what happened. Delegates the
  /// allow-taps check to [_state], so PausedState / ClearedState /
  /// FailedState silently short-circuit to notAnArrow.
  TapOutcome tap(Position position) {
    if (!_state.allowsTaps) return TapOutcome.notAnArrow;

    final arrow = board.arrowAt(position);
    if (arrow == null) return TapOutcome.notAnArrow;

    movesUsed++;
    TapOutcome outcome;
    if (!isActivatable(arrow.id)) {
      lives--;
      outcome = TapOutcome.blocked;
    } else {
      _clearArrow(arrow);
      outcome = TapOutcome.cleared;
    }

    // Notify subscribed observers of the tap event.
    if (outcome == TapOutcome.blocked) {
      for (final obs in _observers) {
        obs.onArrowBlocked();
      }
    } else {
      for (final obs in _observers) {
        obs.onArrowActivated();
      }
    }

    // Transition to terminal states + notify level-scale events.
    if (isCleared) {
      _state = const ClearedState();
      for (final obs in _observers) {
        obs.onLevelCleared();
      }
    } else if (isFailed) {
      _state = const FailedState();
      for (final obs in _observers) {
        obs.onLevelFailed();
      }
    }

    return outcome;
  }

  ArrowPath? _findArrow(String id) {
    for (final a in board.arrows) {
      if (a.id == id) return a;
    }
    return null;
  }

  void _clearArrow(ArrowPath arrow) {
    final gathered = <Position>{};
    var next = arrow.direction.apply(arrow.head);
    while (board.contains(next)) {
      final c = board.collectibleAt(next);
      if (c != null) gathered.add(next);
      next = arrow.direction.apply(next);
    }

    final remainingArrows =
        board.arrows.where((a) => a.id != arrow.id).toList();
    final remainingCollectibles = <Position, Collectible>{
      for (final entry in board.collectibles.entries)
        if (!gathered.contains(entry.key)) entry.key: entry.value,
    };

    board = Board(
      rows: board.rows,
      cols: board.cols,
      arrows: remainingArrows,
      walls: board.walls,
      collectibles: remainingCollectibles,
    );

    collectedPositions.addAll(gathered);
  }

  /// True when every arrow has been cleared.
  bool get isCleared => board.arrows.isEmpty;

  /// True when the run is unwinnable: no lives, or move budget spent
  /// while arrows still stand.
  bool get isFailed => !isCleared && (lives <= 0 || movesUsed >= moveLimit);

  int get arrowsRemaining => board.arrows.length;

  int get starsEarned {
    final livesLost = maxLives - lives;
    final stars = 3 - livesLost;
    return stars < 1 ? 1 : stars;
  }
}
