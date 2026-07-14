import 'package:flutter/services.dart';

import '../../../domain/ports/haptics_service.dart';

/// FlutterHapticsAdapter — implements IHapticsService using Flutter's
/// HapticFeedback platform channel. Respects the OS-level haptics
/// mute automatically; no configuration needed here.
class FlutterHapticsAdapter implements IHapticsService {
  const FlutterHapticsAdapter();

  @override
  Future<void> lightTap() => HapticFeedback.lightImpact();

  @override
  Future<void> heavyTap() => HapticFeedback.heavyImpact();

  @override
  Future<void> success() => HapticFeedback.mediumImpact();
}
