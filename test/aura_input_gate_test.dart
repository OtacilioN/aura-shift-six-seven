import 'package:aura_shift_six_seven/game/aura_input_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts at most eight contacts in any rolling second', () {
    final gate = AuraInputGate();
    expect(maxAuraContactsPerSecond, 8);

    for (var pointer = 0; pointer < 8; pointer++) {
      expect(gate.pointerDown(pointer, 900 + pointer), isTrue);
      gate.pointerUp(pointer);
    }

    expect(gate.pointerDown(8, 1000), isFalse);
    gate.pointerUp(8);
    expect(gate.pointerDown(9, 1899), isFalse);
    gate.pointerUp(9);
    expect(gate.pointerDown(10, 1900), isTrue);
  });

  test('ignores every additional finger until all contacts are released', () {
    final gate = AuraInputGate();

    expect(gate.pointerDown(1, 0), isTrue);
    expect(gate.pointerDown(2, 1), isFalse);

    gate.pointerUp(1);
    expect(gate.pointerDown(3, 2), isFalse);

    gate.pointerUp(2);
    gate.pointerUp(3);
    expect(gate.pointerDown(4, 3), isTrue);
  });

  test('touch and accessibility actions share the same rate budget', () {
    final gate = AuraInputGate();

    for (var action = 0; action < 7; action++) {
      expect(gate.accessibilityAction(action), isTrue);
    }
    expect(gate.pointerDown(1, 7), isTrue);
    gate.pointerUp(1);
    expect(gate.accessibilityAction(8), isFalse);
    expect(gate.accessibilityAction(1000), isTrue);
  });
}
