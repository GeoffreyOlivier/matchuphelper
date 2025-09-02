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
      // On any error (including 404), return null to signal missing/unreadable file.
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
    } on FirebaseException catch (e) {
      // If the file doesn't exist, treat as success.
      if (e.code == 'object-not-found') {
        return;
      }
      // For other storage errors, rethrow to let callers decide.
      rethrow;
    }
  }
}
