import 'package:flutter/material.dart';
import '../../application/usecases/leaderboard/get_leaderboard_usecase.dart';
import '../../core/di/service_locator.dart';
import '../../domain/models/leaderboard_entry.dart';
import '../../domain/models/level.dart';
import '../../l10n/app_localizations.dart';

/// LeaderboardScreen — top runs for a specific level.
///
/// Fetches from the backend on init; renders rank + display name +
/// star count + wall-clock time. Public data, no auth required.
class LeaderboardScreen extends StatefulWidget {
  final Level level;
  const LeaderboardScreen({super.key, required this.level});
  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final GetLeaderboardUseCase _getLeaderboard =
      getIt<GetLeaderboardUseCase>();
  late Future<List<LeaderboardEntry>> _entriesFuture;

  @override
  void initState() {
    super.initState();
    _entriesFuture = _getLeaderboard(levelId: widget.level.id, limit: 20);
  }

  String _formatTime(int ms) {
    final totalSeconds = ms / 1000;
    if (totalSeconds < 60) {
      return '${totalSeconds.toStringAsFixed(1)}s';
    }
    final minutes = (ms ~/ 60_000);
    final seconds = ((ms % 60_000) / 1000).toStringAsFixed(1);
    return '${minutes}m ${seconds}s';
  }

  Widget _rankBadge(int rank) {
    Color color;
    if (rank == 1) {
      color = Colors.amber;
    } else if (rank == 2) {
      color = Colors.blueGrey;
    } else if (rank == 3) {
      color = Colors.brown;
    } else {
      color = Colors.grey.shade400;
    }
    return CircleAvatar(
      backgroundColor: color,
      radius: 18,
      child: Text(
        '#$rank',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.leaderboardTitle(widget.level.index + 1)),
      ),
      body: FutureBuilder<List<LeaderboardEntry>>(
        future: _entriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.errorLoadingLeaderboard(snapshot.error!)),
              ),
            );
          }
          final entries = snapshot.data ?? const <LeaderboardEntry>[];
          if (entries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.noRunsRecorded,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: entries.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final entry = entries[i];
              return ListTile(
                leading: _rankBadge(i + 1),
                title: Text(entry.userDisplayName),
                subtitle: Row(
                  children: [
                    for (var s = 0; s < 3; s++)
                      Icon(
                        s < entry.stars ? Icons.star : Icons.star_border,
                        size: 16,
                        color: s < entry.stars
                            ? Colors.amber
                            : Colors.grey,
                      ),
                    const SizedBox(width: 12),
                    Text(_formatTime(entry.timeMs)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
