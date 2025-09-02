import 'dart:convert';
import 'package:flutter/foundation.dart';

Map<String, dynamic>? parseMatchupResponse(String rawResponse) {
  try {
    String cleaned = rawResponse.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    return jsonDecode(cleaned) as Map<String, dynamic>;
  } catch (e) {
    final preview = rawResponse.replaceAll('\n', ' ');
    final short = preview.length > 240 ? preview.substring(0, 240) + '…' : preview;
    debugPrint('[Parse][JSON] Failed to parse: $e | raw: $short');
    return null;
  }
}
