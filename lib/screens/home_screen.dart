import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/openai_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedChampion;
  String? _selectedOpponent;
  String? _selectedLane;
  String? _selectedLetter;
  bool _selectingForChampion = true; // true = selecting for champion, false = selecting for opponent
  
  final List<String> _lanes = [
    'Top',
    'Jungle',
    'Mid',
    'Bot',
    'Support'
  ];

  // This would typically come from a real API
  final List<String> _champions = [
    'Aatrox', 'Ahri', 'Akali', 'Akshan', 'Alistar', 'Amumu', 'Anivia', 'Annie',
    'Aphelios', 'Ashe', 'Aurelion Sol', 'Azir', 'Bard', 'Bel\'Veth', 'Blitzcrank',
    'Brand', 'Braum', 'Caitlyn', 'Camille', 'Cassiopeia', 'Cho\'Gath', 'Corki',
    'Darius', 'Diana', 'Dr. Mundo', 'Draven', 'Ekko', 'Elise', 'Evelynn', 'Ezreal',
    'Fiddlesticks', 'Fiora', 'Fizz', 'Galio', 'Gangplank', 'Garen', 'Gnar',
    'Gragas', 'Graves', 'Gwen', 'Hecarim', 'Heimerdinger', 'Illaoi', 'Irelia',
    'Ivern', 'Janna', 'Jarvan IV', 'Jax', 'Jayce', 'Jhin', 'Jinx', 'Kai\'Sa',
    'Kalista', 'Karma', 'Karthus', 'Kassadin', 'Katarina', 'Kayle', 'Kayn',
    'Kennen', 'Kha\'Zix', 'Kindred', 'Kled', 'Kog\'Maw', 'LeBlanc', 'Lee Sin',
    'Leona', 'Lillia', 'Lissandra', 'Lucian', 'Lulu', 'Lux', 'Malphite',
    'Malzahar', 'Maokai', 'Master Yi', 'Miss Fortune', 'Mordekaiser', 'Morgana',
    'Nami', 'Nasus', 'Nautilus', 'Neeko', 'Nidalee', 'Nocturne', 'Nunu & Willump',
    'Olaf', 'Orianna', 'Ornn', 'Pantheon', 'Poppy', 'Pyke', 'Qiyana', 'Quinn',
    'Rakan', 'Rammus', 'Rek\'Sai', 'Rell', 'Renata Glasc', 'Renekton', 'Rengar',
    'Riven', 'Rumble', 'Ryze', 'Samira', 'Sejuani', 'Senna', 'Seraphine',
    'Sett', 'Shaco', 'Shen', 'Shyvana', 'Singed', 'Sion', 'Sivir', 'Skarner',
    'Sona', 'Soraka', 'Swain', 'Sylas', 'Syndra', 'Tahm Kench', 'Taliyah',
    'Talon', 'Taric', 'Teemo', 'Thresh', 'Tristana', 'Trundle', 'Tryndamere',
    'Twisted Fate', 'Twitch', 'Udyr', 'Urgot', 'Varus', 'Vayne', 'Veigar',
    'Vel\'Koz', 'Vex', 'Vi', 'Viego', 'Viktor', 'Vladimir', 'Volibear',
    'Warwick', 'Wukong', 'Xayah', 'Xerath', 'Xin Zhao', 'Yasuo', 'Yone',
    'Yorick', 'Yuumi', 'Zac', 'Zed', 'Zeri', 'Ziggs', 'Zilean', 'Zoe', 'Zyra'
  ];

  List<String> get _filteredChampions {
    if (_selectedLetter == null) return [];
    return _champions
        .where((champion) => champion.toLowerCase().startsWith(_selectedLetter!.toLowerCase()))
        .toList();
  }

  void _selectChampion(String champion) {
    setState(() {
      if (_selectingForChampion) {
        _selectedChampion = champion;
        _selectingForChampion = false;
      } else {
        _selectedOpponent = champion;
      }
      _selectedLetter = null;
    });
  }

  void _selectLetter(String letter) {
    setState(() {
      _selectedLetter = letter;
    });
  }

  @override
  Widget build(BuildContext context) {
    final openAIService = Provider.of<OpenAIService>(context);
    // Selected highlight color for squares
    const selectedBorderColor = Color(0xFFc2902a);
    // Responsive card size for champion squares (slightly smaller)
    final double screenWidth = MediaQuery.of(context).size.width;
    final double cardSize = (screenWidth * 0.32).clamp(110.0, 140.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LoL Matchup Helper'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Champion Selection Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Your Champion Input (Left)
                  SizedBox(
                    width: cardSize,
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectingForChampion = true;
                              _selectedLetter = null;
                            });
                          },
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Container(
                              padding: EdgeInsets.zero,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                border: Border.all(
                                  // Highlight LEFT when selecting your champion
                                  color: _selectingForChampion
                                      ? selectedBorderColor
                                      : Colors.grey[700]!,
                                  width: _selectingForChampion ? 2 : 1,
                                ),
                                boxShadow: _selectingForChampion
                                    ? [
                                        BoxShadow(
                                          color: selectedBorderColor.withOpacity(0.4),
                                          blurRadius: 6,
                                          spreadRadius: 0.5,
                                        ),
                                      ]
                                    : null,
                                borderRadius: BorderRadius.zero,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.zero,
                                child: _selectedChampion != null
                                    ? Image.asset(
                                        _getChampionIconPath(_selectedChampion!),
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          final failing = _getChampionIconPath(_selectedChampion!);
                                          // Log failing path for debugging
                                          // ignore: avoid_print
                                          print('❌ [HOME_SCREEN] Failed to load selected champion image: ' + failing + ' -> ' + error.toString());
                                          return Center(
                                            child: Icon(
                                              Icons.image_not_supported,
                                              color: Colors.grey[500],
                                              size: 28,
                                            ),
                                          );
                                        },
                                      )
                                    : Center(
                                        child: Text(
                                          '?',
                                          style: TextStyle(
                                            fontSize: 40,
                                            color: Colors.grey[400],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Mon champion',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // VS Image
                  SizedBox(
                    height: cardSize,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.zero,
                        ),
                        child: Image.asset(
                          'assets/images/vs.png',
                          width: 70,
                          height: 70,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback au texte si l'image n'est pas trouvée
                            return const Text(
                              'VS',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Enemy Champion Input (Right)
                  SizedBox(
                    width: cardSize,
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectingForChampion = false;
                              _selectedLetter = null;
                            });
                          },
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Container(
                              padding: EdgeInsets.zero,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                border: Border.all(
                                  // Highlight RIGHT when selecting the opponent
                                  color: !_selectingForChampion
                                      ? selectedBorderColor
                                      : Colors.grey[700]!,
                                  width: !_selectingForChampion ? 2 : 1,
                                ),
                                boxShadow: !_selectingForChampion
                                    ? [
                                        BoxShadow(
                                          color: selectedBorderColor.withOpacity(0.4),
                                          blurRadius: 6,
                                          spreadRadius: 0.5,
                                        ),
                                      ]
                                    : null,
                                borderRadius: BorderRadius.zero,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.zero,
                                child: _selectedOpponent != null
                                    ? Image.asset(
                                        _getChampionIconPath(_selectedOpponent!),
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          final failing = _getChampionIconPath(_selectedOpponent!);
                                          // ignore: avoid_print
                                          print('❌ [HOME_SCREEN] Failed to load opponent image: ' + failing + ' -> ' + error.toString());
                                          return Center(
                                            child: Icon(
                                              Icons.image_not_supported,
                                              color: Colors.grey[500],
                                              size: 32,
                                            ),
                                          );
                                        },
                                      )
                                    : Center(
                                        child: Text(
                                          '?',
                                          style: TextStyle(
                                            fontSize: 40,
                                            color: Colors.grey[400],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Adversaire',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Alphabet Grid (container removed to eliminate background block)
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.start,
                      spacing: 8,
                      runSpacing: 8,
                      children: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('').map((letter) {
                      final hasChampions = _champions.any((champion) => 
                          champion.toLowerCase().startsWith(letter.toLowerCase()));
                      return GestureDetector(
                        onTap: hasChampions ? () => _selectLetter(letter) : null,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF111111),
                            border: Border.all(
                              color: _selectedLetter == letter
                                  ? const Color(0xFFc2902a)
                                  : hasChampions
                                      ? Colors.grey[600]!
                                      : Colors.grey[500]!,
                              width: _selectedLetter == letter ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.zero,
                          ),
                          child: Center(
                            child: Text(
                              letter,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _selectedLetter == letter
                                    ? Colors.white
                                    : hasChampions
                                        ? Colors.white
                                        : Colors.grey[500],
                              ),
                            ),
                          ),
                        ),
                      );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              
              // Champions List (images + names)
              if (_selectedLetter != null && _filteredChampions.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _filteredChampions.map((champion) {
                    return GestureDetector(
                      onTap: () => _selectChampion(champion),
                      child: SizedBox(
                        width: 70,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                border: Border.all(color: Colors.grey[700]!),
                                borderRadius: BorderRadius.zero,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.zero,
                                child: Image.asset(
                                  _getChampionIconPath(champion),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    final failing = _getChampionIconPath(champion);
                                    // ignore: avoid_print
                                    print('❌ [HOME_SCREEN] Failed to load list item image: ' + failing + ' -> ' + error.toString());
                                    return Center(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        color: Colors.grey[500],
                                        size: 28,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              champion,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Lane Selection with Icons
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lane',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildLaneIcon('Top', 'assets/images/Top_icon.png'),
                      _buildLaneIcon('Jungle', 'assets/images/Jungle_icon.png'),
                      _buildLaneIcon('Mid', 'assets/images/Middle_icon.png'),
                      _buildLaneIcon('Bot', 'assets/images/Bottom_icon.png'),
                      _buildLaneIcon('Support', 'assets/images/Support_icon.png'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Get Advice Button
              ElevatedButton(
                onPressed: openAIService.isLoading || 
                          _selectedChampion == null || 
                          _selectedOpponent == null || 
                          _selectedLane == null
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          await openAIService.getMatchupAdvice(
                            _selectedChampion!,
                            _selectedOpponent!,
                            _selectedLane!,
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: openAIService.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Avoir les conseils',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              
              // Error Display
              if (openAIService.error != null) ...[
                const SizedBox(height: 16),
                Text(
                  openAIService.error!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
              
              // Response Display
              if (openAIService.lastResponse != null) ...[
                const SizedBox(height: 24),
                const Text(
                  'Matchup Advice:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 2,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildMatchupAdviceWidget(openAIService),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchupAdviceWidget(OpenAIService openAIService) {
    if (openAIService.lastParsedResponse == null) {
      return Text(
        openAIService.lastResponse!,
        style: const TextStyle(fontSize: 16, height: 1.5),
      );
    }

    final jsonData = openAIService.lastParsedResponse!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre du matchup
        Text(
          '🎯 ${jsonData['matchup']}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        
        // Kit de l'adversaire
        const Text(
          '⚔️ KIT DE L\'ADVERSAIRE',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const Divider(color: Colors.grey),
        
        // Extraire le nom de l'adversaire
        ...(() {
          String opponent = jsonData['matchup'].split(' vs ')[1].split(' ')[0];
          String kitKey = 'kit_de_$opponent';
          
          if (jsonData[kitKey] == null) return [const SizedBox()];
          
          final List<dynamic> kit = List<dynamic>.from(jsonData[kitKey]);
          // Place passive first
          kit.sort((a, b) {
            final at = (a['touche'] ?? '').toString().toLowerCase();
            final bt = (b['touche'] ?? '').toString().toLowerCase();
            final ap = (at == 'passive' || at.startsWith('p')) ? 0 : 1;
            final bp = (bt == 'passive' || bt.startsWith('p')) ? 0 : 1;
            return ap.compareTo(bp);
          });
          return kit.map<Widget>((spell) {
            String spellImagePath = _getSpellImagePath(opponent, spell['nom'], spell['touche']);
            print('🔍 HOME_SCREEN DEBUG: spellImagePath = "$spellImagePath" for ${spell['nom']}');
            
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image du sort
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.zero,
                      border: Border.all(color: Colors.grey[600]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.zero,
                      child: Image.asset(
                        spellImagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[700],
                            child: Icon(
                              Icons.help_outline,
                              color: Colors.grey[400],
                              size: 24,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Texte du sort
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Builder(builder: (context) {
                          final String title = (spell['nom'] ?? '').toString();
                          final String touche = (spell['touche'] ?? '').toString();
                          String displayTitle = title;
                          if (touche.isNotEmpty) {
                            final lt = title.toLowerCase();
                            final tt = touche.toLowerCase();
                            // If title already includes '(touche)' or the raw touche, don't append
                            final alreadyHas = lt.contains('($tt)') || lt.contains(' $tt');
                            if (!alreadyHas) {
                              displayTitle = '$title ($touche)';
                            }
                          }
                          return Text(
                            '🔸 $displayTitle',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }),
                        const SizedBox(height: 4),
                        Text(
                          spell['description'],
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[300],
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '⚠️ ${spell['si_danger_pour_${jsonData['matchup'].split(' vs ')[0]}']}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.orange,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList();
        })(),
        
        const SizedBox(height: 16),
        
        // Style de jeu conseillé
        const Text(
          '📋 STYLE DE JEU CONSEILLÉ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const Divider(color: Colors.grey),
        
        if (jsonData['style_de_jeu_conseillé'] != null) ...[
          const SizedBox(height: 8),
          _buildGamePhase('🌅 EARLY GAME', jsonData['style_de_jeu_conseillé']['early']),
          const SizedBox(height: 12),
          _buildGamePhase('⚡ MID GAME', jsonData['style_de_jeu_conseillé']['mid_game']),
          const SizedBox(height: 12),
          _buildGamePhase('🏆 LATE GAME', jsonData['style_de_jeu_conseillé']['late_game']),
        ],
      ],
    );
  }

  Widget _buildGamePhase(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[300],
            height: 1.4,
          ),
        ),
      ],
    );
  }

  String _getSpellImagePath(String championName, String spellName, String touche) {
    final openAIService = Provider.of<OpenAIService>(context, listen: false);
    return openAIService.getSpellImagePath(championName, spellName, touche);
  }

  Widget _buildLaneIcon(String lane, String iconPath) {
    final isSelected = _selectedLane == lane;
    const selectedBorderColor = Color(0xFFc2902a);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLane = lane;
        });
      },
      child: Container(
        width: 50,
        height: 50,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: isSelected 
              ? Border.all(
                  color: selectedBorderColor,
                  width: 2,
                )
              : null,
          borderRadius: BorderRadius.zero,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.zero,
          child: Image.asset(
            iconPath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Text(
                  lane.substring(0, 1),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[400],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Build champion icon path: assets/lol_champion_images/<normalized>/icon.jpg
  String _getChampionIconPath(String championName) {
    final dir = _championDirOverride(championName) ?? _normalizeChampionDir(championName);
    final path = 'assets/lol_champion_images/$dir/icon.jpg';
    // Log the exact path being requested for easier debugging
    print('🖼️ [HOME_SCREEN] Champion icon path for "$championName" => $path');
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

  // Some champions have folder names that don't exactly match their display names
  String? _championDirOverride(String name) {
    const overrides = {
      'Wukong': 'monkeyking',
      'Renata Glasc': 'renata',
      'Nunu & Willump': 'nunu',
    };
    return overrides[name];
  }

}
