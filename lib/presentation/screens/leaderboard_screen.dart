import 'package:flutter/material.dart';
import '../../application/usecases/leaderboard/get_leaderboard_usecase.dart';
import '../../application/usecases/leaderboard/get_my_leaderboard_rank_usecase.dart';
import '../../core/di/service_locator.dart';
import '../../domain/models/leaderboard_entry.dart';
import '../../domain/models/level.dart';
import '../../domain/models/my_leaderboard_rank.dart';
import '../../l10n/app_localizations.dart';

/// _LeaderboardData — the two reads the screen needs, fetched together:
/// the level's top runs and (optionally) the current player's own rank.
class _LeaderboardData {
  final List<LeaderboardEntry> entries;
  final MyLeaderboardRank? myRank;
  const _LeaderboardData({required this.entries, this.myRank});
}

/// LeaderboardScreen — top runs for a specific level, plus the current
/// player's own standing.
///
/// Fetches the top 10 and the player's rank on init. If the player is
/// inside the top 10 their row is highlighted; if they ranked but fell
/// outside it, their position is pinned at the bottom ("Your rank: #N").
/// The board itself is public; the personal rank is best-effort and
/// simply absent when there is no session.
class LeaderboardScreen extends StatefulWidget {
  final Level level;
  const LeaderboardScreen({super.key, required this.level});
  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  static const int _topLimit = 10;
  final GetLeaderboardUseCase _getLeaderboard = getIt<GetLeaderboardUseCase>();
  final GetMyLeaderboardRankUseCase _getMyRank =
      getIt<GetMyLeaderboardRankUseCase>();
  late Future<_LeaderboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_LeaderboardData> _load() async {
    final entries =
        await _getLeaderboard(levelId: widget.level.id, limit: _topLimit);
    final myRank = await _getMyRank(levelId: widget.level.id);
    return _LeaderboardData(entries: entries, myRank: myRank);
  }

  String _formatTime(int ms) {
    final totalSeconds = ms / 1000;
    if (totalSeconds < 60) {
      return '${totalSeconds.toStringAsFixed(1)}s';
    }
    final minutes = ms ~/ 60_000;
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

  Widget _starRow(int stars) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var s = 0; s < 3; s++)
          Icon(
            s < stars ? Icons.star : Icons.star_border,
            size: 16,
            color: s < stars ? Colors.amber : Colors.grey,
          ),
      ],
    );
  }

  Widget _entryTile({
    required int rank,
    required LeaderboardEntry entry,
    required bool isMe,
    required AppLocalizations l10n,
  }) {
    return ListTile(
      tileColor: isMe ? Colors.amber.withValues(alpha: 0.15) : null,
      leading: _rankBadge(rank),
      title: Text(entry.userDisplayName),
      subtitle: Row(
        children: [
          _starRow(entry.stars),
          const SizedBox(width: 12),
          Text(_formatTime(entry.timeMs)),
        ],
      ),
      trailing: isMe
          ? Chip(
              label: Text(l10n.youBadge),
              visualDensity: VisualDensity.compact,
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.leaderboardTitle(widget.level.index + 1)),
      ),
      body: FutureBuilder<_LeaderboardData>(
        future: _future,
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
          final data = snapshot.data ??
              const _LeaderboardData(entries: <LeaderboardEntry>[]);
          final entries = data.entries;
          final myRank = data.myRank;
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
          final meInTop = myRank != null && myRank.rank <= entries.length;
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final rank = i + 1;
                    return _entryTile(
                      rank: rank,
                      entry: entries[i],
                      isMe: myRank != null && myRank.rank == rank,
                      l10n: l10n,
                    );
                  },
                ),
              ),
              if (myRank != null && !meInTop)
                Material(
                  elevation: 8,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            l10n.yourRank(myRank.rank),
                            style:
                                const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      _entryTile(
                        rank: myRank.rank,
                        entry: myRank.entry,
                        isMe: true,
                        l10n: l10n,
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
