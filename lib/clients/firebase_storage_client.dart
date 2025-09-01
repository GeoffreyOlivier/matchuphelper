import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageClient {
  const FirebaseStorageClient();

  Future<String?> readText(String remotePath, {int maxSize = 1024 * 1024}) async {
    try {
      final ref = FirebaseStorage.instance.ref(remotePath);
      final Uint8List? data = await ref.getData(maxSize);
      if (data == null) return null;
      return String.fromCharCodes(data);
    } catch (_) {
      return null;
    }
  }

  Future<void> writeText(String remotePath, String content, {String? contentType}) async {
    final ref = FirebaseStorage.instance.ref(remotePath);
    final metadata = SettableMetadata(contentType: contentType);
    await ref.putString(content, format: PutStringFormat.raw, metadata: metadata);
  }

  Future<void> deleteFile(String remotePath) async {
    try {
      final ref = FirebaseStorage.instance.ref(remotePath);
      await ref.delete();
    } catch (e) {
      // File might not exist, ignore error
      throw Exception('Failed to delete file: $e');
    }
  }
}
