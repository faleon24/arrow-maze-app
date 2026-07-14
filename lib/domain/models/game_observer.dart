/// GameObserver — Subscriber in the Observer pattern (GoF).
///
/// GameSession is the Subject: it holds a list of observers and
/// notifies each one when a meaningful gameplay event fires. Concrete
/// observers (audio + haptics feedback, analytics, tutorials) subclass
/// this and override only the callbacks they care about — the base
/// class provides no-op defaults so a partial observer stays simple.
///
/// All callbacks are `Future<void>` so implementations may perform
/// async work (play a sound, send a metric) without blocking the
/// session's tap handling. Session fires observers with
/// fire-and-forget semantics — the return future is not awaited.
abstract class GameObserver {
  Future<void> onArrowActivated() async {}
  Future<void> onArrowBlocked() async {}
  Future<void> onLevelCleared() async {}
  Future<void> onLevelFailed() async {}
}
