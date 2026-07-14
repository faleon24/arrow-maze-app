import 'package:flutter/material.dart';

import '../../application/usecases/auth/sign_out_usecase.dart';
import '../../application/usecases/level/load_levels_catalog_usecase.dart';
import '../../core/di/service_locator.dart';
import '../../domain/models/level.dart';
import 'game_screen.dart';
import 'login_screen.dart';

/// LevelsScreen — lists the published catalog with the player's stars
/// earned per level. The parallel-load + tolerate-progress-failure
/// policy lives inside LoadLevelsCatalogUseCase; the screen just
/// renders whatever LevelsCatalog it gets back.
class LevelsScreen extends StatefulWidget {
  const LevelsScreen({super.key});

  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen> {
  final LoadLevelsCatalogUseCase _loadCatalog =
      getIt<LoadLevelsCatalogUseCase>();
  final SignOutUseCase _signOut = getIt<SignOutUseCase>();

  late Future<LevelsCatalog> _catalogFuture;

  @override
  void initState() {
    super.initState();
    _catalogFuture = _loadCatalog();
  }

  void _reload() {
    setState(() {
      _catalogFuture = _loadCatalog();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arrow Maze — Levels'),
        actions: [
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
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => GameScreen(
                        level: level,
                        catalog: levels,
                        indexInCatalog: i,
                      ),
                    ),
                  );
                  _reload();
                },
              );
            },
          );
        },
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
