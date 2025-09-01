import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/openai_service.dart';
import '../constants/champions.dart';
import '../utils/assets.dart';
import '../widgets/champion_selection_row.dart';
import '../widgets/rating_buttons.dart';

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

  List<String> get _filteredChampions {
    if (_selectedLetter == null) return [];
    return champions
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
    // Shared layout metrics to align edges across sections
    const int kColumns = 5; // champions grid columns
    const int kAlphabetColumns = 7; // alphabet grid columns
    const double kSpacing = 12;
    const double kChampionTile = 70; // tile width used by champions grid
    final double gridMaxWidth = kColumns * kChampionTile + (kColumns - 1) * kSpacing;

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
              // Champion Selection Row (centered, aligned to shared max width)
              Align(
                alignment: Alignment.center,
                child: ChampionSelectionRow(
                  cardSize: cardSize,
                  selectingForChampion: _selectingForChampion,
                  selectedChampion: _selectedChampion,
                  selectedOpponent: _selectedOpponent,
                  onTapChampionSide: () {
                    setState(() {
                      _selectingForChampion = true;
                      _selectedLetter = null;
                    });
                  },
                  onTapOpponentSide: () {
                    setState(() {
                      _selectingForChampion = false;
                      _selectedLetter = null;
                    });
                  },
                  maxWidth: gridMaxWidth,
                ),
              ),
              const SizedBox(height: 20),
              
              // Alphabet Grid — aligned to the same shared max width, 6 columns for better density
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.center,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: gridMaxWidth),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: kAlphabetColumns,
                          crossAxisSpacing: kSpacing,
                          mainAxisSpacing: kSpacing,
                          mainAxisExtent: 40,
                        ),
                        itemCount: 26,
                        itemBuilder: (context, index) {
                          final letter = String.fromCharCode('A'.codeUnitAt(0) + index);
                          final hasChampions = champions.any((c) =>
                              c.toLowerCase().startsWith(letter.toLowerCase()));
                          return Center(
                            child: GestureDetector(
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
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              
              // Champions List (images + names) — 5 columns grid
              if (_selectedLetter != null && _filteredChampions.isNotEmpty) ...[
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const int columns = kColumns;
                    const double spacing = kSpacing;
                    final double _gridMaxWidth = gridMaxWidth;
                    return Align(
                      alignment: Alignment.center,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: _gridMaxWidth),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            crossAxisSpacing: spacing,
                            mainAxisSpacing: spacing,
                            mainAxisExtent: 110,
                          ),
                          itemCount: _filteredChampions.length,
                          itemBuilder: (context, index) {
                            final champion = _filteredChampions[index];
                            return GestureDetector(
                              onTap: () => _selectChampion(champion),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      border: Border.all(color: Colors.grey[700]!),
                                      borderRadius: BorderRadius.zero,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.zero,
                                      child: Image.asset(
                                        championIconPath(champion),
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
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
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Lane Selection with Icons
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
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
            String spellImagePath = _getSpellImagePath(opponent, (spell['nom'] ?? '').toString(), (spell['touche'] ?? '').toString());
            final String desc = (spell['description'] ?? spell['effet_court'] ?? '').toString();
            final String championLeft = jsonData['matchup'].split(' vs ')[0];
            final String dangerKey = 'si_danger_pour_$championLeft';
            final String? danger = (spell[dangerKey] as String?)?.trim().isNotEmpty == true
                ? (spell[dangerKey] as String)
                : (spell['consigne'] as String?);

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
                          desc,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[300],
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (danger != null && danger.isNotEmpty)
                          Text(
                            '⚠️ $danger',
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
        // New schema support: detect advice keys by prefix regardless of opponent suffix
        ...(() {
          String findFirstByPrefix(String prefix) {
            try {
              for (final entry in jsonData.entries) {
                final key = entry.key.toString();
                if (key.toLowerCase().startsWith(prefix.toLowerCase())) {
                  final val = entry.value?.toString() ?? '';
                  if (val.trim().isNotEmpty) return val.trim();
                }
              }
            } catch (_) {}
            return '';
          }

          final legacyStyle = (jsonData['style_de_jeu_conseillé'] ?? jsonData['style_de_jeu_conseille']) as Map<String, dynamic>?;
          final String legacyEarly = legacyStyle != null ? (legacyStyle['early'] ?? '').toString() : '';
          final String legacyMid = legacyStyle != null ? (legacyStyle['mid_game'] ?? '').toString() : '';
          final String legacyLate = legacyStyle != null ? (legacyStyle['late_game'] ?? '').toString() : '';

          final String laneLabel = ((jsonData['lane'] ?? _selectedLane) ?? '').toString();
          String titled(String base) => laneLabel.isNotEmpty ? '$base • $laneLabel' : base;

          final String laning = findFirstByPrefix('laning_vs_');
          final String strat = findFirstByPrefix('strategie_vs_');
          final String spikes = findFirstByPrefix('power_spikes_');

          final List<Widget> blocks = [];
          if (laning.isNotEmpty) {
            blocks..add(const SizedBox(height: 8))..add(_buildGamePhase(titled('🌅 LANING'), laning));
          }
          if (strat.isNotEmpty) {
            blocks..add(const SizedBox(height: 12))..add(_buildGamePhase(titled('🧭 STRATÉGIE'), strat));
          }
          if (spikes.isNotEmpty) {
            blocks..add(const SizedBox(height: 12))..add(_buildGamePhase(titled('⚔️ POWER SPIKES'), spikes));
          }

          // Fallback on legacy fields if new ones are empty
          if (blocks.isEmpty && (legacyEarly.isNotEmpty || legacyMid.isNotEmpty || legacyLate.isNotEmpty)) {
            blocks.add(const SizedBox(height: 8));
            blocks.add(_buildGamePhase('🌅 EARLY GAME', legacyEarly));
            blocks.add(const SizedBox(height: 12));
            blocks.add(_buildGamePhase('⚡ MID GAME', legacyMid));
            blocks.add(const SizedBox(height: 12));
            blocks.add(_buildGamePhase('🏆 LATE GAME', legacyLate));
          }

          return blocks;
        })(),
        
        // Rating buttons at bottom right
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: RatingButtons(
            champion: _selectedChampion ?? '',
            opponent: _selectedOpponent ?? '',
            lane: _selectedLane ?? '',
            ratingService: openAIService.ratingService,
          ),
        ),
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
    // Deprecated: kept for backward compatibility if referenced elsewhere.
    return championIconPath(championName);
  }

}
