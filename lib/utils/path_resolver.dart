class PathResolver {
  final Map<String, dynamic>? spellMapping;
  const PathResolver(this.spellMapping);

  String spellImagePath(String championName, String spellName, [String? touche]) {
    // Mapping based
    final normalizedChampionKey = championName
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll("'", '')
        .replaceAll('.', '')
        .replaceAll('&', '');
    if (spellMapping != null && spellMapping![normalizedChampionKey] != null) {
      final championSpells = spellMapping![normalizedChampionKey] as Map<String, dynamic>;

      String? mappingKeyFromTouche;
      if (touche != null) {
        final t = touche.trim().toUpperCase();
        if (t == 'Q' || t == 'W' || t == 'E' || t == 'R') {
          mappingKeyFromTouche = t;
        } else if (t == 'P' || t.toLowerCase().startsWith('p') || t.toLowerCase() == 'passive') {
          mappingKeyFromTouche = 'Passive';
        }
      }

      String? mappingKey = mappingKeyFromTouche;
      if (mappingKey == null) {
        final s = spellName.trim();
        final su = s.toUpperCase();
        if (su == 'Q' || su == 'W' || su == 'E' || su == 'R') {
          mappingKey = su;
        } else if (s.toLowerCase() == 'passive') {
          mappingKey = 'Passive';
        }
      }

      String? imageFileName;
      if (mappingKey != null) {
        if (mappingKey == 'Passive') {
          imageFileName = 'passive.png';
        } else {
          imageFileName = championSpells[mappingKey] as String?;
        }
      } else {
        final lower = spellName.toLowerCase();
        for (final k in championSpells.keys) {
          if (k.toLowerCase() == lower) {
            imageFileName = championSpells[k] as String?;
            break;
          }
        }
        if (imageFileName == null && lower == 'passive') {
          imageFileName = 'passive.png';
        }
      }

      if (imageFileName != null) {
        final dirChampion = _championDirOverride(championName) ?? championName
            .toLowerCase()
            .replaceAll(' ', '')
            .replaceAll("'", '')
            .replaceAll('.', '')
            .replaceAll('&', '');
        return 'assets/lol_champion_images/$dirChampion/$imageFileName';
      }
    }

    // Fallback generic
    final dirChampion = _championDirOverride(championName) ?? normalizedChampionKey;

    String suffix = 'Q';
    bool isPassive = false;
    if (touche != null) {
      final t = touche.trim().toUpperCase();
      if (t == 'Q' || t == 'W' || t == 'E' || t == 'R') {
        suffix = t;
      } else if (t == 'P' || t.startsWith('P') || t.toLowerCase() == 'passive') {
        isPassive = true;
      }
    }

    // Build CamelCase champion part used in many spell filenames, e.g., "XinZhao"
    String championForFile = championName
        .split(RegExp(r"[ '\.&]+"))
        .where((p) => p.isNotEmpty)
        .map((p) => p.substring(0, 1).toUpperCase() + (p.length > 1 ? p.substring(1) : ''))
        .join();

    return isPassive
        ? 'assets/lol_champion_images/$dirChampion/passive.png'
        : 'assets/lol_champion_images/$dirChampion/spell_$championForFile$suffix.png';
  }

  String? _championDirOverride(String name) {
    const overrides = {
      'Wukong': 'monkeyking',
      'Renata Glasc': 'renata',
      'Nunu & Willump': 'nunu',
    };
    return overrides[name];
  }
}
