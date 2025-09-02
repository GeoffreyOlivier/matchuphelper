import 'package:flutter/material.dart';
import '../utils/assets.dart';

class ChampionSelectionRow extends StatelessWidget {
  const ChampionSelectionRow({
    super.key,
    required this.cardSize,
    required this.selectingForChampion,
    required this.selectedChampion,
    required this.selectedOpponent,
    required this.onTapChampionSide,
    required this.onTapOpponentSide,
    this.maxWidth,
  });

  final double cardSize;
  final bool selectingForChampion;
  final String? selectedChampion;
  final String? selectedOpponent;
  final VoidCallback onTapChampionSide;
  final VoidCallback onTapOpponentSide;
  final double? maxWidth;

  static const Color selectedBorderColor = Color(0xFFc2902a);

  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisAlignment:
          maxWidth != null ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
      children: [
        // Your Champion Input (Left)
        Flexible(
          child: SizedBox(
            width: cardSize,
            child: Column(
            children: [
              GestureDetector(
                onTap: onTapChampionSide,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    padding: EdgeInsets.zero,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(
                        color: selectingForChampion ? selectedBorderColor : Colors.grey[700]!,
                        width: selectingForChampion ? 2 : 1,
                      ),
                      boxShadow: selectingForChampion
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
                      child: selectedChampion != null
                          ? Image.asset(
                              championIconPath(selectedChampion!),
                              width: double.infinity,
                              height: double.infinity,
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
        ),
        const SizedBox(width: 8),
        // VS Image
        Flexible(
          flex: 0,
          child: SizedBox(
            height: cardSize * 0.6,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.zero,
                ),
                child: Image.asset(
                  'assets/images/vs.png',
                  width: 50,
                  height: 50,
                  errorBuilder: (context, error, stackTrace) {
                    return const Text(
                      'VS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Enemy Champion Input (Right)
        Flexible(
          child: SizedBox(
            width: cardSize,
            child: Column(
            children: [
              GestureDetector(
                onTap: onTapOpponentSide,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    padding: EdgeInsets.zero,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(
                        color: !selectingForChampion ? selectedBorderColor : Colors.grey[700]!,
                        width: !selectingForChampion ? 2 : 1,
                      ),
                      boxShadow: !selectingForChampion
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
                      child: selectedOpponent != null
                          ? Image.asset(
                              championIconPath(selectedOpponent!),
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
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
        ),
      ],
    );
    if (maxWidth != null) {
      return SizedBox(width: maxWidth, child: row);
    }
    return row;
  }
}
