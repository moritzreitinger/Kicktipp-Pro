# Kicktipp Pro Backend

TypeScript Backend für die Kicktipp Pro Flutter App.

## Installation

```bash
npm install
```

## Development

```bash
npm run dev
```

Startet den Server mit automatischem Reload bei Dateienänderungen.

## Production

```bash
npm run build
npm start
```

## API Endpoints

### Spiele

- **GET** `/api/matchdays` - Alle Spieltage
- **GET** `/api/matches?matchday=1` - Spiele eines Spieltags (optional)

### Benutzer

- **GET** `/api/user/:id` - Benutzerinformationen

### Tipps

- **POST** `/api/tips` - Neuen Tipp abgeben
  - Body: `{ match_id: number, tip_home: number, tip_away: number }`
- **GET** `/api/user/1/tips` - Alle Tipps des Benutzers mit Match-Infos
- **GET** `/api/user/1/points` - Gesamtpunktzahl des Benutzers

### Admin

- **PUT** `/api/admin/match/:id` - Ergebnis eines Spiels setzen
  - Body: `{ home_score: number, away_score: number }`

## Struktur

Die Anwendung verwendet eine In-Memory Datenbank mit:
- **Database Klasse**: Verwaltet alle Daten (Spiele, Tipps)
- **Type Interfaces**: Streng typisierte Datenmodelle
- **Express Routes**: RESTful API Endpoints

Sample-Daten werden beim Start automatisch geladen (22 Bundesliga Spieltage).

## Port

Standard Port: `3000` (konfigurierbar über `PORT` Umgebungsvariable)
