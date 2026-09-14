import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';

class FlashcardViewerWidget extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> cards;

  const FlashcardViewerWidget({super.key, required this.cards});

  @override
  ConsumerState<FlashcardViewerWidget> createState() => _FlashcardViewerWidgetState();
}

class _FlashcardViewerWidgetState extends ConsumerState<FlashcardViewerWidget> {
  int _currentIndex = 0;
  bool _showBack = false;

  void _nextCard() {
    if (_currentIndex < widget.cards.length - 1) {
      setState(() {
        _currentIndex++;
        _showBack = false;
      });
    }
  }

  void _prevCard() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _showBack = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) {
      return const Center(child: Text('No flashcards available.'));
    }

    final card = widget.cards[_currentIndex];
    final String hindi = card['hindiWord'] ?? card['hindiText'] ?? '';
    final String santali = card['santaliWord'] ?? card['santaliText'] ?? '';
    final String phonetic = card['phoneticGuide'] ?? '';
    final String? audioRef = card['santaliAudioRef'];

    return Column(
      children: [
        // Counter
        Text(
          'Card ${_currentIndex + 1} of ${widget.cards.length}',
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondaryText),
        ),
        const SizedBox(height: 12),

        // Flip Card Widget
        GestureDetector(
          onTap: () => setState(() => _showBack = !_showBack),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (Widget child, Animation<double> animation) {
              final rotateAnim = Tween(begin: 3.14, end: 0.0).animate(animation);
              return AnimatedBuilder(
                animation: rotateAnim,
                child: child,
                builder: (context, child) {
                  return Transform(
                    transform: Matrix4.rotationY(rotateAnim.value),
                    alignment: Alignment.center,
                    child: child,
                  );
                },
              );
            },
            child: Container(
              key: ValueKey(_showBack),
              width: double.infinity,
              height: 240,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _showBack ? AppTheme.primaryAccentLight : AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _showBack ? AppTheme.primaryAccent : AppTheme.surfaceBorder,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _showBack ? 'SANTALI VERNACULAR ( Ol Chiki)' : 'HINDI WORD (हिन्दी)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _showBack ? AppTheme.primaryAccent : AppTheme.secondaryText,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _showBack ? santali : hindi,
                    style: _showBack
                        ? AppTheme.olChikiStyle(fontSize: 28, fontWeight: FontWeight.bold)
                        : AppTheme.devanagariStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  if (_showBack && phonetic.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Phonetic: $phonetic',
                      style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: AppTheme.secondaryText),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.touch_app_rounded, size: 16, color: AppTheme.secondaryText),
                      const SizedBox(width: 4),
                      Text(
                        _showBack ? 'Tap to flip back to Hindi' : 'Tap to reveal Santali translation',
                        style: const TextStyle(fontSize: 12, color: AppTheme.secondaryText),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),
        // Controls Row: Previous, Play Audio, Next
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton.filledTonal(
              onPressed: _currentIndex > 0 ? _prevCard : null,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            if (audioRef != null)
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(translationServiceProvider).playAudio(audioRef);
                },
                icon: const Icon(Icons.volume_up_rounded),
                label: const Text('Play Santali Voice'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(180, 48),
                ),
              ),
            IconButton.filledTonal(
              onPressed: _currentIndex < widget.cards.length - 1 ? _nextCard : null,
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
          ],
        ),
      ],
    );
  }
}
