import 'package:flutter/material.dart';

import '../../data/models/level_model.dart';
import '../widgets/board_widget.dart';

/// GameScreen — shows a single level's board.
///
/// For now it just renders the grid; player movement and win detection
/// come next. It receives the already-loaded LevelModel from the list
/// screen, so no extra fetch is needed to open a board.
class GameScreen extends StatelessWidget {
  final LevelModel level;

  const GameScreen({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Level ${level.index + 1} · ${level.difficulty}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Par time: ${level.parTimeMs ~/ 1000}s',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            // The board sits in a centered, flexible area.
            Expanded(
              child: Center(
                child: BoardWidget(board: level.board),
              ),
            ),
          ],
        ),
      ),
    );
  }
}