import 'package:aura_shift_six_seven/game/aura_input_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts at most thirteen contacts in any rolling second', () {
    final gate = AuraInputGate();
    expect(maxAuraContactsPerSecond, 13);

    for (var pointer = 0; pointer < 13; pointer++) {
      expect(gate.pointerDown(pointer, 900 + pointer), isTrue);
      gate.pointerUp(pointer);
    }

    expect(gate.pointerDown(13, 1000), isFalse);
    gate.pointerUp(13);
    expect(gate.pointerDown(14, 1899), isFalse);
    gate.pointerUp(14);
    expect(gate.pointerDown(15, 1900), isTrue);
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

    for (var action = 0; action < 12; action++) {
      expect(gate.accessibilityAction(action), isTrue);
    }
    expect(gate.pointerDown(1, 12), isTrue);
    gate.pointerUp(1);
    expect(gate.accessibilityAction(13), isFalse);
    expect(gate.accessibilityAction(1000), isTrue);
  });
}
