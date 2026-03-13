import express from 'express';
import sqlite3 from 'sqlite3';
import cors from 'cors';
import path from 'path';
import { fileURLToPath } from 'url';

// Fix für __dirname in ES Modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

sqlite3.verbose();

const app = express();
const PORT = process.env.PORT || 3000;
const DB_PATH = path.join(__dirname, 'kicktipp.db');

app.use(cors());
app.use(express.json());

// SQLite Datenbank
const db = new sqlite3.Database(DB_PATH, (err) => {
  if (err) {
    console.error('Fehler beim Verbinden mit SQLite:', err.message);
    process.exit(1);
  }
  console.log('Datenbank verbunden: kicktipp.db');
});

// Helper Funktionen für async/await
const dbRun = (sql: string, params: any[] = []) => {
  return new Promise<{ id?: number; changes?: number }>((resolve, reject) => {
    db.run(sql, params, function (err) {
      if (err) reject(err);
      else resolve({ id: this.lastID, changes: this.changes });
    });
  });
};

const dbGet = (sql: string, params: any[] = []) => {
  return new Promise<any>((resolve, reject) => {
    db.get(sql, params, (err, row) => {
      if (err) reject(err);
      else resolve(row);
    });
  });
};

const dbAll = (sql: string, params: any[] = []) => {
  return new Promise<any[]>((resolve, reject) => {
    db.all(sql, params, (err, rows) => {
      if (err) reject(err);
      else resolve(rows);
    });
  });
};

// Datenbank initialisieren
async function initDatabase() {
  await dbRun(`
    CREATE TABLE IF NOT EXISTS matches (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      home_team TEXT NOT NULL,
      away_team TEXT NOT NULL,
      home_score INTEGER DEFAULT NULL,
      away_score INTEGER DEFAULT NULL,
      match_date TEXT NOT NULL,
      is_finished INTEGER DEFAULT 0,
      matchday INTEGER DEFAULT 1
    )
  `);

  await dbRun(`
    CREATE TABLE IF NOT EXISTS tips (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      match_id INTEGER NOT NULL,
      user_id INTEGER NOT NULL DEFAULT 1,
      tip_home INTEGER NOT NULL,
      tip_away INTEGER NOT NULL,
      points_earned INTEGER DEFAULT 0,
      FOREIGN KEY (match_id) REFERENCES matches(id)
    )
  `);

  console.log('Tabellen erstellt bzw. vorhanden.');

  const count = await dbGet('SELECT COUNT(*) as count FROM matches');
  if (count.count === 0) {
    const demoMatches = [
      [1, 'Bayern München', 'VfL Wolfsburg', null, null, '2025-01-11T15:30:00.000Z', 0],
      [1, 'Borussia Dortmund', 'VfB Stuttgart', null, null, '2025-01-11T18:30:00.000Z', 0],
      [1, 'RB Leipzig', 'SC Freiburg', null, null, '2025-01-12T15:30:00.000Z', 0],
      [1, 'Bayer Leverkusen', 'Eintracht Frankfurt', null, null, '2025-01-12T18:30:00.000Z', 0],
      [1, '1. FC Köln', 'Union Berlin', null, null, '2025-01-13T19:30:00.000Z', 0],
    ];

    for (const [md, home, away, hs, aw, date, finished] of demoMatches) {
      await dbRun(
        'INSERT INTO matches (matchday, home_team, away_team, home_score, away_score, match_date, is_finished) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [md, home, away, hs, aw, date, finished]
      );
    }
    console.log('Demo-Spiele eingefügt.');
  }
}

// Punkteberechnung
function calculatePoints(tipHome: number, tipAway: number, resultHome: number, resultAway: number) {
  const tipTendenz = Math.sign(tipHome - tipAway);
  const resultTendenz = Math.sign(resultHome - resultAway);

  if (tipHome === resultHome && tipAway === resultAway) return 3;
  if (tipTendenz === resultTendenz) return 1;
  return 0;
}

// API Endpunkte
app.get('/api/matchdays', async (req, res) => {
  try {
    const rows = await dbAll('SELECT DISTINCT matchday FROM matches ORDER BY matchday ASC');
    res.json(rows.map(r => r.matchday));
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Fehler beim Laden der Spieltage' });
  }
});

app.get('/api/matches', async (req, res) => {
  try {
    const matchday = req.query.matchday;
    let sql = 'SELECT * FROM matches';
    const params: any[] = [];
    if (matchday != null) {
      sql += ' WHERE matchday = ?';
      params.push(parseInt(matchday as string, 10));
    }
    sql += ' ORDER BY match_date ASC';
    const matches = await dbAll(sql, params);
    res.json(matches);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Fehler beim Laden der Spiele' });
  }
});

app.get('/api/user/:id', async (req, res) => {
  const id = parseInt(req.params.id, 10);
  if (id === 1) res.json({ id: 1, name: 'Demo User' });
  else res.status(404).json({ error: 'User nicht gefunden' });
});

app.post('/api/tips', async (req, res) => {
  const { match_id, tip_home, tip_away } = req.body;
  if (match_id == null || tip_home == null || tip_away == null) {
    return res.status(400).json({ error: 'match_id, tip_home und tip_away sind erforderlich' });
  }

  const user_id = 1;
  try {
    const match = await dbGet('SELECT id, is_finished FROM matches WHERE id = ?', [match_id]);
    if (!match) return res.status(404).json({ error: 'Spiel nicht gefunden' });
    if (match.is_finished === 1) return res.status(400).json({ error: 'Spiel beendet, Tipp nicht möglich' });

    const existing = await dbGet('SELECT id FROM tips WHERE match_id = ? AND user_id = ?', [match_id, user_id]);
    if (existing) {
      await dbRun('UPDATE tips SET tip_home = ?, tip_away = ? WHERE match_id = ? AND user_id = ?', [tip_home, tip_away, match_id, user_id]);
      res.json({ message: 'Tipp aktualisiert', match_id, tip_home, tip_away });
    } else {
      const result = await dbRun('INSERT INTO tips (match_id, user_id, tip_home, tip_away) VALUES (?, ?, ?, ?)', [match_id, user_id, tip_home, tip_away]);
      res.status(201).json({ message: 'Tipp gespeichert', id: result.id, match_id, tip_home, tip_away });
    }
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Fehler beim Speichern des Tipps' });
  }
});

app.get('/api/user/1/tips', async (req, res) => {
  try {
    const tips = await dbAll(
      `SELECT t.id, t.match_id, t.user_id, t.tip_home, t.tip_away, t.points_earned,
              m.home_team, m.away_team, m.home_score, m.away_score, m.match_date, m.is_finished
       FROM tips t
       JOIN matches m ON t.match_id = m.id
       WHERE t.user_id = 1
       ORDER BY m.match_date ASC`
    );
    res.json(tips);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Fehler beim Laden der Tipps' });
  }
});

app.get('/api/user/1/points', async (req, res) => {
  try {
    const row = await dbGet('SELECT COALESCE(SUM(points_earned), 0) as total FROM tips WHERE user_id = 1');
    res.json({ points: row.total });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Fehler beim Laden der Punkte' });
  }
});

app.put('/api/admin/match/:id', async (req, res) => {
  const matchId = parseInt(req.params.id, 10);
  const home_score = parseInt(req.body.home_score, 10);
  const away_score = parseInt(req.body.away_score, 10);

  if (isNaN(matchId) || isNaN(home_score) || isNaN(away_score)) {
    return res.status(400).json({ error: 'Ungültige Parameter' });
  }

  try {
    const match = await dbGet('SELECT id FROM matches WHERE id = ?', [matchId]);
    if (!match) return res.status(404).json({ error: 'Spiel nicht gefunden' });

    await dbRun('UPDATE matches SET home_score = ?, away_score = ?, is_finished = 1 WHERE id = ?', [home_score, away_score, matchId]);

    const tips = await dbAll('SELECT id, tip_home, tip_away FROM tips WHERE match_id = ?', [matchId]);
    for (const tip of tips) {
      const points = calculatePoints(tip.tip_home, tip.tip_away, home_score, away_score);
      await dbRun('UPDATE tips SET points_earned = ? WHERE id = ?', [points, tip.id]);
    }

    res.json({ message: 'Ergebnis gespeichert und Punkte aktualisiert', match_id: matchId, home_score, away_score });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Fehler beim Speichern des Ergebnisses' });
  }
});

// Server starten
async function start() {
  await initDatabase();
  app.listen(PORT, () => {
    console.log(`Tippspiel Backend läuft auf http://localhost:${PORT}`);
  });
}

start().catch(err => {
  console.error('Startfehler:', err);
  process.exit(1);
});