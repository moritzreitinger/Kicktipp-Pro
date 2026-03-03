import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/match_card.dart';

class TipsScreen extends StatefulWidget {
  final String userName;

  const TipsScreen({super.key, required this.userName});

  @override
  State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen> {
  List<int> _matchdays = [];
  int? _selectedMatchday;
  List<MatchDto> _matches = [];
  Map<int, (int, int)> _userTips = {};
  bool _loading = true;
  String? _error;

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
      final matchdays = await ApiService.getMatchdays();
      final tips = await ApiService.getUserTips(1);
      final matchday = matchdays.isNotEmpty ? matchdays.first : null;
      List<MatchDto> matches = [];
      if (matchday != null) {
        matches = await ApiService.getMatches(matchday: matchday);
      }

      final tipMap = <int, (int, int)>{};
      for (final t in tips) {
        tipMap[t.matchId] = (t.tipHome, t.tipAway);
      }

      setState(() {
        _matchdays = matchdays;
        _selectedMatchday = matchday;
        _matches = matches;
        _userTips = tipMap;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _onMatchdayChanged(int md) async {
    setState(() {
      _selectedMatchday = md;
      _loading = true;
    });
    try {
      final matches = await ApiService.getMatches(matchday: md);
      setState(() {
        _matches = matches;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
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
              'Match-Feed',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          if (_matchdays.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Row(
                  children: _matchdays.map((md) {
                    final isSelected = _selectedMatchday == md;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _onMatchdayChanged(md),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.segmentSelected : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Spieltag $md',
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
                  }).toList(),
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
    if (_loading && _matches.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_matches.isEmpty) {
      return const Center(
        child: Text(
          'Keine Spiele für diesen Spieltag',
          style: TextStyle(color: AppTheme.darkGray),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 100),
        itemCount: _matches.length,
        itemBuilder: (_, i) {
          final m = _matches[i];
          final tip = _userTips[m.id];
          return MatchCard(
            match: m,
            existingTipHome: tip?.$1,
            existingTipAway: tip?.$2,
            onSaved: _load,
          );
        },
      ),
    );
  }
}
