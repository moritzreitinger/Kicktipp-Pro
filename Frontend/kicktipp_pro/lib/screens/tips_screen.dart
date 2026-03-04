import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/match_card.dart';

class TipsScreen extends StatefulWidget {
  final String userName;
  final VoidCallback? onTipSaved;

  const TipsScreen({
    super.key,
    required this.userName,
    this.onTipSaved,
  });

  @override
  State<TipsScreen> createState() => _TipsScreenState();

  static _TipsScreenState? of(BuildContext context) {
    return context.findAncestorStateOfType<_TipsScreenState>();
  }
}

class _TipsScreenState extends State<TipsScreen> {
  List<int> _matchdays = [];
  int? _selectedMatchday;
  int? _selectedIndex; // Index im Array für einfacheres Navigieren
  List<MatchDto> _matches = [];
  Map<int, (int, int)> _userTips = {};
  bool _loading = true;
  String? _error;
  
  // Cache für Spieltage
  final Map<int, List<MatchDto>> _matchCache = {};

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
      
      final tipMap = <int, (int, int)>{};
      for (final t in tips) {
        tipMap[t.matchId] = (t.tipHome, t.tipAway);
      }

      setState(() {
        _matchdays = matchdays;
        _selectedIndex = 0;
        _selectedMatchday = matchdays.isNotEmpty ? matchdays.first : null;
        _userTips = tipMap;
        _loading = false;
      });
      
      // Lade gleich den ersten Spieltag
      if (_selectedMatchday != null) {
        await _loadMatchday(_selectedMatchday!);
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _loadMatchday(int matchday) async {
    // Wenn bereits gecacht, verwende den Cache
    if (_matchCache.containsKey(matchday)) {
      setState(() {
        _matches = _matchCache[matchday]!;
      });
      return;
    }

    // Sonst lade vom Backend
    setState(() => _error = null);
    try {
      final matches = await ApiService.getMatches(matchday: matchday);
      _matchCache[matchday] = matches;
      setState(() => _matches = matches);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _goToPreviousMatchday() async {
    if (_selectedIndex == null || _selectedIndex! <= 0) return;
    
    final newIndex = _selectedIndex! - 1;
    final newMatchday = _matchdays[newIndex];
    
    setState(() {
      _selectedIndex = newIndex;
      _selectedMatchday = newMatchday;
    });
    
    await _loadMatchday(newMatchday);
  }

  Future<void> _goToNextMatchday() async {
    if (_selectedIndex == null || _selectedIndex! >= _matchdays.length - 1) return;
    
    final newIndex = _selectedIndex! + 1;
    final newMatchday = _matchdays[newIndex];
    
    setState(() {
      _selectedIndex = newIndex;
      _selectedMatchday = newMatchday;
    });
    
    await _loadMatchday(newMatchday);
  }

  Future<void> refreshMatches() async {
    try {
      // Lade nur die Tipps neu
      final tips = await ApiService.getUserTips(1);
      
      final tipMap = <int, (int, int)>{};
      for (final t in tips) {
        tipMap[t.matchId] = (t.tipHome, t.tipAway);
      }

      setState(() {
        _userTips = tipMap;
      });

      // Cache invalidieren und den aktuellen Spieltag neu laden
      if (_selectedMatchday != null) {
        _matchCache.remove(_selectedMatchday);
        await _loadMatchday(_selectedMatchday!);
      }
      
      widget.onTipSaved?.call();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
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
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              'Tipps',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          if (_selectedMatchday != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(
                    children: [
                      // Linker Pfeil
                      GestureDetector(
                        onTap: _selectedIndex! > 0 ? _goToPreviousMatchday : null,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _selectedIndex! > 0
                                ? AppTheme.primaryOrange
                                : AppTheme.mediumGray,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      // Spieltag-Info Mitte
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Spieltag $_selectedMatchday',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              '${_selectedIndex! + 1}/${_matchdays.length}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.darkGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Rechter Pfeil
                      GestureDetector(
                        onTap: _selectedIndex! < _matchdays.length - 1
                            ? _goToNextMatchday
                            : null,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _selectedIndex! < _matchdays.length - 1
                                ? AppTheme.primaryOrange
                                : AppTheme.mediumGray,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
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
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    
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
            onSaved: refreshMatches,
          );
        },
      ),
    );
  }
}
