/// Liefert die 2-Letter-Initialen für Team-Avatare (wie im Screenshot).
String getTeamInitials(String teamName) {
  const known = {
    'VfL Bochum': 'BO',
    'VfL Wolfsburg': 'WO',
    'VfB Stuttgart': 'VF',
    'Bayern München': 'FC',
    'FC Bayern München': 'FC',
    'Borussia Dortmund': 'BV',
    'RB Leipzig': 'RB',
    'Bayer Leverkusen': 'BO',
    'Bayer 04 Leverkusen': 'BO',
  };
  return known[teamName] ?? _fallbackInitials(teamName);
}

String _fallbackInitials(String name) {
  final words = name.trim().split(RegExp(r'\s+'));
  if (words.isEmpty) return '??';
  if (words.length == 1) {
    final w = words.first;
    return w.length >= 2 ? w.substring(0, 2).toUpperCase() : w.toUpperCase();
  }
  final last = words.last;
  if (last.length >= 2) return last.substring(0, 2).toUpperCase();
  return '${words.first[0]}${last[0]}'.toUpperCase();
}
