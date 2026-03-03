import 'dart:convert';
import 'package:http/http.dart' as http;

// Für Android-Emulator: 10.0.2.2 statt localhost
// Bei physischem Gerät: IP deines Rechners im lokalen Netz
const String _apiHost = 'localhost';

class ApiService {
  static String get baseUrl => 'http://$_apiHost:3000';

  static Future<List<int>> getMatchdays() async {
    final res = await http.get(Uri.parse('$baseUrl/api/matchdays'));
    if (res.statusCode != 200) throw Exception('Fehler beim Laden der Spieltage');
    final list = jsonDecode(res.body) as List;
    return list.map((e) => (e as num).toInt()).toList();
  }

  static Future<List<MatchDto>> getMatches({int? matchday}) async {
    final uri = matchday != null
        ? Uri.parse('$baseUrl/api/matches?matchday=$matchday')
        : Uri.parse('$baseUrl/api/matches');
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('Fehler beim Laden der Spiele');
    final list = jsonDecode(res.body) as List;
    return list.map((e) => MatchDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<UserDto> getUser(int id) async {
    final res = await http.get(Uri.parse('$baseUrl/api/user/$id'));
    if (res.statusCode != 200) throw Exception('Fehler beim Laden des Users');
    return UserDto.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<List<TipDto>> getUserTips(int userId) async {
    final res = await http.get(Uri.parse('$baseUrl/api/user/$userId/tips'));
    if (res.statusCode != 200) throw Exception('Fehler beim Laden der Tipps');
    final list = jsonDecode(res.body) as List;
    return list.map((e) => TipDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> saveTip({
    required int matchId,
    required int tipHome,
    required int tipAway,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/tips'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'match_id': matchId,
        'tip_home': tipHome,
        'tip_away': tipAway,
      }),
    );
    if (res.statusCode >= 400) {
      final body = jsonDecode(res.body);
      throw Exception(body['error'] ?? 'Fehler beim Speichern');
    }
  }
}

class MatchDto {
  final int id;
  final String homeTeam;
  final String awayTeam;
  final int? homeScore;
  final int? awayScore;
  final String matchDate;
  final int isFinished;
  final int matchday;

  MatchDto({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    this.homeScore,
    this.awayScore,
    required this.matchDate,
    required this.isFinished,
    required this.matchday,
  });

  factory MatchDto.fromJson(Map<String, dynamic> json) {
    return MatchDto(
      id: json['id'] as int,
      homeTeam: json['home_team'] as String,
      awayTeam: json['away_team'] as String,
      homeScore: json['home_score'] as int?,
      awayScore: json['away_score'] as int?,
      matchDate: json['match_date'] as String,
      isFinished: (json['is_finished'] ?? 0) as int,
      matchday: (json['matchday'] ?? 1) as int,
    );
  }

  bool get isFinishedMatch => isFinished == 1;
}

class UserDto {
  final int id;
  final String name;

  UserDto({required this.id, required this.name});

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

class TipDto {
  final int matchId;
  final int tipHome;
  final int tipAway;

  TipDto({
    required this.matchId,
    required this.tipHome,
    required this.tipAway,
  });

  factory TipDto.fromJson(Map<String, dynamic> json) {
    return TipDto(
      matchId: json['match_id'] as int,
      tipHome: json['tip_home'] as int,
      tipAway: json['tip_away'] as int,
    );
  }
}
