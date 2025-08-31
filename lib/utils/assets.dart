String championIconPath(String championName) {
  final dir = _championDirOverride(championName) ?? _normalizeChampionDir(championName);
  final path = 'assets/lol_champion_images/$dir/icon.jpg';
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
