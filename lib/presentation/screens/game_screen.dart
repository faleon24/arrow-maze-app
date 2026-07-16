import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
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
import '../../domain/models/arrow_path.dart';
import '../../domain/models/game_session.dart';
import '../../domain/models/level.dart';
import '../../domain/models/lives_state.dart';
import '../../domain/models/position.dart';
import '../../domain/models/power_up_items.dart';
import '../../domain/ports/inventory_service.dart';
import '../../domain/ports/music_service.dart';
import '../../infrastructure/adapters/http/api_exception.dart';
import '../auth_guard.dart';
import '../widgets/cell_widget.dart';
import '../widgets/board_painter.dart';
import '../widgets/game_fx.dart';
import 'leaderboard_screen.dart';

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

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin {
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
  // Direct port access for pause/resume — the operations are pure
  // pass-throughs, not orchestration, so a wrapping use case would
  // add ceremony without value.
  final IMusicService _music = getIt<IMusicService>();
  final TransformationController _zoomController = TransformationController();
  Position? _blockedFlash;
  Timer? _flashTimer;
  Timer? _powerUpTimer;
  Timer? _uiTicker;
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
  /// Wall-clock start of the current attempt (may shift forward when
  /// pausing, so `elapsed = now - _sessionStartTime` stays correct
  /// regardless of pause history).
  DateTime? _sessionStartTime;
  /// When paused, the instant pause happened. Used to freeze the
  /// displayed elapsed time and to advance _sessionStartTime by the
  /// paused duration on resume.
  DateTime? _pausedAt;
  bool get _isPaused => _pausedAt != null;
  bool _lifeConsumedThisRun = false;

  // --- Animations ---
  // _fxController is a repaint clock for the "arrow cleared" effects; it
  // runs only while effects are on screen. _shakeController fires on a
  // blocked tap; _celebrationController drives the win confetti.
  final List<ClearFx> _clearFx = <ClearFx>[];
  late final AnimationController _fxController;
  late final AnimationController _shakeController;
  late final AnimationController _celebrationController;
  bool _celebrating = false;

  @override
  void initState() {
    super.initState();
    _startSession();
    _loadHeaderState();
    _startUiTicker();
    _fxController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_pruneClearFx);
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _celebrating = false);
        }
      });
  }

  @override
  void dispose() {
    if (!_session.isCleared && !_lifeConsumedThisRun) {
      _lifeConsumedThisRun = true;
      _consumeLife();
    }
    _flashTimer?.cancel();
    _powerUpTimer?.cancel();
    _uiTicker?.cancel();
    _fxController.dispose();
    _shakeController.dispose();
    _celebrationController.dispose();
    _zoomController.dispose();
    // Ensure music is playing again if the player left the game paused.
    _music.resume();
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

  void _startUiTicker() {
    _uiTicker?.cancel();
    _uiTicker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      // Rebuild so the elapsed-time display refreshes. Skipped when
      // paused since elapsed is frozen anyway.
      if (!_isPaused) setState(() {});
    });
  }

  void _startSession() {
    final arrowCount = widget.level.board.arrows.length;
    _session = GameSession(
      board: widget.level.board,
      moveLimit: arrowCount * 3,
      maxLives: 3,
    );
    _session.addObserver(_feedback);
    _blockedFlash = null;
    _saveError = null;
    _hintedHead = null;
    _gridRay = const <Position>[];
    _gridMode = false;
    _coinsEarnedThisRun = 0;
    _serverStars = null;
    _lifeConsumedThisRun = false;
    _clearFx.clear();
    _sessionStartTime = DateTime.now();
    _pausedAt = null;
    _zoomController.value = Matrix4.identity();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _session.isCleared) _submitAndShowWin();
    });
  }

  int _elapsedMs() {
    if (_sessionStartTime == null) return 0;
    final effectiveNow = _pausedAt ?? DateTime.now();
    return effectiveNow.difference(_sessionStartTime!).inMilliseconds;
  }

  String _formatElapsed(int ms) {
    final totalSec = ms ~/ 1000;
    final minutes = totalSec ~/ 60;
    final seconds = totalSec % 60;
    if (minutes == 0) return '${seconds}s';
    return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
  }

  void _togglePause() {
    if (_session.isCleared || _session.isFailed) return;
    if (_isPaused) {
      // Resume: advance sessionStartTime by the paused duration so
      // the displayed elapsed time doesn't jump.
      final pausedFor = DateTime.now().difference(_pausedAt!);
      _sessionStartTime = _sessionStartTime!.add(pausedFor);
      setState(() => _pausedAt = null);
      _music.resume();
      _session.resume();
    } else {
      setState(() => _pausedAt = DateTime.now());
      _music.pause();
      _session.pause();
    }
  }

  void _resetZoom() {
    _zoomController.value = Matrix4.identity();
  }

  Future<void> _useHint() async {
    if (_isPaused) return;
    final activatable = _session.board.arrows
        .where((a) => _session.isActivatable(a.id))
        .map((a) => a.id)
        .toList(growable: false);
    final hintedId = await _revealHint(activatableArrowIds: activatable);
    if (!mounted) return;
    if (hintedId == null) {
      _showSnackBar(
        activatable.isEmpty
            ? AppLocalizations.of(context).noActivatableArrows
            : AppLocalizations.of(context).outOfHints,
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
    if (_isPaused) return;
    if (_gridCount <= 0) {
      _showSnackBar(AppLocalizations.of(context).outOfGridHighlights);
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
      _showSnackBar(AppLocalizations.of(context).outOfGridHighlights);
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
    if (_isPaused) return;
    if (_session.isCleared || _session.isFailed) return;
    final arrow = _session.board.arrowAt(position);
    if (arrow == null) return;
    if (_gridMode) {
      unawaited(_consumeGridOn(arrow.id));
      return;
    }
    final outcome = _session.tap(position);
    setState(() {
      _blockedFlash = outcome == TapOutcome.blocked ? position : null;
      _hintedHead = null;
      _gridRay = const <Position>[];
    });
    if (outcome == TapOutcome.blocked) {
      _triggerShake();
      _flashTimer?.cancel();
      _flashTimer = Timer(const Duration(milliseconds: 350), () {
        if (mounted) setState(() => _blockedFlash = null);
      });
    } else {
      // The tap cleared this arrow: fire its ray-off animation.
      _emitClearFx(arrow);
    }
    if (_session.isCleared) {
      _submitAndShowWin();
    } else if (_session.isFailed) {
      _handleFailure();
      _showEndDialog(won: false);
    }
  }

  // --- Animation helpers ---

  void _pruneClearFx() {
    _clearFx.removeWhere(
      (f) => DateTime.now().difference(f.start) >= kClearFxDuration,
    );
    if (_clearFx.isEmpty && _fxController.isAnimating) {
      _fxController.stop();
    }
  }

  /// Build the fly-off effect for a just-cleared arrow: trace its ray to
  /// the edge (measuring length + any stars swept up) and queue a ClearFx.
  void _emitClearFx(ArrowPath arrow) {
    final head = arrow.head;
    final step = arrow.direction.apply(Position(0, 0));
    final dRow = step.row;
    final dCol = step.col;
    final rows = _session.board.rows;
    final cols = _session.board.cols;
    var r = head.row + dRow;
    var c = head.col + dCol;
    var len = 0;
    final stars = <Position>[];
    while (r >= 0 && r < rows && c >= 0 && c < cols) {
      final p = Position(r, c);
      if (_session.board.collectibleAt(p) != null) stars.add(p);
      len++;
      r += dRow;
      c += dCol;
    }
    _clearFx.add(
      ClearFx(
        row: head.row,
        col: head.col,
        dRow: dRow,
        dCol: dCol,
        color: arrow.color.hex,
        rayLen: len == 0 ? 1 : len,
        stars: stars,
      ),
    );
    if (!_fxController.isAnimating) _fxController.repeat();
  }

  void _triggerShake() {
    _shakeController.forward(from: 0);
  }

  double _shakeDx() {
    final t = _shakeController.value;
    if (t == 0 || t == 1) return 0;
    return math.sin(t * math.pi * 5) * 10 * (1 - t);
  }

  void _startCelebration() {
    setState(() => _celebrating = true);
    _celebrationController.forward(from: 0);
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
    if (mounted) {
      // Celebrate first, then let the results dialog rise over the confetti.
      _startCelebration();
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) _showEndDialog(won: true);
      });
    }
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
    final timeStr = _formatElapsed(_elapsedMs());
    final l10n = AppLocalizations.of(context);
    final starsStr = '*' * stars;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text(won ? l10n.levelCleared : l10n.outOfMoves),
          content: Text(
            won
                ? '${l10n.clearedBoardIn(_session.movesUsed, timeStr)}\n'
                      '${l10n.starsEarned(starsStr)}\n'
                      '${l10n.coinsEarned(_coinsEarnedThisRun, _coinsBalance)}\n'
                      '${_saveError == null ? l10n.progressSaved : l10n.couldNotSave(_saveError!)}'
                : '${l10n.boardStillHas(_session.arrowsRemaining)}\n'
                      '${l10n.oneLifeSpent}',
          ),
          actions: [
            if (won)
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LeaderboardScreen(level: widget.level),
                  ),
                ),
                icon: const Icon(Icons.leaderboard_outlined),
                label: Text(l10n.viewRanking),
              ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Text(l10n.backToLevels),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(_startSession);
              },
              child: Text(l10n.playAgain),
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
                child: Text(l10n.nextLevel),
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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF07091A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1330),
        foregroundColor: Colors.white,
        title: Text(
          l10n.gameLevelTitle(widget.level.index + 1, widget.level.difficulty),
        ),
        actions: [
          IconButton(
            icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
            tooltip: _isPaused ? l10n.resume : l10n.pause,
            onPressed:
                (_session.isCleared || _session.isFailed) ? null : _togglePause,
          ),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.yellow, size: 20),
                const SizedBox(width: 4),
                Text(
                  '${_session.collectedPositions.length}/${_session.collectedPositions.length + _session.board.collectibles.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined),
            tooltip: l10n.leaderboard,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LeaderboardScreen(level: widget.level),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out_map),
            tooltip: l10n.resetZoom,
            onPressed: _resetZoom,
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _StatusBar(
                  session: _session,
                  elapsedText: _formatElapsed(_elapsedMs()),
                ),
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
                    child: AnimatedBuilder(
                      animation: _shakeController,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(_shakeDx(), 0),
                        child: child,
                      ),
                      child: AspectRatio(
                        aspectRatio: board.cols / board.rows,
                        child: Stack(
                          children: [
                            InteractiveViewer(
                              transformationController: _zoomController,
                              minScale: 1.0,
                              maxScale: 3.5,
                              panEnabled: true,
                              scaleEnabled: true,
                              clipBehavior: Clip.hardEdge,
                              child: Stack(
                                children: [
                                  GridView.builder(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
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
                                          collectible:
                                              board.collectibleAt(position),
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
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: RepaintBoundary(
                                        child: AnimatedBuilder(
                                          animation: _fxController,
                                          builder: (_, _) => CustomPaint(
                                            painter: ClearFxPainter(
                                              effects: _clearFx,
                                              rows: board.rows,
                                              cols: board.cols,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_isPaused)
                              Positioned.fill(
                                child: _PauseOverlay(onResume: _togglePause),
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
          if (_celebrating)
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _celebrationController,
                    builder: (_, _) => CustomPaint(
                      painter: ConfettiPainter(t: _celebrationController.value),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PauseOverlay extends StatelessWidget {
  final VoidCallback onResume;
  const _PauseOverlay({required this.onResume});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.pause_circle_outline,
              color: Colors.white, size: 72),
          const SizedBox(height: 12),
          Text(
            l10n.paused,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onResume,
            icon: const Icon(Icons.play_arrow),
            label: Text(l10n.resume),
          ),
        ],
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
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        FilledButton.tonalIcon(
          onPressed: hintCount > 0 ? onHint : null,
          icon: const Icon(Icons.lightbulb_outline),
          label: Text(l10n.hintLabel(hintCount)),
        ),
        FilledButton.tonalIcon(
          onPressed: gridCount > 0 ? onGrid : null,
          icon: Icon(
            Icons.grid_on,
            color: gridMode ? Colors.tealAccent : null,
          ),
          label: Text(gridMode ? l10n.tapAnArrow : l10n.gridLabel(gridCount)),
        ),
      ],
    );
  }
}

class _StatusBar extends StatelessWidget {
  final GameSession session;
  final String elapsedText;
  const _StatusBar({required this.session, required this.elapsedText});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _Stat(
            label: l10n.statArrowsLeft,
            value: '${session.arrowsRemaining}',
          ),
        ),
        Expanded(
          child: _Stat(
            label: l10n.statMoves,
            value: '${session.movesUsed} / ${session.moveLimit}',
          ),
        ),
        Expanded(
          child: _Stat(label: l10n.statTime, value: elapsedText),
        ),
        Expanded(
          child: _Stat(label: l10n.statAttempts, value: '${session.lives}'),
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
