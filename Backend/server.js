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
      is_finished INTEGER DEFAULT 0
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
      ['FC Bayern München', 'Borussia Dortmund', '2025-03-08T15:30:00.000Z'],
      ['RB Leipzig', 'Bayer 04 Leverkusen', '2025-03-09T15:30:00.000Z'],
      ['VfB Stuttgart', 'Eintracht Frankfurt', '2025-03-09T17:30:00.000Z'],
      ['Borussia Mönchengladbach', 'VfL Wolfsburg', '2025-03-10T18:30:00.000Z'],
      ['Union Berlin', 'SC Freiburg', '2025-03-11T18:30:00.000Z'],
    ];

    for (const [home, away, date] of demoMatches) {
      await dbRun(
        'INSERT INTO matches (home_team, away_team, match_date) VALUES (?, ?, ?)',
        [home, away, date]
      );
    }
    console.log('5 Demo-Spiele (Bundesliga) eingefügt.');
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


app.get('/api/matches', async (req, res) => {
  try {
    const matches = await dbAll(
      'SELECT id, home_team, away_team, home_score, away_score, match_date, is_finished FROM matches ORDER BY match_date ASC'
    );
    res.json(matches);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Fehler beim Laden der Spiele' });
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
