import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const root = 'docs/play-games/game-stats';

  test('Game Stats CSV files use the documented column counts', () {
    final expected = {
      'PlayerGameEvent.csv': 3,
      'RepetitiveStatsConfig.csv': 16,
      'ProgressionStatConfig.csv': 6,
      'StatLocalizations.csv': 5,
    };
    for (final entry in expected.entries) {
      final lines = File('$root/${entry.key}')
          .readAsLinesSync()
          .where((line) => line.trim().isNotEmpty);
      expect(lines, isNotEmpty, reason: entry.key);
      for (final line in lines) {
        expect(
          line.split(','),
          hasLength(entry.value),
          reason: '${entry.key}: $line',
        );
      }
    }
  });

  test('all six Game Stats icons are 512 x 512 PNG files', () {
    const names = [
      'aura_level.png',
      'aura_total.png',
      'manual_movements.png',
      'aura_production.png',
      'prestiges.png',
      'items_unlocked.png',
    ];
    for (final name in names) {
      final bytes = File('$root/icons/$name').readAsBytesSync();
      expect(
        bytes.sublist(0, 8),
        orderedEquals([137, 80, 78, 71, 13, 10, 26, 10]),
        reason: name,
      );
      final data = ByteData.sublistView(Uint8List.fromList(bytes));
      expect(data.getUint32(16), 512, reason: '$name width');
      expect(data.getUint32(20), 512, reason: '$name height');
    }
  });
}
