import 'package:flutter/material.dart';

class FeedbackModal extends StatefulWidget {
  const FeedbackModal({super.key});

  @override
  State<FeedbackModal> createState() => _FeedbackModalState();
}

class _FeedbackModalState extends State<FeedbackModal> {
  final Map<String, bool> _feedbackOptions = {
    'images_manquantes': false,
    'texte_faux': false,
    'texte_incomprehensible': false,
    'kit_absent': false,
    'autre': false,
  };

  final Map<String, String> _optionLabels = {
    'images_manquantes': 'Images manquantes',
    'texte_faux': 'Texte faux ou illogique',
    'texte_incomprehensible': 'Texte incompréhensible',
    'kit_absent': 'Kit du champion ou style de jeu absent',
    'autre': 'Autre',
  };

  bool get _hasSelectedOption => _feedbackOptions.values.any((selected) => selected);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1e1e1e),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text(
              'Aidez-nous à améliorer',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Qu\'est-ce qui ne va pas avec cette réponse ?',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[300],
              ),
            ),
            const SizedBox(height: 20),
            
            // Feedback options
            ..._optionLabels.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _feedbackOptions[entry.key] = !_feedbackOptions[entry.key]!;
                    });
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: _feedbackOptions[entry.key]! 
                                ? const Color(0xFFc2902a) 
                                : Colors.transparent,
                            border: Border.all(
                              color: _feedbackOptions[entry.key]! 
                                  ? const Color(0xFFc2902a) 
                                  : Colors.grey[600]!,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: _feedbackOptions[entry.key]! 
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 14,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Cancel button
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(null);
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(
                    'Annuler',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Submit button
                ElevatedButton(
                  onPressed: _hasSelectedOption ? () {
                    Navigator.of(context).pop(_feedbackOptions);
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFc2902a),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: const Text(
                    'Soumettre',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
