import 'package:flutter/material.dart';

import '../../core/di/service_locator.dart';
import '../../domain/models/level.dart';
import '../../domain/ports/auth_token_storage.dart';
import '../../domain/ports/level_repository.dart';
import '../../domain/ports/progress_repository.dart';
import 'game_screen.dart';
import 'login_screen.dart';

/// LevelsScreen — loads the level catalog and the player's progress, and
/// lists each level with the stars earned so far.
class LevelsScreen extends StatefulWidget {
  const LevelsScreen({super.key});

  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

/// Bundles the two things the screen needs, loaded together.
class _LevelsData {
  final List<Level> levels;
  final Map<String, int> starsByLevel;
  _LevelsData(this.levels, this.starsByLevel);
}

class _LevelsScreenState extends State<LevelsScreen> {
  final ILevelRepository _levelRepo = getIt<ILevelRepository>();
  final IProgressRepository _progressRepo = getIt<IProgressRepository>();

  late Future<_LevelsData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
  }

  Future<_LevelsData> _load() async {
    final levelsFuture = _levelRepo.fetchLevels();
    final starsFuture = _progressRepo.fetchStarsByLevel().catchError(
      (Object _) => <String, int>{},
    );
    return _LevelsData(await levelsFuture, await starsFuture);
  }

  void _reload() {
    setState(() {
      _dataFuture = _load();
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
              await getIt<IAuthTokenStorage>().clearSession();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<_LevelsData>(
        future: _dataFuture,
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

          final data = snapshot.data;
          final levels = data?.levels ?? <Level>[];
          final starsByLevel = data?.starsByLevel ?? <String, int>{};

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
