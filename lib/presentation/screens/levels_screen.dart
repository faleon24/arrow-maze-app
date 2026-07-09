import 'package:flutter/material.dart';

import '../../data/api/level_api.dart';
import '../../data/models/level_model.dart';
import 'game_screen.dart';

/// LevelsScreen — the first real screen: it loads the level catalog
/// from the backend and lists it.
///
/// It is a StatefulWidget because it moves through states: while the
/// HTTP call is in flight it shows a spinner; on success it shows the
/// list; on failure it shows the error. This loading/success/error
/// shape is the standard way to present data fetched from an API.
class LevelsScreen extends StatefulWidget {
  const LevelsScreen({super.key});

  @override
  State<LevelsScreen> createState() => _LevelsScreenState();
}

class _LevelsScreenState extends State<LevelsScreen> {
  final LevelApi _api = LevelApi();

  // The future that produces the levels. FutureBuilder (below) listens
  // to it and rebuilds the UI as it resolves.
  late Future<List<LevelModel>> _levelsFuture;

  @override
  void initState() {
    super.initState();
    // Kick off the fetch once, when the screen is first created.
    _levelsFuture = _api.fetchLevels();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Arrow Maze — Levels')),
      body: FutureBuilder<List<LevelModel>>(
        future: _levelsFuture,
        builder: (context, snapshot) {
          // 1. Still loading.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Something went wrong.
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Error loading levels:\n${snapshot.error}'),
              ),
            );
          }

          // 3. Data is ready.
          final levels = snapshot.data ?? [];
          if (levels.isEmpty) {
            return const Center(child: Text('No levels published yet.'));
          }

          return ListView.builder(
            itemCount: levels.length,
            itemBuilder: (context, i) {
              final level = levels[i];
              return ListTile(
                leading: CircleAvatar(child: Text('${level.index + 1}')),
                title: Text('Level ${level.index + 1}'),
                subtitle: Text(
                  '${level.difficulty} · par ${level.parTimeMs ~/ 1000}s',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => GameScreen(level: level)),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
