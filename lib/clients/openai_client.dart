import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class OpenAIClient {
  OpenAIClient(this.apiKey);
  final String apiKey;

  Future<String> getMatchupRaw({
    required String champion,
    required String opponent,
    required String lane,
  }) async {
    final sw = Stopwatch()..start();
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4.1',
        // Optionnel mais utile pour forcer du JSON valide
        'response_format': {'type': 'json_object'},
        'messages': [
          {
            'role': 'system',
            'content': """
Tu es coach sur League of Legends (patch 25.X). Réponds uniquement en JSON strict, concis, sans traduire les termes anglais, ≤ 800 tokens.

Règles générales :
- Liste toutes les compétences de $opponent, mais ajoute une "consigne" uniquement si le sort est réellement menaçant pour $champion sur la lane $lane.
- Si un sort est peu dangereux/situationnel, n'inclus pas le champ "consigne".
- Les consignes sont opérationnelles (verbes d'action), 1 phrase max.
- Pas de texte hors JSON.
 - Toutes les sections doivent être spécifiques à la lane "$lane" (top/jungle/mid/bot/support). Si le matchup change selon la lane, adapte les conseils.

Structure de sortie attendue :
{
  "matchup": "$champion vs $opponent sur la lane $lane",
  "lane": "$lane",
  "kit_de_$opponent": [
    {
      "nom": "Nom du sort",
      "touche": "Passive | Q | W | E | R",
      "effet_court": "Effet très concis (1 phrase max).",
      "consigne": "Action concrète si stun, cc, knock up . Omettre ce champ si non dangereux."
    }
  ],
  "laning_vs_$opponent": "Dit si il est fort avant le level 3 ou non. Conseils pratiques pour gérer la lane (warding, timings de trade, spacing). Max 3 phrases.",
  "strategie_vs_$opponent": "Conseils hors lane: teamfights, rotations, regroupement, macro. Max 3 phrases.",
  "power_spikes_$opponent": "Niveaux/objets/fenêtres où $opponent est fort et comment les jouer. Max 3 phrases."
}
"""
          },
          {
            'role': 'user',
            'content': 'Je joue $champion contre $opponent sur la lane $lane.'
          },
        ],
        'temperature': 0.3,
        'max_tokens': 800,
      }),
    );
    sw.stop();
    debugPrint('[Perf][OpenAI] HTTP ${sw.elapsedMilliseconds} ms');

    if (response.statusCode != 200) {
      throw Exception('OpenAI error: ${response.statusCode} - ${response.body}');
    }

    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'] as String;
  }
}
