import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../utils/team_initials.dart';

class MatchCard extends StatefulWidget {
  final MatchDto match;
  final int? existingTipHome;
  final int? existingTipAway;
  final VoidCallback? onSaved;
  final Color themeColor;

  const MatchCard({
    super.key,
    required this.match,
    this.existingTipHome,
    this.existingTipAway,
    this.onSaved,
    required this.themeColor,
  });

  @override
  State<MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<MatchCard> {
  late final TextEditingController _homeController;
  late final TextEditingController _awayController;
  bool _isSaving = false;
  bool _savedSuccess = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _homeController = TextEditingController(
      text: widget.existingTipHome != null ? '${widget.existingTipHome}' : '',
    );
    _awayController = TextEditingController(
      text: widget.existingTipAway != null ? '${widget.existingTipAway}' : '',
    );
  }

  @override
  void dispose() {
    _homeController.dispose();
    _awayController.dispose();
    super.dispose();
  }

  int _calculatePoints(int tipHome, int tipAway, int resultHome, int resultAway) {
    final tipTendenz = (tipHome - tipAway).sign;
    final resultTendenz = (resultHome - resultAway).sign;

    if (tipHome == resultHome && tipAway == resultAway) {
      return 3;
    }
    if (tipTendenz == resultTendenz) {
      return 1;
    }
    return 0;
  }

  Future<void> _saveTip() async {
    final homeText = _homeController.text.trim();
    final awayText = _awayController.text.trim();
    if (homeText.isEmpty || awayText.isEmpty) {
      setState(() => _error = 'Bitte beide Tore eingeben');
      return;
    }
    final home = int.tryParse(homeText);
    final away = int.tryParse(awayText);
    if (home == null || away == null || home < 0 || away < 0) {
      setState(() => _error = 'Ungültige Eingabe');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await ApiService.saveTip(
        matchId: widget.match.id,
        tipHome: home,
        tipAway: away,
      );
      if (mounted) {
        setState(() {
          _savedSuccess = true;
          _isSaving = false;
        });
      }
      widget.onSaved?.call();
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        setState(() => _savedSuccess = false);
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isSaving = false;
      });
      return;
    }
  }

  void _incrementHome() {
    final v = int.tryParse(_homeController.text) ?? 0;
    _homeController.text = '${v + 1}';
  }

  void _decrementHome() {
    final v = int.tryParse(_homeController.text) ?? 0;
    if (v > 0) _homeController.text = '${v - 1}';
  }

  void _incrementAway() {
    final v = int.tryParse(_awayController.text) ?? 0;
    _awayController.text = '${v + 1}';
  }

  void _decrementAway() {
    final v = int.tryParse(_awayController.text) ?? 0;
    if (v > 0) _awayController.text = '${v - 1}';
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final isFinished = match.isFinishedMatch;
    final hasTip = widget.existingTipHome != null || _savedSuccess;
    final backgroundColor = _savedSuccess
        ? Colors.green.withOpacity(0.05)
        : isFinished
            ? Colors.grey[100]
            : hasTip
                ? AppTheme.lightGray
                : Colors.white;
    final borderColor = _savedSuccess ? Colors.green : Colors.transparent;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: _savedSuccess ? 2 : 0,
        ),
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
              _TeamSection(
                initials: getTeamInitials(match.homeTeam),
                teamName: match.homeTeam,
                isLeft: true,
                themeColor: widget.themeColor,
              ),
              const Spacer(),
              if (isFinished)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Tipp vs. Ergebnis
                    if (widget.existingTipHome != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'Dein Tipp: ${widget.existingTipHome}:${widget.existingTipAway}',
                          style: const TextStyle(
                            color: AppTheme.darkGray,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    Text(
                      'Ergebnis: ${match.homeScore}:${match.awayScore}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              else
                _ScoreInputSection(
                  homeController: _homeController,
                  awayController: _awayController,
                  onIncrementHome: _incrementHome,
                  onDecrementHome: _decrementHome,
                  onIncrementAway: _incrementAway,
                  onDecrementAway: _decrementAway,
                ),
              const Spacer(),
              _TeamSection(
                initials: getTeamInitials(match.awayTeam),
                teamName: match.awayTeam,
                isLeft: false,
                themeColor: widget.themeColor,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  match.homeTeam,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.darkGray,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  match.awayTeam,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.darkGray,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (isFinished && widget.existingTipHome != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: _getPointsColor(
                  _calculatePoints(
                    widget.existingTipHome!,
                    widget.existingTipAway!,
                    match.homeScore!,
                    match.awayScore!,
                  ),
                ).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Beendet',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkGray,
                    ),
                  ),
                  Text(
                    '${_calculatePoints(widget.existingTipHome!, widget.existingTipAway!, match.homeScore!, match.awayScore!)} Pt.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getPointsColor(
                        _calculatePoints(
                          widget.existingTipHome!,
                          widget.existingTipAway!,
                          match.homeScore!,
                          match.awayScore!,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (!isFinished) ...[
            if (hasTip && !_isSaving)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _savedSuccess ? Icons.check_circle : Icons.check,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _savedSuccess ? 'Tipp gespeichert!' : 'Tipp vorhanden',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
                  width: 120,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveTip,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : _savedSuccess
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check, size: 16),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'Gespeichert',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              )
                            : const Text('Speichern'),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getPointsColor(int points) {
    if (points == 3) return Colors.green;
    if (points == 1) return Colors.orange;
    return Colors.red;
  }
}

class _TeamSection extends StatelessWidget {
  final String initials;
  final String teamName;
  final bool isLeft;
  final Color themeColor;

  const _TeamSection({
    required this.initials,
    required this.teamName,
    required this.isLeft,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment:
            isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isLeft) ...[
            _TeamAvatar(initials: initials, themeColor: themeColor),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                teamName,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else ...[
            Flexible(
              child: Text(
                teamName,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 8),
            _TeamAvatar(initials: initials, themeColor: themeColor),
          ],
        ],
      ),
    );
  }
}

class _TeamAvatar extends StatelessWidget {
  final String initials;
  final Color themeColor;

  const _TeamAvatar({required this.initials, required this.themeColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: themeColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _ScoreInputSection extends StatelessWidget {
  final TextEditingController homeController;
  final TextEditingController awayController;
  final VoidCallback onIncrementHome;
  final VoidCallback onDecrementHome;
  final VoidCallback onIncrementAway;
  final VoidCallback onDecrementAway;

  const _ScoreInputSection({
    required this.homeController,
    required this.awayController,
    required this.onIncrementHome,
    required this.onDecrementHome,
    required this.onIncrementAway,
    required this.onDecrementAway,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 70,
          child: TextFormField(
            controller: homeController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 8,
              ),
              suffixIcon: Container(
                width: 24,
                margin: const EdgeInsets.only(right: 4, top: 4, bottom: 4),
                decoration: BoxDecoration(
                  color: AppTheme.darkGray,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: onIncrementHome,
                      child: const Icon(
                        Icons.keyboard_arrow_up,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                    InkWell(
                      onTap: onDecrementHome,
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              suffixIconConstraints: const BoxConstraints(maxHeight: 40),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            ':',
            style: TextStyle(
              color: AppTheme.darkGray,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(
          width: 70,
          child: TextFormField(
            controller: awayController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 8,
              ),
              suffixIcon: Container(
                width: 24,
                margin: const EdgeInsets.only(right: 4, top: 4, bottom: 4),
                decoration: BoxDecoration(
                  color: AppTheme.darkGray,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: onIncrementAway,
                      child: const Icon(
                        Icons.keyboard_arrow_up,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                    InkWell(
                      onTap: onDecrementAway,
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              suffixIconConstraints: const BoxConstraints(maxHeight: 40),
            ),
          ),
        ),
      ],
    );
  }
}
