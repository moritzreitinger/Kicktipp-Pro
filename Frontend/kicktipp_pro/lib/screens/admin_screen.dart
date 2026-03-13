import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../widgets/custom_app_bar.dart';

class AdminScreen extends StatefulWidget {
  final String userName;
  final VoidCallback? onResultSaved;
  final Color themeColor;

  const AdminScreen({
    super.key,
    required this.userName,
    this.onResultSaved,
    required this.themeColor,
  });

  @override
  State<AdminScreen> createState() => _AdminScreenState();

  static _AdminScreenState? of(BuildContext context) {
    return context.findAncestorStateOfType<_AdminScreenState>();
  }
}

class _AdminScreenState extends State<AdminScreen> {
  List<int> _matchdays = [];
  int? _selectedMatchday;
  int? _selectedIndex;
  List<MatchDto> _openMatches = [];
  bool _loading = true;
  String? _error;
  late Map<int, (TextEditingController, TextEditingController)> _controllers;
  
  // Cache für Spieltage
  final Map<int, List<MatchDto>> _matchCache = {};

  @override
  void initState() {
    super.initState();
    _controllers = {};
    _load();
  }

  @override
  void dispose() {
    for (final (home, away) in _controllers.values) {
      home.dispose();
      away.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final matchdays = await ApiService.getMatchdays();
      final allMatches = await ApiService.getMatches();
      final openByDay = <int, List<MatchDto>>{};
      
      // Gruppiere offene Spiele nach Spieltag
      for (final match in allMatches) {
        if (!match.isFinishedMatch) {
          openByDay.putIfAbsent(match.matchday, () => []).add(match);
        }
      }
      
      setState(() {
        _matchdays = matchdays.where((md) => openByDay.containsKey(md)).toList();
        _selectedIndex = 0;
        _selectedMatchday = _matchdays.isNotEmpty ? _matchdays.first : null;
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
    late List<MatchDto> openMatches;
    
    // Wenn bereits gecacht, verwende den Cache
    if (_matchCache.containsKey(matchday)) {
      openMatches = _matchCache[matchday]!;
    } else {
      // Sonst lade vom Backend
      setState(() => _error = null);
      try {
        final matches = await ApiService.getMatches(matchday: matchday);
        openMatches = matches.where((m) => !m.isFinishedMatch).toList();
        _matchCache[matchday] = openMatches;
      } catch (e) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
        });
        return;
      }
    }
    
    // Erstelle Controller für jedes offene Spiel (immer, auch wenn gecacht)
    _controllers.clear();
    for (final match in openMatches) {
      _controllers[match.id] = (
        TextEditingController(),
        TextEditingController(),
      );
    }
    
    setState(() => _openMatches = openMatches);
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
    // Cache invalidieren und nur den aktuellen Spieltag neu laden
    if (_selectedMatchday != null) {
      _matchCache.remove(_selectedMatchday);
      await _loadMatchday(_selectedMatchday!);
    }
  }

  Future<void> _saveResult(MatchDto match) async {
    final (homeController, awayController) = _controllers[match.id]!;
    final homeText = homeController.text.trim();
    final awayText = awayController.text.trim();

    if (homeText.isEmpty || awayText.isEmpty) {
      _showError('Bitte beide Ergebnisse eingeben');
      return;
    }

    final home = int.tryParse(homeText);
    final away = int.tryParse(awayText);

    if (home == null || away == null || home < 0 || away < 0) {
      _showError('Ungültige Eingabe');
      return;
    }

    try {
      await ApiService.setMatchResult(
        matchId: match.id,
        homeScore: home,
        awayScore: away,
      );
      
      // Cache invalidieren und neu laden damit das Spiel verschwindet
      _matchCache.clear();
      widget.onResultSaved?.call();
      
      // Überprüfe ob Benachrichtigungen aktiviert sind
      try {
        final prefs = await SharedPreferences.getInstance();
        final notificationsEnabled = prefs.getBool('push_notifications') ?? false;
        if (notificationsEnabled && mounted) {
          NotificationService().showNotification(
            context: context,
            message: '✅ Ergebnis für ${match.homeTeam} - ${match.awayTeam} gespeichert',
            backgroundColor: widget.themeColor,
          );
        }
      } catch (_) {}
      
      // Refresh den aktuellen Spieltag
      if (_selectedMatchday != null) {
        await _loadMatchday(_selectedMatchday!);
      }
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
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
              'Admin-Panel',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          // Spieltag Navigation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: _loading
                ? const SizedBox(height: 40, child: Center(child: CircularProgressIndicator()))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: _selectedIndex != null && _selectedIndex! > 0
                            ? _goToPreviousMatchday
                            : null,
                        icon: const Icon(Icons.arrow_left),
                        tooltip: 'Vorheriger Spieltag',
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            _selectedMatchday != null && _selectedIndex != null
                                ? 'Spieltag ${_selectedMatchday} (${_selectedIndex! + 1}/${_matchdays.length})'
                                : 'Keine Spieltage',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _selectedIndex != null && _selectedIndex! < _matchdays.length - 1
                            ? _goToNextMatchday
                            : null,
                        icon: const Icon(Icons.arrow_right),
                        tooltip: 'Nächster Spieltag',
                      ),
                    ],
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

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_openMatches.isEmpty) {
      return const Center(
        child: Text(
          'Keine offenen Spiele',
          style: TextStyle(color: AppTheme.darkGray),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Offene Spiele (${_openMatches.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkGray,
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _openMatches.length,
            itemBuilder: (_, i) {
              final match = _openMatches[i];
              return _AdminMatchCard(
                match: match,
                homeController: _controllers[match.id]!.$1,
                awayController: _controllers[match.id]!.$2,
                onSave: () => _saveResult(match),
                themeColor: widget.themeColor,
              );
            },
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _AdminMatchCard extends StatefulWidget {
  final MatchDto match;
  final TextEditingController homeController;
  final TextEditingController awayController;
  final VoidCallback onSave;
  final Color themeColor;

  const _AdminMatchCard({
    required this.match,
    required this.homeController,
    required this.awayController,
    required this.onSave,
    required this.themeColor,
  });

  @override
  State<_AdminMatchCard> createState() => _AdminMatchCardState();
}

class _AdminMatchCardState extends State<_AdminMatchCard> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final match = widget.match;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
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
          Text(
            'Spieltag ${match.matchday}',
            style: const TextStyle(
              color: AppTheme.darkGray,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      match.homeTeam,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: _ScoreInput(
                  controller: widget.homeController,
                  label: 'Tore',
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  ':',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: _ScoreInput(
                  controller: widget.awayController,
                  label: 'Tore',
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      match.awayTeam,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : () async {
                setState(() => _isSaving = true);
                try {
                  widget.onSave();
                } finally {
                  if (mounted) {
                    setState(() => _isSaving = false);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.themeColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text(
                      'Punkte berechnen & verteilen',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _ScoreInput({
    required this.controller,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(2),
      ],
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        filled: true,
        fillColor: AppTheme.lightGray,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        hintText: '0',
        hintStyle: const TextStyle(color: AppTheme.mediumGray),
      ),
    );
  }
}
