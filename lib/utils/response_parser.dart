import 'dart:convert';

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
  } catch (_) {
    return null;
  }
}
