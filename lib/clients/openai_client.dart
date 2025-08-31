import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenAIClient {
  OpenAIClient(this.apiKey);
  final String apiKey;

  Future<String> getMatchupRaw({
    required String champion,
    required String opponent,
    required String lane,
  }) async {
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

    if (response.statusCode != 200) {
      throw Exception('OpenAI error: ${response.statusCode} - ${response.body}');
    }
    final data = jsonDecode(response.body);
    return data['choices'][0]['message']['content'] as String;
  }
}
