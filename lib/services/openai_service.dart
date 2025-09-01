import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// New modular imports
import '../clients/openai_client.dart';
import '../clients/firebase_storage_client.dart';
import '../storage/local_storage.dart';
import '../repositories/matchup_repository.dart';
import '../utils/response_parser.dart' as rp;
import '../utils/response_formatter.dart' as rf;
import '../data/spell_mapping_loader.dart';
import '../utils/path_resolver.dart';

class OpenAIService extends ChangeNotifier {
  bool _isLoading = false;
  String? _lastResponse;
  String? _error;
  Map<String, dynamic>? _lastParsedResponse;
  Map<String, dynamic>? _spellMapping;
  PathResolver? _pathResolver;
  MatchupRepository? _repo;

  bool get isLoading => _isLoading;
  String? get lastResponse => _lastResponse;
  String? get error => _error;
  Map<String, dynamic>? get lastParsedResponse => _lastParsedResponse;

  OpenAIService() {
    // Initialize dependencies
    _repo = MatchupRepository(
      client: OpenAIClient(dotenv.env['OPENAI_API_KEY'] ?? ''),
      remote: const FirebaseStorageClient(),
      local: const LocalStorage(),
    );
    _loadSpellMapping();
  }

  Future<void> _loadSpellMapping() async {
    final loader = SpellMappingLoader();
    _spellMapping = await loader.load();
    _pathResolver = PathResolver(_spellMapping);
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
      // Delegate to repository: it handles cache (Firebase/local) and network
      // Ensure repo uses the latest API key
      _repo = MatchupRepository(
        client: OpenAIClient(apiKey),
        remote: const FirebaseStorageClient(),
        local: const LocalStorage(),
      );

      final (raw, parsed) = await _repo!.getAdvice(
        champion: champion,
        opponent: opponent,
        lane: lane,
        apiKey: apiKey,
      );

      _lastParsedResponse = parsed ?? rp.parseMatchupResponse(raw);
      _lastResponse = rf.formatMatchupResponse(raw);
      return _lastResponse;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('Rate limit reached')) {
        _error = 'Limite atteinte : vous avez atteint 5 requêtes par heure sur mobile. Réessayez un peu plus tard.';
      } else {
        _error = 'Une erreur est survenue lors de la génération du conseil : $e';
      }
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String getSpellImagePath(String championName, String spellName, [String? touche]) {
    final resolver = _pathResolver ?? PathResolver(_spellMapping);
    return resolver.spellImagePath(championName, spellName, touche);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
