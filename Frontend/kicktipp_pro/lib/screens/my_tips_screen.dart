import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/custom_app_bar.dart';
import '../utils/team_initials.dart';

enum _FilterType { all, finished, open }

class MyTipsScreen extends StatefulWidget {
  final String userName;
  final Color themeColor;

  const MyTipsScreen({
    super.key,
    required this.userName,
    required this.themeColor,
  });

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
  _FilterType _currentFilter = _FilterType.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tips = await ApiService.getUserTips(1);
      if (!mounted) return;
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
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> refreshTips() async {
    await _load();
  }

  List<TipDto> _getFilteredTips() {
    switch (_currentFilter) {
      case _FilterType.all:
        return _tips;
      case _FilterType.finished:
        return _tips.where((tip) => tip.isFinishedMatch).toList();
      case _FilterType.open:
        return _tips.where((tip) => !tip.isFinishedMatch).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: CustomAppBar(userName: widget.userName, backgroundColor: widget.themeColor),
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
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Row(
                children: [
                  _FilterButton(
                    label: 'Alle',
                    isSelected: _currentFilter == _FilterType.all,
                    onTap: () => setState(() => _currentFilter = _FilterType.all),
                  ),
                  _FilterButton(
                    label: 'Beendet',
                    isSelected: _currentFilter == _FilterType.finished,
                    onTap: () => setState(() => _currentFilter = _FilterType.finished),
                  ),
                  _FilterButton(
                    label: 'Offen',
                    isSelected: _currentFilter == _FilterType.open,
                    onTap: () => setState(() => _currentFilter = _FilterType.open),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.themeColor,
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

    final filteredTips = _getFilteredTips();
    if (filteredTips.isEmpty) {
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
        itemCount: filteredTips.length,
        itemBuilder: (_, i) {
          final tip = filteredTips[i];
          return _TipCard(tip: tip, themeColor: widget.themeColor);
        },
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.segmentSelected : Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.black : AppTheme.darkGray,
            ),
          ),
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final TipDto tip;
  final Color themeColor;

  const _TipCard({required this.tip, required this.themeColor});

  @override
  Widget build(BuildContext context) {
    final cardColor = tip.isFinishedMatch ? Colors.grey[200] : Colors.white;
    final statusText = tip.isFinishedMatch
        ? 'Abgeschlossen - ${tip.pointsEarned} Pt.'
        : 'Ausstehend';
    final statusColor =
        tip.isFinishedMatch ? AppTheme.darkGray : themeColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
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
                themeColor: themeColor,
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
                themeColor: themeColor,
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
  final Color themeColor;

  const _CompactTeamSection({
    required this.initials,
    required this.teamName,
    this.isRight = false,
    required this.themeColor,
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
              color: themeColor,
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
