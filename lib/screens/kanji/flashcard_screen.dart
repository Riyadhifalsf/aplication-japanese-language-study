import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/kanji.dart';
import '../../models/vocabulary.dart';
import '../../state/app_controller.dart';
import '../../widgets/common_widgets.dart';

class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({
    required this.kanji,
    required this.items,
    super.key,
  });

  final Kanji kanji;
  final List<Vocabulary> items;

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  late List<Vocabulary> _items;
  int _index = 0;
  bool _showBack = false;

  @override
  void initState() {
    super.initState();
    _items = [...widget.items];
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final item = _items[_index];
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.kanji.character} · Kartu hafalan'),
        actions: [
          TextButton.icon(
            onPressed: app.toggleFurigana,
            icon: Icon(
              app.furiganaVisible
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
            ),
            label: const Text('Furigana'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: (_index + 1) / _items.length,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Kartu ${_index + 1} dari ${_items.length}'),
                const Spacer(),
                JlptBadge(item.level),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _showBack = !_showBack),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: Tween(begin: .92, end: 1.0).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutBack,
                      ),
                    ),
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: Card(
                    key: ValueKey('$_index-$_showBack'),
                    child: SizedBox.expand(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!_showBack)
                              FuriganaText(
                                word: item.word,
                                reading: item.reading,
                                showReading: app.furiganaVisible,
                                wordStyle: const TextStyle(
                                  fontSize: 54,
                                  fontWeight: FontWeight.w800,
                                ),
                                readingStyle: const TextStyle(fontSize: 18),
                              )
                            else ...[
                              Text(
                                item.meaning,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                '${item.word}（${item.reading}）',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            const Text('Ketuk kartu untuk membalik'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton.filledTonal(
                  tooltip: 'Dengarkan',
                  onPressed: () => app.tts.speak(item.reading),
                  icon: const Icon(Icons.volume_up_rounded),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Acak kartu',
                  onPressed: _shuffle,
                  icon: const Icon(Icons.shuffle_rounded),
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: _index == 0 ? null : () => _move(-1),
                  child: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => _move(1),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(
                    _index == _items.length - 1 ? 'Ulangi' : 'Berikutnya',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _move(int delta) => setState(() {
        _index = (_index + delta) % _items.length;
        if (_index < 0) _index = _items.length - 1;
        _showBack = false;
      });

  void _shuffle() => setState(() {
        _items.shuffle(Random());
        _index = 0;
        _showBack = false;
      });
}
