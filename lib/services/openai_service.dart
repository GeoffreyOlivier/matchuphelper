import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';

class OpenAIService extends ChangeNotifier {
  bool _isLoading = false;
  String? _lastResponse;
  String? _error;
  Map<String, dynamic>? _lastParsedResponse;
  Map<String, dynamic>? _spellMapping;

  bool get isLoading => _isLoading;
  String? get lastResponse => _lastResponse;
  String? get error => _error;
  Map<String, dynamic>? get lastParsedResponse => _lastParsedResponse;

  OpenAIService() {
    _loadSpellMapping();
  }

  Future<void> _uploadTextToFirebase(String remotePath, String content, {String? contentType}) async {
    final ref = FirebaseStorage.instance.ref(remotePath);
    final metadata = SettableMetadata(contentType: contentType);
    await ref.putString(content, format: PutStringFormat.raw, metadata: metadata);
  }

  Future<void> _loadSpellMapping() async {
    try {
      
      final String jsonString = await rootBundle.loadString('data/spellmap_global.json');
      _spellMapping = jsonDecode(jsonString);
    } catch (e) {
      
      // Essayer d'autres chemins
      List<String> alternativePaths = [
        'assets/data/spellmap_global.json',
        'spellmap_global.json',
        'lol_matchup_helper/data/spellmap_global.json'
      ];
      
      bool loaded = false;
      for (String path in alternativePaths) {
        try {
          final String jsonString = await rootBundle.loadString(path);
          _spellMapping = jsonDecode(jsonString);
          loaded = true;
          break;
        } catch (e2) {
        }
      }
      
      if (!loaded) {
        _spellMapping = null;
      }
    }
  }

  /// Sauvegarde la réponse brute (non parsée), utile si le JSON échoue
  Future<void> _saveRawResponseToFile(String champion, String opponent, String raw) async {
    try {
      String fileName = _generateFileName(champion, opponent).replaceAll('.json', '_raw.txt');
      Directory appDir = await getApplicationDocumentsDirectory();
      String appResponsesDir = path.join(appDir.path, 'chatgpt_responses');
      await Directory(appResponsesDir).create(recursive: true);
      String appFilePath = path.join(appResponsesDir, fileName);
      await File(appFilePath).writeAsString(raw);

      // Upload vers Firebase Storage (RAW)
      if (Firebase.apps.isNotEmpty) {
        try {
          final remotePath = 'chatgpt_responses/$fileName';
          await _uploadTextToFirebase(remotePath, raw, contentType: 'text/plain');
        } catch (e) {
        }
      } else {
      }

      // Mirror on desktop in debug
      try {
        final bool isDesktop = Platform.isMacOS || Platform.isLinux || Platform.isWindows;
        if (kDebugMode && isDesktop) {
          String projectResponsesDir = 'data/chatgpt_responses';
          await Directory(projectResponsesDir).create(recursive: true);
          String projFilePath = path.join(projectResponsesDir, fileName);
          await File(projFilePath).writeAsString(raw);
        }
      } catch (_) {}
    } catch (e) {
    }
  }

  Future<String?> getMatchupAdvice(
      String champion, String opponent, String lane) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      _error = 'OpenAI API key not found';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 0) If a previous response exists in Firebase Storage, use it instead of calling the API
      if (Firebase.apps.isNotEmpty) {
        try {
          final fileName = _generateFileName(champion, opponent);
          final ref = FirebaseStorage.instance.ref('chatgpt_responses/$fileName');
          final data = await ref.getData(1024 * 1024); // up to 1MB
          if (data != null) {
            final cachedJson = utf8.decode(data);
            // Set parsed response and formatted output
            _lastParsedResponse = _parseMatchupResponse(cachedJson);
            _lastResponse = _formatMatchupResponse(cachedJson);
            return _lastResponse;
          }
        } catch (_) {
          // ignore and fall back to API
        }
      }

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': [
            {
              'role': 'system',
              'content': 'Tu es coach sur League of Legends (patch 25.X). Réponds toujours de façon structurée et concise sans traduire les termes anglais, sans dépasser 800 tokens. Respecte **strictement** cette structure de réponse :\n\n{\n  "matchup": "$champion vs $opponent sur la lane $lane",\n  "kit_de_$opponent": [\n    {\n      "nom": "Nom du sort",\n      "touche": "Q / W / E / R / Passive",\n      "description": "Effet du sort",\n      "si_danger_pour_$champion": "Pourquoi ce sort est dangereux"\n    }\n  ],\n  "style_de_jeu_conseillé": {\n    "early": "Conseil pour les premiers niveaux",\n    "mid_game": "Conseil vers le niveau 6",\n    "late_game": "Conseil si la partie dure"\n  }\n}\nRéponds uniquement sous cette forme.'
            },
            {
              'role': 'user',
              'content': 'Je joue $champion contre $opponent sur la lane $lane.'
            },
          ],
          'temperature': 0.7,
          'max_tokens': 800,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawResponse = data['choices'][0]['message']['content'];
        
        // Parser la réponse JSON et la stocker
        _lastParsedResponse = _parseMatchupResponse(rawResponse);
        
        // Sauvegarder la réponse (JSON parsé si possible, sinon brut)

        // Toujours sauvegarder la réponse brute pour debug
        await _saveRawResponseToFile(champion, opponent, rawResponse);

        // Et sauvegarder le JSON parsé si disponible
        if (_lastParsedResponse != null) {
          await _saveResponseToFile(champion, opponent, _lastParsedResponse!);
        } else {
        }
        
        _lastResponse = _formatMatchupResponse(rawResponse);
        return _lastResponse;
      } else {
        _error = 'Error: ${response.statusCode} - ${response.body}';
        return null;
      }
    } catch (e) {
      _error = 'Failed to get matchup advice: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Map<String, dynamic>? _parseMatchupResponse(String rawResponse) {
    try {
      String cleanedResponse = rawResponse.trim();
      if (cleanedResponse.startsWith('```json')) {
        cleanedResponse = cleanedResponse.substring(7);
      }
      if (cleanedResponse.endsWith('```')) {
        cleanedResponse = cleanedResponse.substring(0, cleanedResponse.length - 3);
      }
      return jsonDecode(cleanedResponse);
    } catch (e) {
      return null;
    }
  }

  String getSpellImagePath(String championName, String spellName, [String? touche]) {
    
    
    // Utiliser le mapping JSON si disponible
    if (_spellMapping != null && _spellMapping![championName.toLowerCase()] != null) {
      final championSpells = _spellMapping![championName.toLowerCase()] as Map<String, dynamic>;

      // 1) Priorité: la touche (Q/W/E/R/Passive)
      String? mappingKeyFromTouche;
      if (touche != null) {
        final t = touche.trim().toUpperCase();
        if (t == 'Q' || t == 'W' || t == 'E' || t == 'R') {
          mappingKeyFromTouche = t; // clés exactement 'Q','W','E','R'
        } else if (t == 'P' || t.startsWith('P')) {
          mappingKeyFromTouche = 'Passive';
        } else if (t.toLowerCase() == 'passive') {
          mappingKeyFromTouche = 'Passive';
        }
      }

      // 2) Si pas de touche exploitable, essayer de déduire depuis spellName s'il vaut déjà Q/W/E/R/Passive
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
        // Si passif, on force le nom de fichier à passive.png
        if (mappingKey == 'Passive') {
          imageFileName = 'passive.png';
        } else {
          imageFileName = championSpells[mappingKey] as String?;
        }
      } else {
        // 3) Dernière chance: compatibilité avec anciens prompts → recherche insensible à la casse sur l'intitulé complet (rare désormais)
        final lower = spellName.toLowerCase();
        for (final k in championSpells.keys) {
          if (k.toLowerCase() == lower) {
            imageFileName = championSpells[k] as String?;
            break;
          }
        }
        // Si le nom du sort est littéralement "passive", on force aussi
        if (imageFileName == null && lower == 'passive') {
          imageFileName = 'passive.png';
        }
      }

      if (imageFileName != null) {
        // Dossier champion: minuscule, sans espaces/apostrophes/points/& et overrides éventuels
        final dirChampion = _championDirOverride(championName) ?? championName
            .toLowerCase()
            .replaceAll(' ', '')
            .replaceAll('\'', '')
            .replaceAll('.', '')
            .replaceAll('&', '');
        final finalPath = 'assets/lol_champion_images/$dirChampion/$imageFileName';
        return finalPath;
      }
    }
    
    // Fallback générique basé sur la touche (Q/W/E/R). Eviter les règles spécifiques à un champion.
    final dirChampion = _championDirOverride(championName) ?? championName
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('\'', '')
        .replaceAll('.', '')
        .replaceAll('&', '');
    // Déterminer le suffixe à partir de la touche fournie, sinon défaut Q
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
    // Capitaliser la première lettre du champion pour le nom de fichier
    String championForFile = championName.substring(0, 1).toUpperCase() + 
                            championName.substring(1).toLowerCase().replaceAll(' ', '');
    // Aligner avec pubspec.yaml: préfixe "assets/" et dossier champion capitalisé
    final fallbackPath = isPassive
        ? 'assets/lol_champion_images/$dirChampion/passive.png'
        : 'assets/lol_champion_images/$dirChampion/spell_${championForFile}${suffix}.png';
    return fallbackPath;
  }

  // Keep the override helper in this service as well
  String? _championDirOverride(String name) {
    const overrides = {
      'Wukong': 'monkeyking',
      'Renata Glasc': 'renata',
      'Nunu & Willump': 'nunu',
    };
    return overrides[name];
  }

  String _formatMatchupResponse(String rawResponse) {
    try {
      final jsonData = _parseMatchupResponse(rawResponse);
      if (jsonData == null) return rawResponse;
      
      StringBuffer formatted = StringBuffer();
      
      // Titre du matchup
      formatted.writeln('🎯 ${jsonData['matchup']}\n');
      
      // Kit de l'adversaire
      formatted.writeln('⚔️ KIT DE L\'ADVERSAIRE');
      formatted.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      // Extraire le nom de l'adversaire
      String opponent = jsonData['matchup'].split(' vs ')[1].split(' ')[0];
      String kitKey = 'kit_de_$opponent';
      
      if (jsonData[kitKey] != null) {
        final kit = jsonData[kitKey];
        for (var spell in kit) {
          formatted.writeln('🔸 ${spell['nom']} (${spell['touche']})');
          formatted.writeln('   ${spell['description']}');
          formatted.writeln('   ⚠️ ${spell['si_danger_pour_${jsonData['matchup'].split(' vs ')[0]}']}');
          formatted.writeln('');
        }
      }
      
      // Style de jeu conseillé
      formatted.writeln('📋 STYLE DE JEU CONSEILLÉ');
      formatted.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      final style = jsonData['style_de_jeu_conseillé'];
      formatted.writeln('🌅 EARLY GAME');
      formatted.writeln('   ${style['early']}\n');
      
      formatted.writeln('⚡ MID GAME');
      formatted.writeln('   ${style['mid_game']}\n');
      
      formatted.writeln('🏆 LATE GAME');
      formatted.writeln('   ${style['late_game']}');
      
      return formatted.toString();
      
    } catch (e) {
      return rawResponse;
    }
  }

  /// Génère le nom de fichier au format champion1_champion2.json
  String _generateFileName(String champion1, String champion2) {
    // Nettoyer les noms de champions (enlever espaces, caractères spéciaux)
    String cleanChampion1 = champion1.toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('&', 'and')
        .replaceAll('.', '')
        .replaceAll('\'', '');
    String cleanChampion2 = champion2.toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('&', 'and')
        .replaceAll('.', '')
        .replaceAll('\'', '');
    
    return '${cleanChampion1}_${cleanChampion2}.json';
  }

  /// Sauvegarde la réponse JSON dans le dossier data/chatgpt_responses/
  Future<void> _saveResponseToFile(String champion, String opponent, Map<String, dynamic> response) async {
    
    try {
      // Générer le nom de fichier
      String fileName = _generateFileName(champion, opponent);

      // 1) Écriture dans Documents de l'application (toutes plateformes)
      Directory appDir = await getApplicationDocumentsDirectory();
      String appResponsesDir = path.join(appDir.path, 'chatgpt_responses');
      Directory dirApp = Directory(appResponsesDir);
      if (!await dirApp.exists()) {
        await dirApp.create(recursive: true);
      }
      String appFilePath = path.join(appResponsesDir, fileName);
      
      // Ajouter un timestamp à la réponse
      Map<String, dynamic> responseWithTimestamp = {
        ...response,
        'timestamp': DateTime.now().toIso8601String(),
        'champion': champion,
        'opponent': opponent,
      };
      
      // Écrire le fichier JSON (Documents app)
      String jsonContent = jsonEncode(responseWithTimestamp);
      File appFile = File(appFilePath);
      await appFile.writeAsString(jsonContent);
      bool fileExistsApp = await appFile.exists();
      int fileSizeApp = fileExistsApp ? await appFile.length() : 0;

      // Upload vers Firebase Storage (JSON)
      if (Firebase.apps.isNotEmpty) {
        try {
          final remotePath = 'chatgpt_responses/$fileName';
          await _uploadTextToFirebase(remotePath, jsonContent, contentType: 'application/json');
        } catch (e) {
        }
      } else {
      }

      // 2) En debug desktop seulement: écriture miroir dans le dossier du projet
      try {
        final bool isDesktop = Platform.isMacOS || Platform.isLinux || Platform.isWindows;
        if (kDebugMode && isDesktop) {
          String projectResponsesDir = 'data/chatgpt_responses';
          Directory dirProj = Directory(projectResponsesDir);
          if (!await dirProj.exists()) {
            await dirProj.create(recursive: true);
          }
          String projFilePath = path.join(projectResponsesDir, fileName);
          await File(projFilePath).writeAsString(jsonContent);
        }
      } catch (e) {
      }
      
    } catch (e, stackTrace) {
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
