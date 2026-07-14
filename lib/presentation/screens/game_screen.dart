import 'dart:async';

import 'package:flutter/material.dart';

import '../../application/usecases/game/game_feedback_usecase.dart';
import '../../application/usecases/game/reveal_hint_usecase.dart';
import '../../application/usecases/game/use_grid_highlight_usecase.dart';
import '../../application/usecases/lives/consume_life_usecase.dart';
import '../../application/usecases/lives/get_lives_usecase.dart';
import '../../application/usecases/progress/get_stars_by_level_usecase.dart';
import '../../application/usecases/progress/submit_level_result_usecase.dart';
import '../../application/usecases/wallet/award_coins_for_level_usecase.dart';
import '../../application/usecases/wallet/get_wallet_balance_usecase.dart';
import '../../core/di/service_locator.dart';
import '../../domain/models/game_session.dart';
import '../../domain/models/level.dart';
import '../../domain/models/lives_state.dart';
import '../../domain/models/position.dart';
import '../../domain/models/power_up_items.dart';
import '../../domain/ports/inventory_service.dart';
import '../../infrastructure/adapters/http/api_exception.dart';
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
  final SubmitLevelResultUseCase _submitResult =
      getIt<SubmitLevelResultUseCase>();
  final GetStarsByLevelUseCase _getStarsByLevel =
      getIt<GetStarsByLevelUseCase>();
  final GameFeedbackUseCase _feedback = getIt<GameFeedbackUseCase>();
  final RevealHintUseCase _revealHint = getIt<RevealHintUseCase>();
  final UseGridHighlightUseCase _useGrid = getIt<UseGridHighlightUseCase>();
  final GetWalletBalanceUseCase _getBalance =
      getIt<GetWalletBalanceUseCase>();
  final AwardCoinsForLevelUseCase _awardCoins =
      getIt<AwardCoinsForLevelUseCase>();
  final GetLivesUseCase _getLives = getIt<GetLivesUseCase>();
  final ConsumeLifeUseCase _consumeLife = getIt<ConsumeLifeUseCase>();
  final IInventoryService _inventory = getIt<IInventoryService>();

  final TransformationController _zoomController = TransformationController();

  Position? _blockedFlash;
  Timer? _flashTimer;
  Timer? _powerUpTimer;
  String? _saveError;

  int _coinsBalance = 0;
  int _hintCount = 0;
  int _gridCount = 0;
  int _coinsEarnedThisRun = 0;
  int? _serverStars;
  LivesState? _globalLives;
  bool _gridMode = false;
  Position? _hintedHead;
  List<Position> _gridRay = const <Position>[];

  /// Wall-clock start of the current attempt. Elapsed ms is submitted
  /// so the server's DifficultyProfile.starsFor(timeMs) receives a
  /// real duration and doesn't grade every run as three stars.
  DateTime? _sessionStartTime;

  /// Guard so we never consume more than one global life per instance
  /// of this screen (fail path AND dispose path both check it).
  bool _lifeConsumedThisRun = false;

  @override
  void initState() {
    super.initState();
    _startSession();
    _loadHeaderState();
  }

  @override
  void dispose() {
    if (!_session.isCleared && !_lifeConsumedThisRun) {
      _lifeConsumedThisRun = true;
      _consumeLife();
    }
    _flashTimer?.cancel();
    _powerUpTimer?.cancel();
    _zoomController.dispose();
    super.dispose();
  }

  Future<void> _loadHeaderState() async {
    final balance = await _getBalance();
    final hints = await _inventory.getCount(PowerUpItems.hint);
    final grids = await _inventory.getCount(PowerUpItems.gridHighlight);
    final lives = await _getLives();
    if (!mounted) return;
    setState(() {
      _coinsBalance = balance;
      _hintCount = hints;
      _gridCount = grids;
      _globalLives = lives;
    });
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
    _hintedHead = null;
    _gridRay = const <Position>[];
    _gridMode = false;
    _coinsEarnedThisRun = 0;
    _serverStars = null;
    _lifeConsumedThisRun = false;
    _sessionStartTime = DateTime.now();
    _zoomController.value = Matrix4.identity();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _session.isCleared) _submitAndShowWin();
    });
  }

  int _elapsedMs() {
    if (_sessionStartTime == null) return 0;
    return DateTime.now().difference(_sessionStartTime!).inMilliseconds;
  }

  void _resetZoom() {
    _zoomController.value = Matrix4.identity();
  }

  Future<void> _useHint() async {
    final activatable = _session.board.arrows
        .where((a) => _session.isActivatable(a.id))
        .map((a) => a.id)
        .toList(growable: false);
    final hintedId = await _revealHint(activatableArrowIds: activatable);
    if (!mounted) return;
    if (hintedId == null) {
      _showSnackBar(
        activatable.isEmpty
            ? 'No activatable arrows right now'
            : 'Out of hints',
      );
      return;
    }
    final arrow = _session.board.arrows.firstWhere((a) => a.id == hintedId);
    setState(() {
      _hintedHead = arrow.head;
      _hintCount = _hintCount > 0 ? _hintCount - 1 : 0;
      _gridRay = const <Position>[];
    });
    _powerUpTimer?.cancel();
    _powerUpTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _hintedHead = null);
    });
  }

  void _toggleGridMode() {
    if (_gridCount <= 0) {
      _showSnackBar('Out of grid highlights');
      return;
    }
    setState(() {
      _gridMode = !_gridMode;
      if (!_gridMode) _gridRay = const <Position>[];
    });
  }

  Future<void> _consumeGridOn(String arrowId) async {
    final ray = await _useGrid(board: _session.board, arrowId: arrowId);
    if (!mounted) return;
    if (ray == null) {
      _showSnackBar('Out of grid highlights');
      setState(() => _gridMode = false);
      return;
    }
    setState(() {
      _gridRay = ray;
      _gridMode = false;
      _gridCount = _gridCount > 0 ? _gridCount - 1 : 0;
      _hintedHead = null;
    });
    _powerUpTimer?.cancel();
    _powerUpTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _gridRay = const <Position>[]);
    });
  }

  void _onCellTapped(Position position) {
    if (_session.isCleared || _session.isFailed) return;
    final arrow = _session.board.arrowAt(position);
    if (arrow == null) return;

    if (_gridMode) {
      unawaited(_consumeGridOn(arrow.id));
      return;
    }

    final outcome = _session.tap(position);

    if (outcome == TapOutcome.blocked) {
      unawaited(_feedback.arrowBlocked());
    } else {
      unawaited(_feedback.arrowActivated());
    }

    setState(() {
      _blockedFlash = outcome == TapOutcome.blocked ? position : null;
      _hintedHead = null;
      _gridRay = const <Position>[];
    });
    if (outcome == TapOutcome.blocked) {
      _flashTimer?.cancel();
      _flashTimer = Timer(const Duration(milliseconds: 350), () {
        if (mounted) setState(() => _blockedFlash = null);
      });
    }
    if (_session.isCleared) {
      unawaited(_feedback.levelCleared());
      _submitAndShowWin();
    } else if (_session.isFailed) {
      unawaited(_feedback.levelFailed());
      _handleFailure();
      _showEndDialog(won: false);
    }
  }

  void _handleFailure() {
    if (_lifeConsumedThisRun) return;
    _lifeConsumedThisRun = true;
    unawaited(() async {
      await _consumeLife();
      if (!mounted) return;
      final lives = await _getLives();
      if (!mounted) return;
      setState(() => _globalLives = lives);
    }());
  }

  Future<void> _submitAndShowWin() async {
    _saveError = null;
    int? serverStars;
    final elapsedMs = _elapsedMs();
    try {
      await _submitResult(
        levelId: widget.level.id,
        moves: _session.movesUsed,
        timeMs: elapsedMs,
      );
      // Server is authoritative for stars — refetch so both this
      // dialog and the coin award reflect what actually got recorded.
      final starsByLevel = await _getStarsByLevel();
      serverStars = starsByLevel[widget.level.id];
    } on UnauthorizedException catch (_) {
      if (mounted) await AuthGuard.signOut();
      return;
    } on ApiException catch (e) {
      _saveError = e.message;
    } catch (e) {
      _saveError = e.toString();
    }

    final displayStars = serverStars ?? _session.starsEarned;
    final earned = await _awardCoins(stars: displayStars);
    if (mounted) {
      setState(() {
        _coinsEarnedThisRun = earned;
        _coinsBalance += earned;
        _serverStars = serverStars;
      });
    }
    if (mounted) _showEndDialog(won: true);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color? _highlightFor(Position position) {
    if (_blockedFlash == position) return Colors.red.shade400;
    if (_hintedHead == position) {
      return Colors.amberAccent.withValues(alpha: 0.55);
    }
    if (_gridRay.contains(position)) {
      return Colors.cyanAccent.withValues(alpha: 0.35);
    }
    return null;
  }

  void _showEndDialog({required bool won}) {
    final stars = _serverStars ?? _session.starsEarned;
    final timeSec = (_elapsedMs() / 1000).toStringAsFixed(1);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text(won ? 'Level cleared!' : 'Out of moves'),
          content: Text(
            won
                ? 'You cleared the board in ${_session.movesUsed} moves ($timeSec s).\n'
                      'Stars earned: ${'*' * stars}\n'
                      'Coins earned: +$_coinsEarnedThisRun (total: $_coinsBalance)\n'
                      '${_saveError == null ? 'Progress saved.' : 'Could not save: $_saveError'}'
                : 'The board still has ${_session.arrowsRemaining} arrows.\n'
                      '-1 life spent.',
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
    final lives = _globalLives;
    return Scaffold(
      backgroundColor: const Color(0xFF07091A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1330),
        foregroundColor: Colors.white,
        title: Text(
          'Level ${widget.level.index + 1} - ${widget.level.difficulty}',
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                const Icon(Icons.favorite, color: Colors.redAccent, size: 20),
                const SizedBox(width: 4),
                Text(
                  lives != null ? '${lives.current}' : '-',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(
                  '$_coinsBalance',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out_map),
            tooltip: 'Reset zoom',
            onPressed: _resetZoom,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _StatusBar(session: _session),
            const SizedBox(height: 12),
            _PowerUpBar(
              hintCount: _hintCount,
              gridCount: _gridCount,
              gridMode: _gridMode,
              onHint: _useHint,
              onGrid: _toggleGridMode,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: board.cols / board.rows,
                  child: InteractiveViewer(
                    transformationController: _zoomController,
                    minScale: 1.0,
                    maxScale: 3.5,
                    panEnabled: true,
                    scaleEnabled: true,
                    clipBehavior: Clip.hardEdge,
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
                                highlight: _highlightFor(position),
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
            ),
          ],
        ),
      ),
    );
  }
}

class _PowerUpBar extends StatelessWidget {
  final int hintCount;
  final int gridCount;
  final bool gridMode;
  final VoidCallback onHint;
  final VoidCallback onGrid;

  const _PowerUpBar({
    required this.hintCount,
    required this.gridCount,
    required this.gridMode,
    required this.onHint,
    required this.onGrid,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        FilledButton.tonalIcon(
          onPressed: hintCount > 0 ? onHint : null,
          icon: const Icon(Icons.lightbulb_outline),
          label: Text('Hint ($hintCount)'),
        ),
        FilledButton.tonalIcon(
          onPressed: gridCount > 0 ? onGrid : null,
          icon: Icon(
            Icons.grid_on,
            color: gridMode ? Colors.tealAccent : null,
          ),
          label: Text(gridMode ? 'Tap an arrow' : 'Grid ($gridCount)'),
        ),
      ],
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
        Expanded(
          child: _Stat(label: 'Attempts', value: '${session.lives}'),
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
