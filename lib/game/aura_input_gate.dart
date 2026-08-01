import 'dart:collection';

/// Maximum number of accepted Six/Seven contacts in any rolling second.
const maxAuraContactsPerSecond = 13;

/// Deterministic input gate shared by direct touch and accessibility actions.
///
/// Physical input is single-contact: once a pointer is down, every additional
/// pointer is ignored until all contacts have been released. Accepted contacts
/// are also limited by a rolling window so a boundary between clock seconds
/// cannot admit two bursts.
class AuraInputGate {
  AuraInputGate({
    this.maxContactsPerSecond = maxAuraContactsPerSecond,
    this.windowMilliseconds = 1000,
  })  : assert(maxContactsPerSecond > 0),
        assert(windowMilliseconds > 0);

  final int maxContactsPerSecond;
  final int windowMilliseconds;

  final ListQueue<int> _acceptedAt = ListQueue<int>();
  final Set<int> _pointersDown = <int>{};

  bool pointerDown(int pointerId, int nowMilliseconds) {
    final hadActivePointer = _pointersDown.isNotEmpty;
    final isNewPointer = _pointersDown.add(pointerId);
    if (hadActivePointer || !isNewPointer) return false;
    return _acceptAt(nowMilliseconds);
  }

  void pointerUp(int pointerId) => _pointersDown.remove(pointerId);

  bool accessibilityAction(int nowMilliseconds) => _acceptAt(nowMilliseconds);

  bool _acceptAt(int nowMilliseconds) {
    while (_acceptedAt.isNotEmpty &&
        nowMilliseconds - _acceptedAt.first >= windowMilliseconds) {
      _acceptedAt.removeFirst();
    }
    if (_acceptedAt.length >= maxContactsPerSecond) return false;
    _acceptedAt.addLast(nowMilliseconds);
    return true;
  }
}
