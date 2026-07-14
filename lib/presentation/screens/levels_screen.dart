import 'package:flutter/material.dart';

import '../../application/usecases/auth/sign_out_usecase.dart';
import '../../application/usecases/level/generate_level_usecase.dart';
import '../../application/usecases/level/load_levels_catalog_usecase.dart';
import '../../application/usecases/lives/get_lives_usecase.dart';
import '../../application/usecases/lives/purchase_life_usecase.dart';
import '../../application/usecases/wallet/get_wallet_balance_usecase.dart';
import '../../core/di/service_locator.dart';
import '../../domain/models/level.dart';
import '../../domain/models/lives_state.dart';
import 'game_screen.dart';
import 'login_screen.dart';

class LevelsScreen extends StatefulWidget {
  const LevelsScreen({super.key});

  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen> {
  final LoadLevelsCatalogUseCase _loadCatalog =
      getIt<LoadLevelsCatalogUseCase>();
  final SignOutUseCase _signOut = getIt<SignOutUseCase>();
  final GetLivesUseCase _getLives = getIt<GetLivesUseCase>();
  final PurchaseLifeUseCase _purchaseLife = getIt<PurchaseLifeUseCase>();
  final GetWalletBalanceUseCase _getBalance =
      getIt<GetWalletBalanceUseCase>();
  final GenerateLevelUseCase _generateLevel = getIt<GenerateLevelUseCase>();

  late Future<LevelsCatalog> _catalogFuture;
  LivesState? _lives;
  int _coins = 0;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _catalogFuture = _loadCatalog();
    _refreshHeader();
  }

  Future<void> _refreshHeader() async {
    final lives = await _getLives();
    final coins = await _getBalance();
    if (!mounted) return;
    setState(() {
      _lives = lives;
      _coins = coins;
    });
  }

  void _reload() {
    setState(() {
      _catalogFuture = _loadCatalog();
    });
    _refreshHeader();
  }

  Future<void> _handleBuyLife() async {
    final ok = await _purchaseLife();
    if (!mounted) return;
    if (!ok) {
      final lives = _lives;
      final msg = (lives != null && lives.isFull)
          ? 'Already at max lives'
          : 'Not enough coins (need ${PurchaseLifeUseCase.cost})';
      _showSnack(msg);
      return;
    }
    _showSnack('+1 life (-${PurchaseLifeUseCase.cost} coins)');
    await _refreshHeader();
  }

  void _openLevel(
    BuildContext context,
    Level level,
    List<Level> levels,
    int index,
  ) async {
    final lives = _lives;
    if (lives != null && lives.isEmpty) {
      _showSnack('No lives left. Buy one with coins to play.');
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          level: level,
          catalog: levels,
          indexInCatalog: index,
        ),
      ),
    );
    _reload();
  }

  void _openGenerateSheet() {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Generate a new level',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Pick a difficulty and the server crafts a solvable puzzle.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 8),
            for (final d in const ['EASY', 'MEDIUM', 'HARD'])
              ListTile(
                leading: const Icon(Icons.auto_awesome),
                title: Text(d),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _generateAndRefresh(d);
                },
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _generateAndRefresh(String difficulty) async {
    if (_generating) return;
    setState(() => _generating = true);
    try {
      final level = await _generateLevel(difficulty: difficulty);
      if (!mounted) return;
      _showSnack(
        'Generated ${level.difficulty} level #${level.index + 1}',
      );
      _reload();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Generation failed: $e');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lives = _lives;
    final canBuyLife = lives != null && !lives.isFull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Arrow Maze — Levels'),
        actions: [
          _HeaderChip(
            icon: Icons.favorite,
            iconColor: Colors.redAccent,
            text: lives != null ? '${lives.current}/${lives.max}' : '-',
          ),
          if (canBuyLife)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Buy 1 life (${PurchaseLifeUseCase.cost} coins)',
              onPressed: _handleBuyLife,
            ),
          _HeaderChip(
            icon: Icons.monetization_on,
            iconColor: Colors.amber,
            text: '$_coins',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () async {
              await _signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generating ? null : _openGenerateSheet,
        icon: _generating
            ? const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.auto_awesome),
        label: Text(_generating ? 'Generating...' : 'Generate level'),
      ),
      body: FutureBuilder<LevelsCatalog>(
        future: _catalogFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Error loading levels:\n${snapshot.error}'),
              ),
            );
          }

          final catalog = snapshot.data;
          final levels = catalog?.levels ?? <Level>[];
          final starsByLevel = catalog?.starsByLevel ?? <String, int>{};

          if (levels.isEmpty) {
            return const Center(child: Text('No levels published yet.'));
          }

          return ListView.builder(
            itemCount: levels.length,
            itemBuilder: (context, i) {
              final level = levels[i];
              final earned = starsByLevel[level.id];

              return ListTile(
                leading: CircleAvatar(child: Text('${level.index + 1}')),
                title: Text('Level ${level.index + 1}'),
                subtitle: Row(
                  children: [
                    Text(level.difficulty),
                    const SizedBox(width: 8),
                    _StarRow(earned: earned),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openLevel(context, level, levels, i),
              );
            },
          );
        },
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;

  const _HeaderChip({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final int? earned;

  const _StarRow({required this.earned});

  @override
  Widget build(BuildContext context) {
    final count = earned ?? 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final filled = i < count;
        return Icon(
          filled ? Icons.star : Icons.star_border,
          size: 18,
          color: filled ? Colors.amber : Colors.grey,
        );
      }),
    );
  }
}
