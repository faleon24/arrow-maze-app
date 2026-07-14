import 'package:flutter/material.dart';

import '../../data/api/level_api.dart';
import '../../data/dev_level_source.dart';
import '../../data/api/progress_api.dart';
import '../../data/models/level_model.dart';
import '../../data/auth_storage.dart';
import 'game_screen.dart';
import 'login_screen.dart';

/// LevelsScreen — loads the level catalog and the player's progress, and
/// lists each level with the stars earned so far.
///
/// It fetches both the public levels and the authenticated progress in
/// parallel, then cross-references them: each row shows how many of 3
/// stars the player has earned on that level (empty if never cleared).
class LevelsScreen extends StatefulWidget {
  const LevelsScreen({super.key});

  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

/// Bundles the two things the screen needs, loaded together.
class _LevelsData {
  final List<LevelModel> levels;
  final Map<String, int> starsByLevel;
  _LevelsData(this.levels, this.starsByLevel);
}

class _LevelsScreenState extends State<LevelsScreen> {
  final LevelApi _levelApi = LevelApi();
  final ProgressApi _progressApi = ProgressApi();

  late Future<_LevelsData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _load();
  }
      static const bool _useDevLevels =
      bool.fromEnvironment('USE_DEV_LEVELS', defaultValue: false);
  Future<_LevelsData> _load() async {
    final levelsFuture =
        _useDevLevels ? DevLevelSource.load() : _levelApi.fetchLevels();
    final starsFuture = _progressApi.fetchStarsByLevel().catchError(
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
              await AuthStorage().clearSession();
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
          final levels = data?.levels ?? [];
          final starsByLevel = data?.starsByLevel ?? {};

          if (levels.isEmpty) {
            return const Center(child: Text('No levels published yet.'));
          }

          return ListView.builder(
            itemCount: levels.length,
            itemBuilder: (context, i) {
              final level = levels[i];
              final earned = starsByLevel[level.id]; // null if not cleared

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
                  // Coming back from a game: refresh so new stars show.
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

/// Shows three star icons: filled for stars earned, outlined for the
/// rest. If [earned] is null (never cleared), all three are outlined.
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
