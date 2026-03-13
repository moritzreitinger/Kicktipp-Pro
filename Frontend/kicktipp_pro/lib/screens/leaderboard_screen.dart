import 'package:flutter/material.dart';
import 'dart:math';
import '../theme/app_theme.dart';
import '../widgets/custom_app_bar.dart';
import '../services/api_service.dart';

class LeaderboardPlayer {
  final String name;
  final int points;
  final int fullMatches;
  final String emoji;
  final int rank;

  LeaderboardPlayer({
    required this.name,
    required this.points,
    required this.fullMatches,
    required this.emoji,
    required this.rank,
  });
}

class LeaderboardScreen extends StatefulWidget {
  final String userName;
  final Color themeColor;

  const LeaderboardScreen({
    super.key,
    required this.userName,
    required this.themeColor,
  });

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<LeaderboardPlayer> _players = [];
  bool _loading = true;

  // Bot player names und emojis
  static const List<String> _botNames = [
    'Max Müller',
    'Anna Schmidt',
    'Tom Wagner',
    'Lisa Bauer',
    'Jan Fischer',
    'Sarah Meyer',
  ];

  static const List<String> _emojis = [
    '⚽',
    '🏆',
    '⚽',
    '🏰',
    '🌮',
    '🎪',
  ];

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _loading = true);
    try {
      // Hole alle fertiggestellten Spiele
      final allMatches = await ApiService.getMatches();
      final finishedMatches = allMatches.where((m) => m.isFinishedMatch).toList();
      
      // Hole Tipps des aktuellen Users (ID 1)
      final userTips = await ApiService.getUserTips(1);
      int userPoints = userTips.fold(0, (sum, tip) => sum + tip.pointsEarned);
      int userFullMatches = userTips.where((tip) => tip.pointsEarned == 3).length;

      final players = <LeaderboardPlayer>[];

      // Füge eingeloggten User hinzu
      players.add(LeaderboardPlayer(
        name: widget.userName,
        points: userPoints,
        fullMatches: userFullMatches,
        emoji: '⚽',
        rank: 0,
      ));

      // Füge Bot-Spieler hinzu mit generierten Punkten pro Spiel
      for (int i = 0; i < _botNames.length; i++) {
        int botPoints = 0;
        int botFullMatches = 0;
        
        // Pro beendetes Spiel: random 0, 1, oder 3 Punkte
        for (final match in finishedMatches) {
          // Seed der random generierung basierend auf match ID und bot index für konsistenz
          final seed = match.id * 7 + i * 13;
          final rand = Random(seed);
          final points = [0, 1, 3][rand.nextInt(3)];
          botPoints += points;
          if (points == 3) botFullMatches++;
        }

        players.add(LeaderboardPlayer(
          name: _botNames[i],
          points: botPoints,
          fullMatches: botFullMatches,
          emoji: _emojis[i],
          rank: 0,
        ));
      }

      // Sortiere nach Punkten (absteigend)
      players.sort((a, b) => b.points.compareTo(a.points));

      // Setze Rankings
      for (int i = 0; i < players.length; i++) {
        players[i] = LeaderboardPlayer(
          name: players[i].name,
          points: players[i].points,
          fullMatches: players[i].fullMatches,
          emoji: players[i].emoji,
          rank: i + 1,
        );
      }

      setState(() {
        _players = players;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Color _getMedalColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey[400]!;
      case 3:
        return const Color(0xFFCD7F32); // bronze
      default:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: CustomAppBar(userName: widget.userName, backgroundColor: widget.themeColor),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bestenliste',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Top 3 Podium
                        _buildPodium(widget.themeColor),
                      ],
                    ),
                  ),
                ),
                // Restliche Spieler
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final player = _players[index + 3];
                      return _buildPlayerListItem(player, index + 4, widget.themeColor);
                    },
                    childCount: _players.length > 3 ? _players.length - 3 : 0,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPodium(Color themeColor) {
    if (_players.length < 3) {
      return SizedBox(
        height: 220,
        width: double.infinity,
        child: Center(
          child: Text('Zu wenig Spieler (${_players.length})'),
        ),
      );
    }

    final first = _players[0];
    final second = _players[1];
    final third = _players[2];

    return SizedBox(
      height: 300,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Platz 2 (links, kleiner)
            _buildPodiumCard(second, 2, 220, themeColor),
            // Platz 1 (Mitte, größer)
            _buildPodiumCard(first, 1, 280, themeColor),
            // Platz 3 (rechts, mittel)
            _buildPodiumCard(third, 3, 240, themeColor),
          ],
        ),
      ),
    );
  }

  Widget _buildPodiumCard(LeaderboardPlayer player, int rank, double height, Color themeColor) {
    final medalColor = _getMedalColor(rank);
    final isFirst = rank == 1;

    return SizedBox(
      width: 100,
      height: height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Avatar mit emoji
          Container(
            width: isFirst ? 80 : 70,
            height: isFirst ? 80 : 70,
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    player.emoji,
                    style: TextStyle(fontSize: isFirst ? 36 : 32),
                  ),
                  if (rank == 1)
                    const Icon(
                      Icons.emoji_events,
                      color: Colors.amber,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Name
          Text(
            player.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          // Punkte
          Text(
            '${player.points} Pkt',
            style: TextStyle(
              fontSize: isFirst ? 16 : 14,
              fontWeight: FontWeight.bold,
              color: themeColor,
            ),
          ),
          // Volltreffer
          Text(
            '${player.fullMatches} Volltreffer',
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.darkGray,
            ),
          ),
          const Spacer(),
          // Podium Box
          Container(
            width: double.infinity,
            height: isFirst ? 90 : (rank == 2 ? 70 : 80),
            decoration: BoxDecoration(
              color: medalColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: isFirst ? 48 : 40,
                  fontWeight: FontWeight.bold,
                  color: rank == 2 ? Colors.black87 : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerListItem(LeaderboardPlayer player, int displayRank, Color themeColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightGray, width: 1),
      ),
      child: Row(
        children: [
          // Ranking
          Text(
            '$displayRank',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkGray,
            ),
          ),
          const SizedBox(width: 16),
          // Emoji
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                player.emoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name und Volltreffer
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${player.fullMatches} Volltreffer',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.darkGray,
                  ),
                ),
              ],
            ),
          ),
          // Punkte
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${player.points}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                ),
              ),
              const Text(
                'Punkte',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.darkGray,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
