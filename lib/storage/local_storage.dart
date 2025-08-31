import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class LocalStorage {
  const LocalStorage();

  Future<String> _responsesDir() async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'chatgpt_responses'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  Future<String?> readText(String fileName) async {
    try {
      final dir = await _responsesDir();
      final file = File(p.join(dir, fileName));
      if (!await file.exists()) return null;
      return await file.readAsString();
    } catch (_) {
      return null;
    }
  }

  Future<void> writeText(String fileName, String content) async {
    final dir = await _responsesDir();
    final file = File(p.join(dir, fileName));
    await file.writeAsString(content);
  }
}
