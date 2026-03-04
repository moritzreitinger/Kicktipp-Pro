import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/custom_app_bar.dart';
import '../utils/team_initials.dart';

class MyTipsScreen extends StatefulWidget {
  final String userName;

  const MyTipsScreen({super.key, required this.userName});

  @override
  State<MyTipsScreen> createState() => _MyTipsScreenState();
  
  static _MyTipsScreenState? of(BuildContext context) {
    return context.findAncestorStateOfType<_MyTipsScreenState>();
  }
}

class _MyTipsScreenState extends State<MyTipsScreen> {
  List<TipDto> _tips = [];
  bool _loading = true;
  String? _error;
  int _totalPoints = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tips = await ApiService.getUserTips(1);
      int totalPoints = 0;
      for (final tip in tips) {
        totalPoints += tip.pointsEarned;
      }
      setState(() {
        _tips = tips;
        _totalPoints = totalPoints;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> refreshTips() async {
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: CustomAppBar(userName: widget.userName),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Meine Tipps',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryOrange,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Gesamt Punkte: $_totalPoints',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _load,
                child: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
      );
    }

    if (_loading && _tips.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_tips.isEmpty) {
      return const Center(
        child: Text(
          'Keine Tipps vorhanden',
          style: TextStyle(color: AppTheme.darkGray),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: _tips.length,
        itemBuilder: (_, i) {
          final tip = _tips[i];
          return _TipCard(tip: tip);
        },
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final TipDto tip;

  const _TipCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    final cardColor = tip.isFinishedMatch ? Colors.grey[200] : Colors.white;
    final statusText = tip.isFinishedMatch
        ? 'Abgeschlossen - ${tip.pointsEarned} Pt.'
        : 'Ausstehend';
    final statusColor =
        tip.isFinishedMatch ? AppTheme.darkGray : AppTheme.primaryOrange;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CompactTeamSection(
                initials: getTeamInitials(tip.homeTeam),
                teamName: tip.homeTeam,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${tip.tipHome}:${tip.tipAway}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (tip.isFinishedMatch)
                      Text(
                        'Ergebnis: ${tip.homeScore}:${tip.awayScore}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.darkGray,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _CompactTeamSection(
                initials: getTeamInitials(tip.awayTeam),
                teamName: tip.awayTeam,
                isRight: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDate(tip.matchDate),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.darkGray,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final dt = DateTime.parse(dateString);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return dateString;
    }
  }
}

class _CompactTeamSection extends StatelessWidget {
  final String initials;
  final String teamName;
  final bool isRight;

  const _CompactTeamSection({
    required this.initials,
    required this.teamName,
    this.isRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment:
            isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            teamName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: isRight ? TextAlign.right : TextAlign.left,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
