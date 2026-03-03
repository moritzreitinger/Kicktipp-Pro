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

  const MatchCard({
    super.key,
    required this.match,
    this.existingTipHome,
    this.existingTipAway,
    this.onSaved,
  });

  @override
  State<MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<MatchCard> {
  late final TextEditingController _homeController;
  late final TextEditingController _awayController;
  bool _isSaving = false;
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
      widget.onSaved?.call();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isSaving = false;
      });
      return;
    }
    setState(() => _isSaving = false);
  }

  void _incrementHome() {
    final v = int.tryParse(_homeController.text) ?? 0;
    _homeController.text = '${v + 1}';
  }

  void _decrementHome() {
    final v = int.tryParse(_homeController.text) ?? 0;
    if (v > 0) _homeController.text = '${v - 1}';
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final isFinished = match.isFinishedMatch;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _TeamSection(
                initials: getTeamInitials(match.homeTeam),
                teamName: match.homeTeam,
                isLeft: true,
              ),
              const Spacer(),
              if (isFinished)
                Text(
                  'Endergebnis: ${match.homeScore}:${match.awayScore}',
                  style: const TextStyle(
                    color: AppTheme.darkGray,
                    fontSize: 14,
                  ),
                )
              else
                _ScoreInputSection(
                  homeController: _homeController,
                  awayController: _awayController,
                  onIncrementHome: _incrementHome,
                  onDecrementHome: _decrementHome,
                ),
              const Spacer(),
              _TeamSection(
                initials: getTeamInitials(match.awayTeam),
                teamName: match.awayTeam,
                isLeft: false,
              ),
            ],
          ),
          if (!isFinished) ...[
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
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
}

class _TeamSection extends StatelessWidget {
  final String initials;
  final String teamName;
  final bool isLeft;

  const _TeamSection({
    required this.initials,
    required this.teamName,
    required this.isLeft,
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
            _TeamAvatar(initials: initials),
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
            _TeamAvatar(initials: initials),
          ],
        ],
      ),
    );
  }
}

class _TeamAvatar extends StatelessWidget {
  final String initials;

  const _TeamAvatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.primaryOrange,
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

  const _ScoreInputSection({
    required this.homeController,
    required this.awayController,
    required this.onIncrementHome,
    required this.onDecrementHome,
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
          width: 56,
          child: TextFormField(
            controller: awayController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ],
    );
  }
}
