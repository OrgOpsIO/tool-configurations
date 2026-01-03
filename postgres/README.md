# PostgreSQL Instanzen Management

Einfache und sichere Verwaltung mehrerer PostgreSQL-Instanzen mit Docker Compose.

## 🎯 Features

- **Zwei Betriebsmodi:**
  - 🔒 **Private Instanzen**: Nur über SSH-Tunnel erreichbar (Standard)
  - 🌐 **Öffentliche Instanzen**: Von extern mit SSL/TLS erreichbar

- **Sicherheit:**
  - Automatische, sichere Passwort-Generierung (32 Zeichen)
  - SSL/TLS Verschlüsselung für öffentliche Instanzen
  - Restriktive pg_hba.conf Konfiguration
  - Separate Admin- und Application-User
  - SCRAM-SHA-256 Authentifizierung

- **Performance:**
  - Optimiert für kleine Server (512MB-1GB RAM pro Instanz)
  - Ressourcen-Limits (0.5 CPU, max 1GB RAM)
  - Konfigurierbare PostgreSQL-Parameter

- **Management:**
  - Automatische Port-Zuweisung (keine Konflikte)
  - Einfaches Backup & Restore
  - Health Checks und Auto-Restart
  - Zentrales Management-Script

- **PostgreSQL 18** (neueste Version)

## 📦 Installation

### Voraussetzungen

- Docker & Docker Compose
- Bash Shell
- OpenSSL (für SSL-Zertifikate)

### Neue Instanz erstellen

```bash
# Private Instanz (nur SSH-Tunnel)
./install.sh postgres kunde-a

# Öffentliche Instanz (mit SSL)
./install.sh postgres dev-db --public

# Mehrere Instanzen
./install.sh postgres kunde-a
./install.sh postgres kunde-b
./install.sh postgres dev-db --public
./install.sh postgres test-db --public
```

## 🔧 Verwaltung

Nach der Installation steht ein zentrales Management-Script zur Verfügung:

```bash
~/postgres-instances/manage.sh <command> [instance-name]
```

### Verfügbare Befehle

```bash
# Alle Instanzen auflisten
~/postgres-instances/manage.sh list

# Details einer Instanz anzeigen (inkl. Passwörter)
~/postgres-instances/manage.sh info kunde-a

# Instanz starten/stoppen/neustarten
~/postgres-instances/manage.sh start kunde-a
~/postgres-instances/manage.sh stop kunde-a
~/postgres-instances/manage.sh restart kunde-a

# Status und Logs
~/postgres-instances/manage.sh status kunde-a
~/postgres-instances/manage.sh logs kunde-a

# Backup erstellen
~/postgres-instances/manage.sh backup kunde-a
~/postgres-instances/manage.sh backup kunde-a /pfad/zu/backup.sql

# Backup wiederherstellen
~/postgres-instances/manage.sh restore kunde-a /pfad/zu/backup.sql

# Instanz löschen (mit Bestätigung)
~/postgres-instances/manage.sh delete kunde-a
```

## 🔌 Verbindung

### Private Instanzen (SSH-Tunnel)

**Schritt 1:** SSH-Tunnel aufbauen
```bash
ssh -L 5433:localhost:5433 user@your-server
```

**Schritt 2:** Lokal verbinden
```bash
psql -h localhost -p 5433 -U kunde_a_app -d kunde_a_db
```

### Öffentliche Instanzen

```bash
psql -h your-server-ip -p 6433 -U dev_db_app -d dev_db_db
```

**Wichtig:** 
- SSL ist erzwungen
- Firewall-Port öffnen: `sudo ufw allow 6433/tcp`
- Self-signed Zertifikat (für Produktion echtes Zertifikat empfohlen)

## 📁 Verzeichnisstruktur

```
~/postgres-instances/
├── manage.sh                    # Management-Script (wird beim ersten Install kopiert)
├── kunde-a/                     # Private Instanz
│   ├── .env                     # Umgebungsvariablen & Passwörter
│   ├── docker-compose.yml       # Docker Compose Konfiguration
│   ├── README.txt              # Instanz-spezifische Infos
│   ├── data/                    # PostgreSQL Daten
│   ├── config/                  # Konfigurationsdateien
│   │   ├── postgresql.conf
│   │   └── pg_hba.conf
│   ├── init/                    # Initialisierungs-Scripts
│   │   └── 01-create-app-user.sh
│   └── backups/                 # Backup-Verzeichnis
├── dev-db/                      # Öffentliche Instanz
│   ├── .env
│   ├── docker-compose.yml
│   ├── README.txt
│   ├── data/
│   ├── config/
│   │   ├── postgresql.conf
│   │   ├── pg_hba.conf
│   │   ├── server.crt          # SSL-Zertifikat
│   │   └── server.key          # SSL-Key
│   ├── init/
│   └── backups/
└── ...
```

## 🔐 Sicherheit

### Private Instanzen

- Port nur auf `127.0.0.1` gebunden
- Keine externe Erreichbarkeit
- Zugriff nur über SSH-Tunnel
- pg_hba.conf erlaubt nur localhost

### Öffentliche Instanzen

- SSL/TLS erzwungen für alle externen Verbindungen
- SCRAM-SHA-256 Authentifizierung
- Alle nicht-SSL Verbindungen werden abgelehnt
- Self-signed Zertifikat (austauschbar)
- IP-Whitelist konfigurierbar in `config/pg_hba.conf`

### Best Practices

1. **Passwörter sichern**: Alle Zugangsdaten sind in der `.env` Datei
2. **Backups erstellen**: Regelmäßige Backups mit dem Management-Script
3. **SSL-Zertifikate**: Für Produktion echte Zertifikate verwenden
4. **Firewall**: Nur benötigte Ports öffnen
5. **IP-Whitelist**: In `config/pg_hba.conf` spezifische IPs eintragen

## 🛠 Erweiterte Konfiguration

### PostgreSQL-Parameter anpassen

Bearbeiten Sie `~/postgres-instances/<instance-name>/config/postgresql.conf`:

```bash
cd ~/postgres-instances/kunde-a
nano config/postgresql.conf
docker compose restart
```

### IP-Whitelist einrichten (öffentliche Instanzen)

Bearbeiten Sie `config/pg_hba.conf`:

```bash
# Nur spezifische IPs erlauben
hostssl all all 203.0.113.0/24 scram-sha-256
hostssl all all 198.51.100.50/32 scram-sha-256
```

### Echtes SSL-Zertifikat verwenden

Ersetzen Sie die Self-signed Zertifikate:

```bash
cd ~/postgres-instances/<instance-name>/config
# Ihre Zertifikate kopieren
cp /pfad/zu/ihrem/cert.crt server.crt
cp /pfad/zu/ihrem/key.key server.key
chmod 600 server.key
chmod 644 server.crt

# Container neustarten
cd ~/postgres-instances/<instance-name>
docker compose restart
```

### Ressourcen-Limits anpassen

Bearbeiten Sie `docker-compose.yml`:

```yaml
deploy:
  resources:
    limits:
      cpus: '1.0'      # Von 0.5 auf 1.0 erhöhen
      memory: 2G       # Von 1G auf 2G erhöhen
```

## 📊 Monitoring

### Container-Status

```bash
~/postgres-instances/manage.sh status kunde-a
```

### Ressourcen-Nutzung

```bash
~/postgres-instances/manage.sh info kunde-a
# Zeigt CPU und Memory Usage
```

### Logs

```bash
~/postgres-instances/manage.sh logs kunde-a
# Drücken Sie Ctrl+C zum Beenden
```

### PostgreSQL Logs

```bash
docker exec kunde_a_postgres tail -f /var/lib/postgresql/data/log/postgresql-*.log
```

## 💾 Backup & Restore

### Backup erstellen

```bash
# Automatischer Dateiname (Timestamp)
~/postgres-instances/manage.sh backup kunde-a

# Eigener Dateiname
~/postgres-instances/manage.sh backup kunde-a /pfad/zu/backup.sql
```

### Backup wiederherstellen

```bash
~/postgres-instances/manage.sh restore kunde-a /pfad/zu/backup.sql
# Bestätigung erforderlich
```

### Automatische Backups (Optional)

Cron-Job einrichten:

```bash
crontab -e

# Tägliches Backup um 2 Uhr nachts
0 2 * * * ~/postgres-instances/manage.sh backup kunde-a
```

## 🚀 Beispiel-Workflows

### Neue Kunden-Datenbank

```bash
# 1. Instanz erstellen (privat)
./install.sh postgres kunde-x

# 2. Zugangsdaten abrufen
~/postgres-instances/manage.sh info kunde-x

# 3. Zugangsdaten an Kunden weitergeben
```

### Entwicklungs-Datenbank

```bash
# 1. Öffentliche Instanz erstellen
./install.sh postgres dev-db --public

# 2. Firewall-Port öffnen
sudo ufw allow 6433/tcp

# 3. Von extern verbinden
psql -h server-ip -p 6433 -U dev_db_app -d dev_db_db
```

### Migration zu neuer Instanz

```bash
# 1. Backup der alten Instanz
~/postgres-instances/manage.sh backup alte-instanz

# 2. Neue Instanz erstellen
./install.sh postgres neue-instanz

# 3. Backup wiederherstellen
~/postgres-instances/manage.sh restore neue-instanz ~/postgres-instances/alte-instanz/backups/alte-instanz_20260103_120000.sql

# 4. Alte Instanz löschen (optional)
~/postgres-instances/manage.sh delete alte-instanz
```

## 🔧 Troubleshooting

### Container startet nicht

```bash
# Logs prüfen
~/postgres-instances/manage.sh logs kunde-a

# Status prüfen
docker ps -a | grep kunde_a

# Manuell starten
cd ~/postgres-instances/kunde-a
docker compose up
```

### Port bereits belegt

Das Script findet automatisch freie Ports. Bei manueller Änderung:

```bash
nano ~/postgres-instances/kunde-a/.env
# POSTGRES_PORT ändern
docker compose restart
```

### Verbindung schlägt fehl

**Private Instanz:**
- SSH-Tunnel aktiv? `ps aux | grep ssh`
- Richtiger Port? Siehe `.env` Datei
- Passwort korrekt? Siehe `README.txt` oder `manage.sh info`

**Öffentliche Instanz:**
- Firewall-Port offen? `sudo ufw status`
- SSL aktiviert im Client?
- Server-IP korrekt?

### Passwort vergessen

```bash
~/postgres-instances/manage.sh info kunde-a
# Zeigt alle Passwörter an
```

## 📝 Technische Details

- **PostgreSQL Version:** 18-alpine
- **Docker Base Image:** postgres:18-alpine
- **Standard-Ports:** 5433+ (privat), 6433+ (öffentlich)
- **Ressourcen:** 0.5 CPU, 512MB-1GB RAM pro Instanz
- **Authentifizierung:** SCRAM-SHA-256
- **Extensions:** uuid-ossp, pgcrypto, pg_stat_statements
- **Encoding:** UTF-8
- **Locale:** de_DE / en_US
- **Timezone:** Europe/Berlin

## 📄 Lizenz

Teil des OrgOps Tool-Configurations Projekts.

## 🤝 Support

Bei Problemen oder Fragen:
1. Logs prüfen: `~/postgres-instances/manage.sh logs <name>`
2. README.txt in der Instanz konsultieren
3. Management-Script nutzen: `~/postgres-instances/manage.sh help`
