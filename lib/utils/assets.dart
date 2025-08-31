import 'package:flutter/foundation.dart';

String championIconPath(String championName) {
  final dir = _championDirOverride(championName) ?? _normalizeChampionDir(championName);
  final path = 'assets/lol_champion_images/$dir/icon.jpg';
  if (kDebugMode) {
    // Log the exact path being requested for easier debugging
    // ignore: avoid_print
    print('🖼️ [ASSETS] Champion icon path for "$championName" => $path');
  }
  return path;
}

String _normalizeChampionDir(String name) {
  return name
      .toLowerCase()
      .replaceAll(' ', '')
      .replaceAll("'", '')
      .replaceAll('.', '')
      .replaceAll('&', '');
}

String? _championDirOverride(String name) {
  const overrides = {
    'Wukong': 'monkeyking',
    'Renata Glasc': 'renata',
    'Nunu & Willump': 'nunu',
  };
  return overrides[name];
}
