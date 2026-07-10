import 'package:flutter/material.dart';

import '../../data/models/level_model.dart';
import '../../domain/models/cell.dart';
import '../../domain/models/game_session.dart';
import '../../domain/models/position.dart';
import '../widgets/cell_widget.dart';

/// GameScreen — the playable board for a single level.
///
/// Wraps the level's board in a GameSession (the tested domain rules) and
/// turns taps into moves: tapping a clearable arrow sends it off the
/// board; tapping a blocked one costs a life. It shows moves and lives,
/// and ends the game on a cleared board (win) or when lives/moves run out
/// (lose).
class GameScreen extends StatefulWidget {
  final LevelModel level;

  const GameScreen({super.key, required this.level});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameSession _session;

  // The position briefly flashed red after a blocked tap.
  Position? _blockedFlash;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  void _startSession() {
    // A generous move limit based on the number of arrows: every arrow
    // needs at least one move, plus some slack for mistakes.
    final arrowCount = widget.level.board.arrows.length;
    _session = GameSession(
      board: widget.level.board,
      moveLimit: arrowCount * 3,
      maxLives: 3,
    );
    _blockedFlash = null;
  }

  void _onCellTapped(Position position) {
    if (_session.isCleared || _session.isFailed) return;

    final outcome = _session.tap(position);

    setState(() {
      if (outcome == TapOutcome.blocked) {
        _blockedFlash = position;
      } else {
        _blockedFlash = null;
      }
    });

    // Clear the red flash shortly after a blocked tap.
    if (outcome == TapOutcome.blocked) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) setState(() => _blockedFlash = null);
      });
    }

    // Check for end of game after the move.
    if (_session.isCleared) {
      _showEndDialog(won: true);
    } else if (_session.isFailed) {
      _showEndDialog(won: false);
    }
  }

  void _showEndDialog({required bool won}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(won ? 'Level cleared! 🎉' : 'Out of moves'),
        content: Text(
          won
              ? 'You cleared the board in ${_session.movesUsed} moves.'
              : 'The board still has ${_session.arrowsRemaining} arrows. Try again!',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // close dialog
              Navigator.of(context).pop(); // back to level list
            },
            child: const Text('Back to levels'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // close dialog
              setState(_startSession); // restart this level
            },
            child: const Text('Play again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final board = _session.board;

    return Scaffold(
      appBar: AppBar(
        title: Text('Level ${widget.level.index + 1} · ${widget.level.difficulty}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _StatusBar(session: _session),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: board.cols / board.rows,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: board.cols,
                    ),
                    itemCount: board.rows * board.cols,
                    itemBuilder: (context, i) {
                      final row = i ~/ board.cols;
                      final col = i % board.cols;
                      final position = Position(row, col);
                      final cell = board.cellAt(position);

                      return GestureDetector(
                        onTap: cell is ArrowCell
                            ? () => _onCellTapped(position)
                            : null,
                        child: CellWidget(
                          cell: cell,
                          highlight: _blockedFlash == position
                              ? Colors.red.shade400
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small header showing moves used and lives remaining.
class _StatusBar extends StatelessWidget {
  final GameSession session;

  const _StatusBar({required this.session});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _Stat(label: 'Arrows left', value: '${session.arrowsRemaining}'),
        _Stat(label: 'Moves', value: '${session.movesUsed} / ${session.moveLimit}'),
        _Stat(label: 'Lives', value: '${session.lives}'),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}