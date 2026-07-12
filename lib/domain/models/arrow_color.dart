import 'package:flutter/painting.dart';

/// ArrowColor — Strategy for the tint an arrow-path takes on the board.
///
/// Modeled as a class hierarchy rather than an enum (project constraint):
/// each color knows its backend label and how to render itself. Callers
/// depend only on the abstract type; concrete palette values live in one
/// place, so retuning the visual identity is a local edit.
abstract class ArrowColor {
  /// The backend's string label (PINK/GREEN/BLUE/YELLOW/PURPLE).
  String get name;

  /// The neon tint used by the renderer.
  Color get hex;
}

class PinkColor extends ArrowColor {
  @override
  String get name => 'PINK';
  @override
  Color get hex => const Color(0xFFFF3EA5);
}

class GreenColor extends ArrowColor {
  @override
  String get name => 'GREEN';
  @override
  Color get hex => const Color(0xFF39FF14);
}

class BlueColor extends ArrowColor {
  @override
  String get name => 'BLUE';
  @override
  Color get hex => const Color(0xFF00E0FF);
}

class YellowColor extends ArrowColor {
  @override
  String get name => 'YELLOW';
  @override
  Color get hex => const Color(0xFFFFEE00);
}

class PurpleColor extends ArrowColor {
  @override
  String get name => 'PURPLE';
  @override
  Color get hex => const Color(0xFFB026FF);
}

/// ArrowColorFactory — Factory Method (GoF, creational). Twin of
/// DirectionFactory: turns the backend's color label into the matching
/// ArrowColor strategy instance. Callers depend only on the abstract
/// ArrowColor return type, so adding a color means editing one method.
///
/// Unknown labels are rejected fast with FormatException so a stale
/// seed or a typo cannot silently produce the wrong tint.
class ArrowColorFactory {
  static ArrowColor fromLabel(String label) {
    switch (label.toUpperCase()) {
      case 'PINK':
        return PinkColor();
      case 'GREEN':
        return GreenColor();
      case 'BLUE':
        return BlueColor();
      case 'YELLOW':
        return YellowColor();
      case 'PURPLE':
        return PurpleColor();
      default:
        throw FormatException('Unknown arrow color: "$label"');
    }
  }
}