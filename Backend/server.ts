import express, { Express, Request, Response } from 'express';
import cors from 'cors';

const app: Express = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

interface Match {
  id: number;
  matchday: number;
  homeTeam: string;
  awayTeam: string;
  homeScore: number | null;
  awayScore: number | null;
  matchDate: string;
  isFinished: boolean;
}

interface Tip {
  id: number;
  matchId: number;
  userId: number;
  tipHome: number;
  tipAway: number;
  pointsEarned: number;
  homeTeam?: string;
  awayTeam?: string;
  homeScore?: number | null;
  awayScore?: number | null;
  matchDate?: string;
  isFinished?: boolean;
}

interface User {
  id: number;
  name: string;
}

class Database {
  private matches: Map<number, Match> = new Map();
  private tips: Map<number, Tip> = new Map();
  private matchIdCounter: number = 1;
  private tipIdCounter: number = 1;

  constructor() {
    this.initSampleData();
  }

  private initSampleData(): void {
    const demoMatches = [
      // Spieltag 1
      [1, 'Bayern München', 'VfL Wolfsburg', null, null, '2025-01-11T15:30:00.000Z', false],
      [1, 'Borussia Dortmund', 'VfB Stuttgart', null, null, '2025-01-11T18:30:00.000Z', false],
      [1, 'RB Leipzig', 'SC Freiburg', null, null, '2025-01-12T15:30:00.000Z', false],
      [1, 'Bayer Leverkusen', 'Eintracht Frankfurt', null, null, '2025-01-12T18:30:00.000Z', false],
      [1, '1. FC Köln', 'Union Berlin', null, null, '2025-01-13T19:30:00.000Z', false],
      // Spieltag 2
      [2, 'TSG Hoffenheim', 'Bayern München', null, null, '2025-01-18T15:30:00.000Z', false],
      [2, 'SC Freiburg', 'Borussia Dortmund', null, null, '2025-01-18T18:30:00.000Z', false],
      [2, 'VfB Stuttgart', 'RB Leipzig', null, null, '2025-01-19T15:30:00.000Z', false],
      [2, 'Eintracht Frankfurt', 'Bayer Leverkusen', null, null, '2025-01-19T18:30:00.000Z', false],
      [2, 'VfL Wolfsburg', 'Mainz 05', null, null, '2025-01-20T20:30:00.000Z', false],
      // Spieltag 3
      [3, 'Bayern München', 'Mainz 05', null, null, '2025-01-25T15:30:00.000Z', false],
      [3, 'Borussia Dortmund', 'Bayer Leverkusen', null, null, '2025-01-25T18:30:00.000Z', false],
      [3, 'RB Leipzig', 'TSG Hoffenheim', null, null, '2025-01-26T15:30:00.000Z', false],
      [3, 'Union Berlin', 'SC Freiburg', null, null, '2025-01-26T18:30:00.000Z', false],
      [3, 'FC Augsburg', 'VfB Stuttgart', null, null, '2025-01-27T19:30:00.000Z', false],
      // Spieltag 4
      [4, 'VfL Wolfsburg', 'Bayern München', null, null, '2025-02-01T15:30:00.000Z', false],
      [4, 'Bayer Leverkusen', 'RB Leipzig', null, null, '2025-02-01T18:30:00.000Z', false],
      [4, 'SC Freiburg', 'Borussia Dortmund', null, null, '2025-02-02T15:30:00.000Z', false],
      [4, 'Mainz 05', 'Union Berlin', null, null, '2025-02-02T18:30:00.000Z', false],
      [4, 'VfB Stuttgart', 'Eintracht Frankfurt', null, null, '2025-02-03T19:30:00.000Z', false],
      // Spieltag 5
      [5, 'Bayern München', 'TSG Hoffenheim', null, null, '2025-02-08T15:30:00.000Z', false],
      [5, 'Borussia Dortmund', 'FC Augsburg', null, null, '2025-02-08T18:30:00.000Z', false],
      [5, 'RB Leipzig', 'VfB Stuttgart', null, null, '2025-02-09T15:30:00.000Z', false],
      [5, 'Eintracht Frankfurt', 'VfL Wolfsburg', null, null, '2025-02-09T18:30:00.000Z', false],
      [5, '1. FC Köln', 'Bayer Leverkusen', null, null, '2025-02-10T20:30:00.000Z', false],
      // Spieltag 6
      [6, 'SC Freiburg', 'Bayern München', null, null, '2025-02-15T15:30:00.000Z', false],
      [6, 'VfL Wolfsburg', 'RB Leipzig', null, null, '2025-02-15T18:30:00.000Z', false],
      [6, 'Union Berlin', 'Borussia Dortmund', null, null, '2025-02-16T15:30:00.000Z', false],
      [6, 'Mainz 05', 'Bayer Leverkusen', null, null, '2025-02-16T18:30:00.000Z', false],
      [6, 'VfB Stuttgart', 'TSG Hoffenheim', null, null, '2025-02-17T19:30:00.000Z', false],
      // Spieltag 7
      [7, 'Bayern München', 'Borussia Dortmund', 1, 2, '2025-02-22T18:30:00.000Z', true],
      [7, 'RB Leipzig', 'Bayer Leverkusen', null, null, '2025-02-23T15:30:00.000Z', false],
      [7, 'Bayer Leverkusen', 'VfL Wolfsburg', null, null, '2025-02-23T18:30:00.000Z', false],
      [7, 'Eintracht Frankfurt', 'SC Freiburg', null, null, '2025-02-24T19:30:00.000Z', false],
      [7, 'FC Augsburg', 'Union Berlin', null, null, '2025-02-25T19:30:00.000Z', false],
      // Spieltag 8
      [8, 'Borussia Dortmund', 'VfB Stuttgart', null, null, '2025-03-01T15:30:00.000Z', false],
      [8, 'TSG Hoffenheim', 'RB Leipzig', null, null, '2025-03-01T18:30:00.000Z', false],
      [8, 'VfL Wolfsburg', 'SC Freiburg', null, null, '2025-03-02T15:30:00.000Z', false],
      [8, 'Union Berlin', 'Eintracht Frankfurt', null, null, '2025-03-02T18:30:00.000Z', false],
      [8, 'Mainz 05', 'Bayern München', null, null, '2025-03-03T20:30:00.000Z', false],
      // Spieltag 9
      [9, 'Bayern München', 'FC Augsburg', null, null, '2025-03-08T15:30:00.000Z', false],
      [9, 'RB Leipzig', 'Borussia Dortmund', null, null, '2025-03-08T18:30:00.000Z', false],
      [9, 'Bayer Leverkusen', 'TSG Hoffenheim', null, null, '2025-03-09T15:30:00.000Z', false],
      [9, 'SC Freiburg', 'VfL Wolfsburg', null, null, '2025-03-09T18:30:00.000Z', false],
      [9, 'VfB Stuttgart', 'Mainz 05', null, null, '2025-03-10T19:30:00.000Z', false],
      // Spieltag 10
      [10, 'Eintracht Frankfurt', 'Bayer Leverkusen', null, null, '2025-03-15T15:30:00.000Z', false],
      [10, 'Union Berlin', 'Bayern München', null, null, '2025-03-15T18:30:00.000Z', false],
      [10, 'TSG Hoffenheim', 'VfB Stuttgart', null, null, '2025-03-16T15:30:00.000Z', false],
      [10, 'FC Augsburg', 'RB Leipzig', null, null, '2025-03-16T18:30:00.000Z', false],
      [10, '1. FC Köln', 'Borussia Dortmund', null, null, '2025-03-17T19:30:00.000Z', false],
      // Spieltag 11
      [11, 'Borussia Dortmund', 'Mainz 05', null, null, '2025-03-22T15:30:00.000Z', false],
      [11, 'VfL Wolfsburg', 'Union Berlin', null, null, '2025-03-22T18:30:00.000Z', false],
      [11, 'Bayern München', 'SC Freiburg', null, null, '2025-03-23T15:30:00.000Z', false],
      [11, 'RB Leipzig', 'Eintracht Frankfurt', null, null, '2025-03-23T18:30:00.000Z', false],
      [11, 'VfB Stuttgart', 'Bayer Leverkusen', null, null, '2025-03-24T19:30:00.000Z', false],
      // Spieltag 12
      [12, 'Bayer Leverkusen', 'FC Augsburg', null, null, '2025-03-29T15:30:00.000Z', false],
      [12, 'TSG Hoffenheim', 'Borussia Dortmund', null, null, '2025-03-29T18:30:00.000Z', false],
      [12, 'SC Freiburg', 'RB Leipzig', null, null, '2025-03-30T15:30:00.000Z', false],
      [12, 'Mainz 05', 'VfL Wolfsburg', null, null, '2025-03-30T18:30:00.000Z', false],
      [12, 'Eintracht Frankfurt', 'Bayern München', null, null, '2025-03-31T20:30:00.000Z', false],
      // Spieltag 13
      [13, 'Bayern München', 'VfB Stuttgart', null, null, '2025-04-05T15:30:00.000Z', false],
      [13, 'RB Leipzig', 'Union Berlin', null, null, '2025-04-05T18:30:00.000Z', false],
      [13, 'Borussia Dortmund', 'SC Freiburg', null, null, '2025-04-06T15:30:00.000Z', false],
      [13, 'VfL Wolfsburg', 'Bayer Leverkusen', null, null, '2025-04-06T18:30:00.000Z', false],
      [13, 'FC Augsburg', 'TSG Hoffenheim', null, null, '2025-04-07T19:30:00.000Z', false],
      // Spieltag 14
      [14, 'Union Berlin', 'VfB Stuttgart', null, null, '2025-04-12T15:30:00.000Z', false],
      [14, 'Eintracht Frankfurt', 'Mainz 05', null, null, '2025-04-12T18:30:00.000Z', false],
      [14, 'SC Freiburg', 'Bayer Leverkusen', null, null, '2025-04-13T15:30:00.000Z', false],
      [14, 'TSG Hoffenheim', 'VfL Wolfsburg', null, null, '2025-04-13T18:30:00.000Z', false],
      [14, 'Bayern München', 'RB Leipzig', null, null, '2025-04-14T20:30:00.000Z', false],
      // Spieltag 15
      [15, 'Borussia Dortmund', 'Eintracht Frankfurt', null, null, '2025-04-19T15:30:00.000Z', false],
      [15, 'RB Leipzig', 'FC Augsburg', null, null, '2025-04-19T18:30:00.000Z', false],
      [15, 'VfB Stuttgart', 'Bayern München', null, null, '2025-04-20T15:30:00.000Z', false],
      [15, 'Bayer Leverkusen', 'Union Berlin', null, null, '2025-04-20T18:30:00.000Z', false],
      [15, 'VfL Wolfsburg', 'SC Freiburg', null, null, '2025-04-21T19:30:00.000Z', false],
      // Spieltag 16
      [16, 'Bayern München', 'TSG Hoffenheim', null, null, '2025-04-26T15:30:00.000Z', false],
      [16, 'SC Freiburg', 'Borussia Dortmund', null, null, '2025-04-26T18:30:00.000Z', false],
      [16, 'Mainz 05', 'RB Leipzig', null, null, '2025-04-27T15:30:00.000Z', false],
      [16, 'Union Berlin', 'Bayer Leverkusen', null, null, '2025-04-27T18:30:00.000Z', false],
      [16, 'Eintracht Frankfurt', 'VfL Wolfsburg', null, null, '2025-04-28T19:30:00.000Z', false],
      // Spieltag 17
      [17, 'Borussia Dortmund', 'VfL Wolfsburg', null, null, '2025-05-03T15:30:00.000Z', false],
      [17, 'RB Leipzig', 'Bayern München', null, null, '2025-05-03T18:30:00.000Z', false],
      [17, 'TSG Hoffenheim', 'Bayer Leverkusen', null, null, '2025-05-04T15:30:00.000Z', false],
      [17, 'VfB Stuttgart', 'SC Freiburg', null, null, '2025-05-04T18:30:00.000Z', false],
      [17, 'FC Augsburg', 'Union Berlin', null, null, '2025-05-05T19:30:00.000Z', false],
      // Spieltag 18
      [18, 'Bayern München', 'Eintracht Frankfurt', null, null, '2025-05-10T15:30:00.000Z', false],
      [18, 'Bayer Leverkusen', 'Borussia Dortmund', null, null, '2025-05-10T18:30:00.000Z', false],
      [18, 'VfL Wolfsburg', 'RB Leipzig', null, null, '2025-05-11T15:30:00.000Z', false],
      [18, 'SC Freiburg', 'TSG Hoffenheim', null, null, '2025-05-11T18:30:00.000Z', false],
      [18, 'Union Berlin', 'Mainz 05', null, null, '2025-05-12T20:30:00.000Z', false],
      // Spieltag 19
      [19, 'Borussia Dortmund', 'Bayern München', null, null, '2025-05-17T15:30:00.000Z', false],
      [19, 'RB Leipzig', 'VfB Stuttgart', null, null, '2025-05-17T18:30:00.000Z', false],
      [19, 'Mainz 05', 'Bayer Leverkusen', null, null, '2025-05-18T15:30:00.000Z', false],
      [19, 'Eintracht Frankfurt', 'FC Augsburg', null, null, '2025-05-18T18:30:00.000Z', false],
      [19, 'TSG Hoffenheim', 'Union Berlin', null, null, '2025-05-19T19:30:00.000Z', false],
      // Spieltag 20
      [20, 'Bayern München', 'VfL Wolfsburg', null, null, '2025-05-24T15:30:00.000Z', false],
      [20, 'SC Freiburg', 'RB Leipzig', null, null, '2025-05-24T18:30:00.000Z', false],
      [20, 'VfB Stuttgart', 'Borussia Dortmund', null, null, '2025-05-25T15:30:00.000Z', false],
      [20, 'Union Berlin', 'Bayer Leverkusen', null, null, '2025-05-25T18:30:00.000Z', false],
      [20, 'FC Augsburg', 'TSG Hoffenheim', null, null, '2025-05-26T19:30:00.000Z', false],
      // Spieltag 21
      [21, 'Bayer Leverkusen', 'Bayern München', null, null, '2025-05-31T15:30:00.000Z', false],
      [21, 'RB Leipzig', 'Eintracht Frankfurt', null, null, '2025-05-31T18:30:00.000Z', false],
      [21, 'Borussia Dortmund', 'Union Berlin', null, null, '2025-06-01T15:30:00.000Z', false],
      [21, 'TSG Hoffenheim', 'VfL Wolfsburg', null, null, '2025-06-01T18:30:00.000Z', false],
      [21, 'SC Freiburg', 'Mainz 05', null, null, '2025-06-02T19:30:00.000Z', false],
      // Spieltag 22
      [22, 'Bayern München', 'Borussia Dortmund', null, null, '2025-06-07T15:30:00.000Z', false],
      [22, 'VfL Wolfsburg', 'Bayer Leverkusen', null, null, '2025-06-07T18:30:00.000Z', false],
      [22, 'VfB Stuttgart', 'RB Leipzig', null, null, '2025-06-08T15:30:00.000Z', false],
      [22, 'Union Berlin', 'SC Freiburg', null, null, '2025-06-08T18:30:00.000Z', false],
      [22, 'Eintracht Frankfurt', 'TSG Hoffenheim', null, null, '2025-06-09T19:30:00.000Z', false],
    ];

    for (const [matchday, homeTeam, awayTeam, homeScore, awayScore, matchDate, isFinished] of demoMatches) {
      this.matches.set(this.matchIdCounter, {
        id: this.matchIdCounter,
        matchday: matchday as number,
        homeTeam: homeTeam as string,
        awayTeam: awayTeam as string,
        homeScore: homeScore as number | null,
        awayScore: awayScore as number | null,
        matchDate: matchDate as string,
        isFinished: isFinished as boolean,
      });
      this.matchIdCounter++;
    }

    console.log('Demo-Spiele (Spieltag 1–22) geladen.');
  }

  getMatches(matchday?: number): Match[] {
    let matches = Array.from(this.matches.values());
    if (matchday !== undefined) {
      matches = matches.filter(m => m.matchday === matchday);
    }
    return matches.sort((a, b) => new Date(a.matchDate).getTime() - new Date(b.matchDate).getTime());
  }

  getMatchById(id: number): Match | undefined {
    return this.matches.get(id);
  }

  updateMatch(id: number, homeScore: number, awayScore: number): Match | undefined {
    const match = this.matches.get(id);
    if (match) {
      match.homeScore = homeScore;
      match.awayScore = awayScore;
      match.isFinished = true;
    }
    return match;
  }

  getMatchdays(): number[] {
    const matchdays = new Set<number>();
    this.matches.forEach(match => matchdays.add(match.matchday));
    return Array.from(matchdays).sort((a, b) => a - b);
  }

  addTip(matchId: number, userId: number, tipHome: number, tipAway: number): Tip {
    const tip: Tip = {
      id: this.tipIdCounter++,
      matchId,
      userId,
      tipHome,
      tipAway,
      pointsEarned: 0,
    };
    this.tips.set(tip.id, tip);
    return tip;
  }

  getTipByMatchAndUser(matchId: number, userId: number): Tip | undefined {
    return Array.from(this.tips.values()).find(t => t.matchId === matchId && t.userId === userId);
  }

  updateTip(id: number, tipHome: number, tipAway: number): Tip | undefined {
    const tip = this.tips.get(id);
    if (tip) {
      tip.tipHome = tipHome;
      tip.tipAway = tipAway;
    }
    return tip;
  }

  getTipsByUser(userId: number): Tip[] {
    const tips = Array.from(this.tips.values()).filter(t => t.userId === userId);
    return tips.map(tip => {
      const match = this.matches.get(tip.matchId);
      return {
        ...tip,
        homeTeam: match?.homeTeam,
        awayTeam: match?.awayTeam,
        homeScore: match?.homeScore,
        awayScore: match?.awayScore,
        matchDate: match?.matchDate,
        isFinished: match?.isFinished,
      };
    }).sort((a, b) => new Date(a.matchDate!).getTime() - new Date(b.matchDate!).getTime());
  }

  getTotalPoints(userId: number): number {
    return Array.from(this.tips.values())
      .filter(t => t.userId === userId)
      .reduce((sum, tip) => sum + tip.pointsEarned, 0);
  }

  getTipsByMatch(matchId: number): Tip[] {
    return Array.from(this.tips.values()).filter(t => t.matchId === matchId);
  }

  updateTipPoints(tipId: number, points: number): void {
    const tip = this.tips.get(tipId);
    if (tip) {
      tip.pointsEarned = points;
    }
  }
}

const db = new Database();

// ============ Utility Functions ============

function calculatePoints(tipHome: number, tipAway: number, resultHome: number, resultAway: number): number {
  const tipTendency = Math.sign(tipHome - tipAway);
  const resultTendency = Math.sign(resultHome - resultAway);

  if (tipHome === resultHome && tipAway === resultAway) {
    return 3;
  }
  if (tipTendency === resultTendency) {
    return 1;
  }
  return 0;
}

// ============ Routes ============

app.get('/api/matchdays', (req: Request, res: Response) => {
  try {
    const matchdays = db.getMatchdays();
    res.json(matchdays);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Fehler beim Laden der Spieltage' });
  }
});

app.get('/api/matches', (req: Request, res: Response) => {
  try {
    const matchday = req.query.matchday ? parseInt(req.query.matchday as string, 10) : undefined;
    const matches = db.getMatches(matchday);
    res.json(matches);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Fehler beim Laden der Spiele' });
  }
});

app.get('/api/user/:id', (req: Request, res: Response) => {
  try {
    const id = parseInt(req.params.id, 10);
    if (id === 1) {
      res.json({ id: 1, name: 'Demo User' });
    } else {
      res.status(404).json({ error: 'User nicht gefunden' });
    }
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Fehler beim Laden des Users' });
  }
});

app.post('/api/tips', (req: Request, res: Response) => {
  try {
    const { match_id, tip_home, tip_away } = req.body;

    if (match_id == null || tip_home == null || tip_away == null) {
      return res.status(400).json({
        error: 'match_id, tip_home und tip_away sind erforderlich',
      });
    }

    const userId = 1;
    const match = db.getMatchById(match_id);

    if (!match) {
      return res.status(404).json({ error: 'Spiel nicht gefunden' });
    }

    if (match.isFinished) {
      return res.status(400).json({ error: 'Spiel bereits beendet, Tipp kann nicht mehr geändert werden' });
    }

    const existing = db.getTipByMatchAndUser(match_id, userId);

    if (existing) {
      db.updateTip(existing.id, tip_home, tip_away);
      res.json({
        message: 'Tipp aktualisiert',
        match_id,
        tip_home,
        tip_away,
      });
    } else {
      const tip = db.addTip(match_id, userId, tip_home, tip_away);
      res.status(201).json({
        message: 'Tipp gespeichert',
        id: tip.id,
        match_id,
        tip_home,
        tip_away,
      });
    }
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Fehler beim Speichern des Tipps' });
  }
});

app.get('/api/user/1/tips', (req: Request, res: Response) => {
  try {
    const tips = db.getTipsByUser(1);
    res.json(tips);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Fehler beim Laden der Tipps' });
  }
});

app.get('/api/user/1/points', (req: Request, res: Response) => {
  try {
    const points = db.getTotalPoints(1);
    res.json({ points });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Fehler beim Laden der Punkte' });
  }
});

app.put('/api/admin/match/:id', (req: Request, res: Response) => {
  try {
    const matchId = parseInt(req.params.id, 10);
    const homeScore = parseInt(req.body.home_score, 10);
    const awayScore = parseInt(req.body.away_score, 10);

    if (isNaN(matchId)) {
      return res.status(400).json({ error: 'Ungültige Match-ID' });
    }

    if (isNaN(homeScore) || isNaN(awayScore)) {
      return res.status(400).json({
        error: 'home_score und away_score müssen als Zahlen übergeben werden',
      });
    }

    const match = db.getMatchById(matchId);
    if (!match) {
      return res.status(404).json({ error: 'Spiel nicht gefunden' });
    }

    db.updateMatch(matchId, homeScore, awayScore);

    const tips = db.getTipsByMatch(matchId);
    for (const tip of tips) {
      const points = calculatePoints(tip.tipHome, tip.tipAway, homeScore, awayScore);
      db.updateTipPoints(tip.id, points);
    }

    res.json({
      message: 'Ergebnis gespeichert und Punkte aktualisiert',
      match_id: matchId,
      home_score: homeScore,
      away_score: awayScore,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Fehler beim Speichern des Ergebnisses' });
  }
});

// ============ Start Server ============

app.listen(PORT, () => {
  console.log(`Tippspiel Backend läuft auf http://localhost:${PORT}`);
  console.log('API Endpunkte:');
  console.log('  GET  /api/matchdays       - Alle Spieltage');
  console.log('  GET  /api/matches         - Alle Spiele');
  console.log('  POST /api/tips            - Tipp abgeben');
  console.log('  GET  /api/user/1/tips     - Tipps des Users');
  console.log('  GET  /api/user/1/points   - Gesamtpunktzahl');
  console.log('  PUT  /api/admin/match/:id - Ergebnis setzen');
});
