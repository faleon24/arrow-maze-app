import 'dart:async';

import 'package:flutter/material.dart';

import '../../domain/models/game_session.dart';
import '../../domain/models/level.dart';
import '../../domain/models/position.dart';
import '../../domain/ports/progress_repository.dart';
import '../../infrastructure/adapters/http/api_exception.dart';
import '../../infrastructure/adapters/http/progress_http_adapter.dart';
import '../../infrastructure/adapters/local/shared_prefs_token_storage.dart';
import '../auth_guard.dart';
import '../widgets/cell_widget.dart';
import '../widgets/board_painter.dart';

class GameScreen extends StatefulWidget {
  final Level level;
  final List<Level>? catalog;
  final int? indexInCatalog;

  const GameScreen({
    super.key,
    required this.level,
    this.catalog,
    this.indexInCatalog,
  });

  Level? get nextLevel {
    if (catalog == null || indexInCatalog == null) return null;
    final next = indexInCatalog! + 1;
    return next < catalog!.length ? catalog![next] : null;
  }

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameSession _session;
  final IProgressRepository _progressRepo =
      const ProgressHttpAdapter(SharedPrefsTokenStorage());

  Position? _blockedFlash;
  Timer? _flashTimer;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    super.dispose();
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _session.isCleared) _submitAndShowWin();
    });
  }

  void _onCellTapped(Position position) {
    if (_session.isCleared || _session.isFailed) return;
    final outcome = _session.tap(position);
    setState(() {
      _blockedFlash = outcome == TapOutcome.blocked ? position : null;
    });
    if (outcome == TapOutcome.blocked) {
      _flashTimer?.cancel();
      _flashTimer = Timer(const Duration(milliseconds: 350), () {
        if (mounted) setState(() => _blockedFlash = null);
      });
    }
    if (_session.isCleared) {
      _submitAndShowWin();
    } else if (_session.isFailed) {
      _showEndDialog(won: false);
    }
  }

  Future<void> _submitAndShowWin() async {
    _saveError = null;
    try {
      await _progressRepo.submitScore(
        levelId: widget.level.id,
        moves: _session.movesUsed,
        timeMs: 0,
      );
    } on UnauthorizedException catch (_) {
      if (mounted) await AuthGuard.signOut();
      return;
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
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text(won ? 'Level cleared!' : 'Out of moves'),
          content: Text(
            won
                ? 'You cleared the board in ${_session.movesUsed} moves.\n'
                      'Stars earned: ${'*' * _session.starsEarned}\n'
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
            if (won && widget.nextLevel != null)
              FilledButton(
                onPressed: () {
                  final next = widget.nextLevel!;
                  Navigator.of(context).pop();
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final board = _session.board;
    return Scaffold(
      backgroundColor: const Color(0xFF07091A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1330),
        foregroundColor: Colors.white,
        title: Text(
          'Level ${widget.level.index + 1} - ${widget.level.difficulty}',
        ),
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
                  child: Stack(
                    children: [
                      GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: board.cols,
                        ),
                        itemCount: board.rows * board.cols,
                        itemBuilder: (context, i) {
                          final row = i ~/ board.cols;
                          final col = i % board.cols;
                          final position = Position(row, col);
                          final arrow = board.arrowAt(position);
                          return GestureDetector(
                            onTap: arrow != null
                                ? () => _onCellTapped(position)
                                : null,
                            child: CellWidget(
                              isWall: board.isWall(position),
                              collectible: board.collectibleAt(position),
                              highlight: _blockedFlash == position
                                  ? Colors.red.shade400
                                  : null,
                            ),
                          );
                        },
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: BoardPainter(board: board),
                          ),
                        ),
                      ),
                    ],
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

class _StatusBar extends StatelessWidget {
  final GameSession session;
  const _StatusBar({required this.session});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Stat(
            label: 'Arrows left',
            value: '${session.arrowsRemaining}',
          ),
        ),
        Expanded(
          child: _Stat(
            label: 'Moves',
            value: '${session.movesUsed} / ${session.moveLimit}',
          ),
        ),
        Expanded(child: _Stat(label: 'Lives', value: '${session.lives}')),
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
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(color: Colors.white),
        ),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.white70),
        ),
      ],
    );
  }
}
