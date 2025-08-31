import 'dart:convert';
import 'package:flutter/services.dart';

class SpellMappingLoader {
  Future<Map<String, dynamic>?> load() async {
    try {
      final String jsonString = await rootBundle.loadString('data/spellmap_global.json');
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (_) {
      for (final alt in const [
        'assets/data/spellmap_global.json',
        'spellmap_global.json',
        'lol_matchup_helper/data/spellmap_global.json',
      ]) {
        try {
          final String jsonString = await rootBundle.loadString(alt);
          return jsonDecode(jsonString) as Map<String, dynamic>;
        } catch (_) {}
      }
      return null;
    }
  }
}
