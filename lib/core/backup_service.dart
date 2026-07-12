import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'game_controller.dart';

/// Portable, integrity-checked manual backup. This resists accidental corruption,
/// not deliberate modification (the game has no account or server authority).
class BackupService {
  static const _format = 'aura-shift-backup-v1';

  static String wrap(GameController controller) {
    final payload = controller.exportState();
    return jsonEncode({
      'format': _format,
      'payload': payload,
      'sha256': sha256.convert(utf8.encode(payload)).toString()
    });
  }

  static String? unpack(String raw) {
    try {
      final envelope = jsonDecode(raw) as Map<String, dynamic>;
      final payload = envelope['payload'] as String;
      if (envelope['format'] != _format ||
          envelope['sha256'] !=
              sha256.convert(utf8.encode(payload)).toString()) {
        return null;
      }
      return payload;
    } catch (_) {
      return null;
    }
  }

  static Future<void> exportAndShare(GameController controller) async {
    final directory = await getTemporaryDirectory();
    final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
    final file = File('${directory.path}/aura-shift-$stamp.as67');
    await file.writeAsString(wrap(controller), flush: true);
    await Share.shareXFiles([XFile(file.path)], subject: 'Aura Shift backup');
  }

  static Future<String?> pickPayload() async {
    const backupTypes = XTypeGroup(
      label: 'Aura Shift backup',
      extensions: ['as67', 'json'],
    );
    final file = await openFile(acceptedTypeGroups: [backupTypes]);
    if (file == null) return null;
    return unpack(await file.readAsString());
  }
}
