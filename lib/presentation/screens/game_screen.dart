import 'package:flutter/material.dart';

import '../../data/models/level_model.dart';
import '../../domain/models/cell.dart';
import '../../domain/models/game_session.dart';
import '../../domain/models/position.dart';
import '../../data/api/progress_api.dart';
import '../../data/api/api_exception.dart';
import '../widgets/cell_widget.dart';

/// GameScreen — the playable board for a single level.
///
/// Wraps the level's board in a GameSession (the tested domain rules) and
/// turns taps into moves. On a win it submits the run to the backend and
/// shows the result; on a loss it offers a retry.
class GameScreen extends StatefulWidget {
  final LevelModel level;

  // The full catalog and this level's position in it, so the game can
  // offer "next level" on a win. Optional: if not provided, no next.
  final List<LevelModel>? catalog;
  final int? indexInCatalog;

  const GameScreen({
    super.key,
    required this.level,
    this.catalog,
    this.indexInCatalog,
  });

  LevelModel? get nextLevel {
    if (catalog == null || indexInCatalog == null) return null;
    final next = indexInCatalog! + 1;
    return next < catalog!.length ? catalog![next] : null;
  }

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameSession _session;
  final ProgressApi _progressApi = ProgressApi();

  // The position briefly flashed red after a blocked tap.
  Position? _blockedFlash;

  // A message if saving the score failed (offline, token expired, etc.).
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  void _startSession() {
    final arrowCount = widget.level.board.arrows.length;
    _session = GameSession(
      board: widget.level.board,
      moveLimit: arrowCount * 3,
      maxLives: 3,
    );
    _blockedFlash = null;
    _saveError = null;
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

    if (outcome == TapOutcome.blocked) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) setState(() => _blockedFlash = null);
      });
    }

    // Check for end of game after the move.
    if (_session.isCleared) {
      _submitAndShowWin();
    } else if (_session.isFailed) {
      _showEndDialog(won: false);
    }
  }

  /// On a win, submit the run to the backend (best score is kept there),
  /// then show the win dialog. A failed save doesn't block the dialog —
  /// the player still cleared the level; we just note it couldn't sync.
  Future<void> _submitAndShowWin() async {
    _saveError = null;

    try {
      await _progressApi.submitScore(
        levelId: widget.level.id,
        moves: _session.movesUsed,
        // No timer in this game; send 0 as an informational placeholder.
        timeMs: 0,
        stars: _session.starsEarned,
      );
    } on ApiException catch (e) {
      _saveError = e.message;
    } catch (e) {
      _saveError = e.toString();
    }

    if (mounted) _showEndDialog(won: true);
  }

  void _showEndDialog({required bool won}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(won ? 'Level cleared! 🎉' : 'Out of moves'),
        content: Text(
          won
              ? 'You cleared the board in ${_session.movesUsed} moves.\n'
                  'Stars earned: ${'⭐' * _session.starsEarned}\n'
                  '${_saveError == null ? 'Progress saved.' : 'Could not save: $_saveError'}'
              : 'The board still has ${_session.arrowsRemaining} arrows. Try again!',
        ),
actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Back to levels'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(_startSession);
            },
            child: const Text('Play again'),
          ),
          // Only on a win, and only if there is a next level.
          if (won && widget.nextLevel != null)
            FilledButton(
              onPressed: () {
                final next = widget.nextLevel!;
                Navigator.of(context).pop(); // close dialog
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => GameScreen(
                      level: next,
                      catalog: widget.catalog,
                      indexInCatalog: widget.indexInCatalog! + 1,
                    ),
                  ),
                );
              },
              child: const Text('Next level'),
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
      children: [
        Expanded(
          child: _Stat(label: 'Arrows left', value: '${session.arrowsRemaining}'),
        ),
        Expanded(
          child: _Stat(
            label: 'Moves',
            value: '${session.movesUsed} / ${session.moveLimit}',
          ),
        ),
        Expanded(
          child: _Stat(label: 'Lives', value: '${session.lives}'),
        ),
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