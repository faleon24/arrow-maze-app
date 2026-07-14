import 'package:flutter/material.dart';

import '../../application/usecases/auth/sign_out_usecase.dart';
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

  late Future<LevelsCatalog> _catalogFuture;
  LivesState? _lives;
  int _coins = 0;

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '+1 life (-${PurchaseLifeUseCase.cost} coins)',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
    await _refreshHeader();
  }

  void _openLevel(BuildContext context, Level level, List<Level> levels,
      int index) async {
    final lives = _lives;
    if (lives != null && lives.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No lives left. Buy one with coins to play.'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
