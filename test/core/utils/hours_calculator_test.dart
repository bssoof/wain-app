import 'package:flutter_test/flutter_test.dart';
import 'package:wain_app/core/utils/hours_calculator.dart';

class _Slot {
  final String open;
  final String close;
  final bool spansMidnight;

  const _Slot({
    required this.open,
    required this.close,
    required this.spansMidnight,
  });
}

void main() {
  group('isOpenNowFromSlots', () {
    test('returns true for 24h venues', () {
      final isOpen = isOpenNowFromSlots<_Slot>(
        hours: const {},
        is24Hours: true,
        openOf: (slot) => slot.open,
        closeOf: (slot) => slot.close,
        spansMidnightOf: (slot) => slot.spansMidnight,
      );

      expect(isOpen, isTrue);
    });

    test('returns null when hours are empty and not 24h', () {
      final isOpen = isOpenNowFromSlots<_Slot>(
        hours: const {},
        is24Hours: false,
        openOf: (slot) => slot.open,
        closeOf: (slot) => slot.close,
        spansMidnightOf: (slot) => slot.spansMidnight,
      );

      expect(isOpen, isNull);
    });

    test('returns true during same-day slot', () {
      final isOpen = isOpenNowFromSlots<_Slot>(
        hours: const {
          'monday': [
            _Slot(open: '09:00', close: '18:00', spansMidnight: false),
          ],
        },
        is24Hours: false,
        now: DateTime(2026, 2, 16, 14),
        openOf: (slot) => slot.open,
        closeOf: (slot) => slot.close,
        spansMidnightOf: (slot) => slot.spansMidnight,
      );

      expect(isOpen, isTrue);
    });

    test('handles overnight carry-over from previous day', () {
      final isOpen = isOpenNowFromSlots<_Slot>(
        hours: const {
          'monday': [_Slot(open: '22:00', close: '03:00', spansMidnight: true)],
        },
        is24Hours: false,
        now: DateTime(2026, 2, 17, 1),
        openOf: (slot) => slot.open,
        closeOf: (slot) => slot.close,
        spansMidnightOf: (slot) => slot.spansMidnight,
      );

      expect(isOpen, isTrue);
    });
  });
}
