/// IHapticsService — abstract contract for tactile feedback.
///
/// Concrete adapters map these semantic events to platform vibration
/// APIs (Flutter's HapticFeedback on iOS/Android). Application-level
/// code fires these events; the domain and application layers stay
/// ignorant of the vibration mechanism.
abstract class IHapticsService {
  /// A soft, quick tap — used when the player activates an arrow
  /// successfully.
  Future<void> lightTap();

  /// A firm, blunt tap — used when the player taps a blocked arrow.
  Future<void> heavyTap();

  /// A distinctive success pulse — used when a level is cleared.
  Future<void> success();
}
