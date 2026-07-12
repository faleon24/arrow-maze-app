import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrow_maze_app/domain/models/arrow_color.dart';

void main() {
  group('ArrowColor subclasses', () {
    test('should_expose_backend_label_and_neon_hex_when_constructed', () {
      expect(PinkColor().name, 'PINK');
      expect(PinkColor().hex, const Color(0xFFFF3EA5));

      expect(GreenColor().name, 'GREEN');
      expect(GreenColor().hex, const Color(0xFF39FF14));

      expect(BlueColor().name, 'BLUE');
      expect(BlueColor().hex, const Color(0xFF00E0FF));

      expect(YellowColor().name, 'YELLOW');
      expect(YellowColor().hex, const Color(0xFFFFEE00));

      expect(PurpleColor().name, 'PURPLE');
      expect(PurpleColor().hex, const Color(0xFFB026FF));
    });
  });

  group('ArrowColorFactory.fromLabel', () {
    test('should_return_matching_subclass_when_label_is_known', () {
      expect(ArrowColorFactory.fromLabel('PINK'), isA<PinkColor>());
      expect(ArrowColorFactory.fromLabel('GREEN'), isA<GreenColor>());
      expect(ArrowColorFactory.fromLabel('BLUE'), isA<BlueColor>());
      expect(ArrowColorFactory.fromLabel('YELLOW'), isA<YellowColor>());
      expect(ArrowColorFactory.fromLabel('PURPLE'), isA<PurpleColor>());
    });

    test('should_normalize_case_when_matching_labels', () {
      expect(ArrowColorFactory.fromLabel('pink'), isA<PinkColor>());
      expect(ArrowColorFactory.fromLabel('Green'), isA<GreenColor>());
    });

    test('should_throw_format_exception_when_label_is_unknown', () {
      expect(
        () => ArrowColorFactory.fromLabel('ORANGE'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}