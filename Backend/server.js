const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const cors = require('cors');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;
const DB_PATH = path.join(__dirname, 'tippspiel.db');

app.use(cors());
app.use(express.json());

const db = new sqlite3.Database(DB_PATH, (err) => {
  if (err) {
    console.error('Fehler beim Verbinden mit SQLite:', err.message);
    process.exit(1);
  }
  console.log('Datenbank verbunden: tippspiel.db');
});

const dbRun = (sql, params = []) => {
  return new Promise((resolve, reject) => {
    db.run(sql, params, function (err) {
      if (err) reject(err);
      else resolve({ id: this.lastID, changes: this.changes });
    });
  });
};

const dbGet = (sql, params = []) => {
  return new Promise((resolve, reject) => {
    db.get(sql, params, (err, row) => {
      if (err) reject(err);
      else resolve(row);
    });
  });
};

const dbAll = (sql, params = []) => {
  return new Promise((resolve, reject) => {
    db.all(sql, params, (err, rows) => {
      if (err) reject(err);
      else resolve(rows);
    });
  });
};

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

  // matchday-Spalte nachträglich hinzufügen falls Tabelle bereits existiert
  try {
    await dbRun('ALTER TABLE matches ADD COLUMN matchday INTEGER DEFAULT 1');
  } catch (e) {
    // Spalte existiert bereits
  }

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
      // Spieltag 1
      [1, 'Bayern München', 'VfL Wolfsburg', null, null, '2025-01-11T15:30:00.000Z', 0],
      [1, 'Borussia Dortmund', 'VfB Stuttgart', null, null, '2025-01-11T18:30:00.000Z', 0],
      [1, 'RB Leipzig', 'SC Freiburg', null, null, '2025-01-12T15:30:00.000Z', 0],
      [1, 'Bayer Leverkusen', 'Eintracht Frankfurt', null, null, '2025-01-12T18:30:00.000Z', 0],
      [1, '1. FC Köln', 'Union Berlin', null, null, '2025-01-13T19:30:00.000Z', 0],
      // Spieltag 2
      [2, 'TSG Hoffenheim', 'Bayern München', null, null, '2025-01-18T15:30:00.000Z', 0],
      [2, 'SC Freiburg', 'Borussia Dortmund', null, null, '2025-01-18T18:30:00.000Z', 0],
      [2, 'VfB Stuttgart', 'RB Leipzig', null, null, '2025-01-19T15:30:00.000Z', 0],
      [2, 'Eintracht Frankfurt', 'Bayer Leverkusen', null, null, '2025-01-19T18:30:00.000Z', 0],
      [2, 'VfL Wolfsburg', 'Mainz 05', null, null, '2025-01-20T20:30:00.000Z', 0],
      // Spieltag 3
      [3, 'Bayern München', 'Mainz 05', null, null, '2025-01-25T15:30:00.000Z', 0],
      [3, 'Borussia Dortmund', 'Bayer Leverkusen', null, null, '2025-01-25T18:30:00.000Z', 0],
      [3, 'RB Leipzig', 'TSG Hoffenheim', null, null, '2025-01-26T15:30:00.000Z', 0],
      [3, 'Union Berlin', 'SC Freiburg', null, null, '2025-01-26T18:30:00.000Z', 0],
      [3, 'FC Augsburg', 'VfB Stuttgart', null, null, '2025-01-27T19:30:00.000Z', 0],
      // Spieltag 4
      [4, 'VfL Wolfsburg', 'Bayern München', null, null, '2025-02-01T15:30:00.000Z', 0],
      [4, 'Bayer Leverkusen', 'RB Leipzig', null, null, '2025-02-01T18:30:00.000Z', 0],
      [4, 'SC Freiburg', 'Borussia Dortmund', null, null, '2025-02-02T15:30:00.000Z', 0],
      [4, 'Mainz 05', 'Union Berlin', null, null, '2025-02-02T18:30:00.000Z', 0],
      [4, 'VfB Stuttgart', 'Eintracht Frankfurt', null, null, '2025-02-03T19:30:00.000Z', 0],
      // Spieltag 5
      [5, 'Bayern München', 'TSG Hoffenheim', null, null, '2025-02-08T15:30:00.000Z', 0],
      [5, 'Borussia Dortmund', 'FC Augsburg', null, null, '2025-02-08T18:30:00.000Z', 0],
      [5, 'RB Leipzig', 'VfB Stuttgart', null, null, '2025-02-09T15:30:00.000Z', 0],
      [5, 'Eintracht Frankfurt', 'VfL Wolfsburg', null, null, '2025-02-09T18:30:00.000Z', 0],
      [5, '1. FC Köln', 'Bayer Leverkusen', null, null, '2025-02-10T20:30:00.000Z', 0],
      // Spieltag 6
      [6, 'SC Freiburg', 'Bayern München', null, null, '2025-02-15T15:30:00.000Z', 0],
      [6, 'VfL Wolfsburg', 'RB Leipzig', null, null, '2025-02-15T18:30:00.000Z', 0],
      [6, 'Union Berlin', 'Borussia Dortmund', null, null, '2025-02-16T15:30:00.000Z', 0],
      [6, 'Mainz 05', 'Bayer Leverkusen', null, null, '2025-02-16T18:30:00.000Z', 0],
      [6, 'VfB Stuttgart', 'TSG Hoffenheim', null, null, '2025-02-17T19:30:00.000Z', 0],
      // Spieltag 7
      [7, 'Bayern München', 'Borussia Dortmund', 1, 2, '2025-02-22T18:30:00.000Z', 1],
      [7, 'RB Leipzig', 'Bayer Leverkusen', null, null, '2025-02-23T15:30:00.000Z', 0],
      [7, 'Bayer Leverkusen', 'VfL Wolfsburg', null, null, '2025-02-23T18:30:00.000Z', 0],
      [7, 'Eintracht Frankfurt', 'SC Freiburg', null, null, '2025-02-24T19:30:00.000Z', 0],
      [7, 'FC Augsburg', 'Union Berlin', null, null, '2025-02-25T19:30:00.000Z', 0],
      // Spieltag 8
      [8, 'Borussia Dortmund', 'VfB Stuttgart', null, null, '2025-03-01T15:30:00.000Z', 0],
      [8, 'TSG Hoffenheim', 'RB Leipzig', null, null, '2025-03-01T18:30:00.000Z', 0],
      [8, 'VfL Wolfsburg', 'SC Freiburg', null, null, '2025-03-02T15:30:00.000Z', 0],
      [8, 'Union Berlin', 'Eintracht Frankfurt', null, null, '2025-03-02T18:30:00.000Z', 0],
      [8, 'Mainz 05', 'Bayern München', null, null, '2025-03-03T20:30:00.000Z', 0],
      // Spieltag 9
      [9, 'Bayern München', 'FC Augsburg', null, null, '2025-03-08T15:30:00.000Z', 0],
      [9, 'RB Leipzig', 'Borussia Dortmund', null, null, '2025-03-08T18:30:00.000Z', 0],
      [9, 'Bayer Leverkusen', 'TSG Hoffenheim', null, null, '2025-03-09T15:30:00.000Z', 0],
      [9, 'SC Freiburg', 'VfL Wolfsburg', null, null, '2025-03-09T18:30:00.000Z', 0],
      [9, 'VfB Stuttgart', 'Mainz 05', null, null, '2025-03-10T19:30:00.000Z', 0],
      // Spieltag 10
      [10, 'Eintracht Frankfurt', 'Bayer Leverkusen', null, null, '2025-03-15T15:30:00.000Z', 0],
      [10, 'Union Berlin', 'Bayern München', null, null, '2025-03-15T18:30:00.000Z', 0],
      [10, 'TSG Hoffenheim', 'VfB Stuttgart', null, null, '2025-03-16T15:30:00.000Z', 0],
      [10, 'FC Augsburg', 'RB Leipzig', null, null, '2025-03-16T18:30:00.000Z', 0],
      [10, '1. FC Köln', 'Borussia Dortmund', null, null, '2025-03-17T19:30:00.000Z', 0],
      // Spieltag 11
      [11, 'Borussia Dortmund', 'Mainz 05', null, null, '2025-03-22T15:30:00.000Z', 0],
      [11, 'VfL Wolfsburg', 'Union Berlin', null, null, '2025-03-22T18:30:00.000Z', 0],
      [11, 'Bayern München', 'SC Freiburg', null, null, '2025-03-23T15:30:00.000Z', 0],
      [11, 'RB Leipzig', 'Eintracht Frankfurt', null, null, '2025-03-23T18:30:00.000Z', 0],
      [11, 'VfB Stuttgart', 'Bayer Leverkusen', null, null, '2025-03-24T19:30:00.000Z', 0],
      // Spieltag 12
      [12, 'Bayer Leverkusen', 'FC Augsburg', null, null, '2025-03-29T15:30:00.000Z', 0],
      [12, 'TSG Hoffenheim', 'Borussia Dortmund', null, null, '2025-03-29T18:30:00.000Z', 0],
      [12, 'SC Freiburg', 'RB Leipzig', null, null, '2025-03-30T15:30:00.000Z', 0],
      [12, 'Mainz 05', 'VfL Wolfsburg', null, null, '2025-03-30T18:30:00.000Z', 0],
      [12, 'Eintracht Frankfurt', 'Bayern München', null, null, '2025-03-31T20:30:00.000Z', 0],
      // Spieltag 13
      [13, 'Bayern München', 'VfB Stuttgart', null, null, '2025-04-05T15:30:00.000Z', 0],
      [13, 'RB Leipzig', 'Union Berlin', null, null, '2025-04-05T18:30:00.000Z', 0],
      [13, 'Borussia Dortmund', 'SC Freiburg', null, null, '2025-04-06T15:30:00.000Z', 0],
      [13, 'VfL Wolfsburg', 'Bayer Leverkusen', null, null, '2025-04-06T18:30:00.000Z', 0],
      [13, 'FC Augsburg', 'TSG Hoffenheim', null, null, '2025-04-07T19:30:00.000Z', 0],
      // Spieltag 14
      [14, 'Union Berlin', 'VfB Stuttgart', null, null, '2025-04-12T15:30:00.000Z', 0],
      [14, 'Eintracht Frankfurt', 'Mainz 05', null, null, '2025-04-12T18:30:00.000Z', 0],
      [14, 'SC Freiburg', 'Bayer Leverkusen', null, null, '2025-04-13T15:30:00.000Z', 0],
      [14, 'TSG Hoffenheim', 'VfL Wolfsburg', null, null, '2025-04-13T18:30:00.000Z', 0],
      [14, 'Bayern München', 'RB Leipzig', null, null, '2025-04-14T20:30:00.000Z', 0],
      // Spieltag 15
      [15, 'Borussia Dortmund', 'Eintracht Frankfurt', null, null, '2025-04-19T15:30:00.000Z', 0],
      [15, 'RB Leipzig', 'FC Augsburg', null, null, '2025-04-19T18:30:00.000Z', 0],
      [15, 'VfB Stuttgart', 'Bayern München', null, null, '2025-04-20T15:30:00.000Z', 0],
      [15, 'Bayer Leverkusen', 'Union Berlin', null, null, '2025-04-20T18:30:00.000Z', 0],
      [15, 'VfL Wolfsburg', 'SC Freiburg', null, null, '2025-04-21T19:30:00.000Z', 0],
      // Spieltag 16
      [16, 'Bayern München', 'TSG Hoffenheim', null, null, '2025-04-26T15:30:00.000Z', 0],
      [16, 'SC Freiburg', 'Borussia Dortmund', null, null, '2025-04-26T18:30:00.000Z', 0],
      [16, 'Mainz 05', 'RB Leipzig', null, null, '2025-04-27T15:30:00.000Z', 0],
      [16, 'Union Berlin', 'Bayer Leverkusen', null, null, '2025-04-27T18:30:00.000Z', 0],
      [16, 'Eintracht Frankfurt', 'VfL Wolfsburg', null, null, '2025-04-28T19:30:00.000Z', 0],
      // Spieltag 17
      [17, 'Borussia Dortmund', 'VfL Wolfsburg', null, null, '2025-05-03T15:30:00.000Z', 0],
      [17, 'RB Leipzig', 'Bayern München', null, null, '2025-05-03T18:30:00.000Z', 0],
      [17, 'TSG Hoffenheim', 'Bayer Leverkusen', null, null, '2025-05-04T15:30:00.000Z', 0],
      [17, 'VfB Stuttgart', 'SC Freiburg', null, null, '2025-05-04T18:30:00.000Z', 0],
      [17, 'FC Augsburg', 'Union Berlin', null, null, '2025-05-05T19:30:00.000Z', 0],
      // Spieltag 18
      [18, 'Bayern München', 'Eintracht Frankfurt', null, null, '2025-05-10T15:30:00.000Z', 0],
      [18, 'Bayer Leverkusen', 'Borussia Dortmund', null, null, '2025-05-10T18:30:00.000Z', 0],
      [18, 'VfL Wolfsburg', 'RB Leipzig', null, null, '2025-05-11T15:30:00.000Z', 0],
      [18, 'SC Freiburg', 'TSG Hoffenheim', null, null, '2025-05-11T18:30:00.000Z', 0],
      [18, 'Union Berlin', 'Mainz 05', null, null, '2025-05-12T20:30:00.000Z', 0],
      // Spieltag 19
      [19, 'Borussia Dortmund', 'Bayern München', null, null, '2025-05-17T15:30:00.000Z', 0],
      [19, 'RB Leipzig', 'VfB Stuttgart', null, null, '2025-05-17T18:30:00.000Z', 0],
      [19, 'Mainz 05', 'Bayer Leverkusen', null, null, '2025-05-18T15:30:00.000Z', 0],
      [19, 'Eintracht Frankfurt', 'FC Augsburg', null, null, '2025-05-18T18:30:00.000Z', 0],
      [19, 'TSG Hoffenheim', 'Union Berlin', null, null, '2025-05-19T19:30:00.000Z', 0],
      // Spieltag 20
      [20, 'Bayern München', 'VfL Wolfsburg', null, null, '2025-05-24T15:30:00.000Z', 0],
      [20, 'SC Freiburg', 'RB Leipzig', null, null, '2025-05-24T18:30:00.000Z', 0],
      [20, 'VfB Stuttgart', 'Borussia Dortmund', null, null, '2025-05-25T15:30:00.000Z', 0],
      [20, 'Union Berlin', 'Bayer Leverkusen', null, null, '2025-05-25T18:30:00.000Z', 0],
      [20, 'FC Augsburg', 'TSG Hoffenheim', null, null, '2025-05-26T19:30:00.000Z', 0],
      // Spieltag 21
      [21, 'Bayer Leverkusen', 'Bayern München', null, null, '2025-05-31T15:30:00.000Z', 0],
      [21, 'RB Leipzig', 'Eintracht Frankfurt', null, null, '2025-05-31T18:30:00.000Z', 0],
      [21, 'Borussia Dortmund', 'Union Berlin', null, null, '2025-06-01T15:30:00.000Z', 0],
      [21, 'TSG Hoffenheim', 'VfL Wolfsburg', null, null, '2025-06-01T18:30:00.000Z', 0],
      [21, 'SC Freiburg', 'Mainz 05', null, null, '2025-06-02T19:30:00.000Z', 0],
      // Spieltag 22
      [22, 'Bayern München', 'Borussia Dortmund', null, null, '2025-06-07T15:30:00.000Z', 0],
      [22, 'VfL Wolfsburg', 'Bayer Leverkusen', null, null, '2025-06-07T18:30:00.000Z', 0],
      [22, 'VfB Stuttgart', 'RB Leipzig', null, null, '2025-06-08T15:30:00.000Z', 0],
      [22, 'Union Berlin', 'SC Freiburg', null, null, '2025-06-08T18:30:00.000Z', 0],
      [22, 'Eintracht Frankfurt', 'TSG Hoffenheim', null, null, '2025-06-09T19:30:00.000Z', 0],
    ];

    for (const [md, home, away, hs, aw, date, finished] of demoMatches) {
      await dbRun(
        'INSERT INTO matches (matchday, home_team, away_team, home_score, away_score, match_date, is_finished) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [md, home, away, hs, aw, date, finished]
      );
    }
    console.log('Demo-Spiele (Spieltag 1–22) eingefügt.');
  }
}

function calculatePoints(tipHome, tipAway, resultHome, resultAway) {
  const tipTendenz = Math.sign(tipHome - tipAway);   // -1, 0, 1
  const resultTendenz = Math.sign(resultHome - resultAway);

  if (tipHome === resultHome && tipAway === resultAway) {
    return 3; 
  }
  if (tipTendenz === resultTendenz) {
    return 1; 
  }
  return 0; 
}


app.get('/api/matchdays', async (req, res) => {
  try {
    const rows = await dbAll(
      'SELECT DISTINCT matchday FROM matches ORDER BY matchday ASC'
    );
    res.json(rows.map(r => r.matchday));
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Fehler beim Laden der Spieltage' });
  }
});

app.get('/api/matches', async (req, res) => {
  try {
    const matchday = req.query.matchday;
    let sql = 'SELECT id, home_team, away_team, home_score, away_score, match_date, is_finished, matchday FROM matches';
    const params = [];
    if (matchday != null) {
      sql += ' WHERE matchday = ?';
      params.push(parseInt(matchday, 10));
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

app.post('/api/tips', async (req, res) => {
  const { match_id, tip_home, tip_away } = req.body;

  if (match_id == null || tip_home == null || tip_away == null) {
    return res.status(400).json({
      error: 'match_id, tip_home und tip_away sind erforderlich',
    });
  }

  const user_id = 1; 

  try {
    const match = await dbGet('SELECT id, is_finished FROM matches WHERE id = ?', [match_id]);
    if (!match) {
      return res.status(404).json({ error: 'Spiel nicht gefunden' });
    }
    if (match.is_finished === 1) {
      return res.status(400).json({ error: 'Spiel bereits beendet, Tipp kann nicht mehr geändert werden' });
    }

    const existing = await dbGet(
      'SELECT id FROM tips WHERE match_id = ? AND user_id = ?',
      [match_id, user_id]
    );

    if (existing) {
      await dbRun(
        'UPDATE tips SET tip_home = ?, tip_away = ? WHERE match_id = ? AND user_id = ?',
        [tip_home, tip_away, match_id, user_id]
      );
      res.json({
        message: 'Tipp aktualisiert',
        match_id,
        tip_home,
        tip_away,
      });
    } else {
      const result = await dbRun(
        'INSERT INTO tips (match_id, user_id, tip_home, tip_away) VALUES (?, ?, ?, ?)',
        [match_id, user_id, tip_home, tip_away]
      );
      res.status(201).json({
        message: 'Tipp gespeichert',
        id: result.id,
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

app.get('/api/user/1/tips', async (req, res) => {
  try {
    const tips = await dbAll(
      `SELECT 
        t.id, t.match_id, t.user_id, t.tip_home, t.tip_away, t.points_earned,
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
    const row = await dbGet(
      'SELECT COALESCE(SUM(points_earned), 0) as total FROM tips WHERE user_id = 1'
    );
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

  if (matchId == null || isNaN(matchId)) {
    return res.status(400).json({ error: 'Ungültige Match-ID' });
  }
  if (isNaN(home_score) || isNaN(away_score)) {
    return res.status(400).json({
      error: 'home_score und away_score müssen als Zahlen übergeben werden',
    });
  }

  try {
    const match = await dbGet('SELECT id FROM matches WHERE id = ?', [matchId]);
    if (!match) {
      return res.status(404).json({ error: 'Spiel nicht gefunden' });
    }

    await dbRun(
      'UPDATE matches SET home_score = ?, away_score = ?, is_finished = 1 WHERE id = ?',
      [home_score, away_score, matchId]
    );

    const tips = await dbAll(
      'SELECT id, tip_home, tip_away FROM tips WHERE match_id = ?',
      [matchId]
    );

    for (const tip of tips) {
      const points = calculatePoints(tip.tip_home, tip.tip_away, home_score, away_score);
      await dbRun('UPDATE tips SET points_earned = ? WHERE id = ?', [points, tip.id]);
    }

    res.json({
      message: 'Ergebnis gespeichert und Punkte aktualisiert',
      match_id: matchId,
      home_score,
      away_score,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Fehler beim Speichern des Ergebnisses' });
  }
});

async function start() {
  await initDatabase();

  app.listen(PORT, () => {
    console.log(`Tippspiel Backend läuft auf http://localhost:${PORT}`);
    console.log('API Endpunkte:');
    console.log('  GET  /api/matches         - Alle Spiele');
    console.log('  POST /api/tips            - Tipp abgeben (body: match_id, tip_home, tip_away)');
    console.log('  GET  /api/user/1/tips     - Tipps des Users mit Match-Infos');
    console.log('  GET  /api/user/1/points   - Gesamtpunktzahl');
    console.log('  PUT  /api/admin/match/:id - Ergebnis setzen (body: home_score, away_score)');
  });
}

start().catch((err) => {
  console.error('Startfehler:', err);
  process.exit(1);
});
