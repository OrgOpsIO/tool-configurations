#!/bin/bash

# ---------------------------------------------
# PostgreSQL Instanz Installation
# ---------------------------------------------

# Farben für die Ausgabe
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Aktuelles Verzeichnis des Skripts
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Basis-Verzeichnis für alle Instanzen
INSTANCES_DIR=~/postgres-instances

# Funktion zum Anzeigen der Hilfe
show_help() {
    echo -e "${GREEN}PostgreSQL Instanz Installation${NC}"
    echo -e "Verwendung: $0 <instance-name> [--public]"
    echo -e ""
    echo -e "Parameter:"
    echo -e "  <instance-name>  - Name der PostgreSQL-Instanz (z.B. kunde-a, dev-db)"
    echo -e "  --public         - Instanz von extern erreichbar machen (mit SSL)"
    echo -e ""
    echo -e "Beispiele:"
    echo -e "  $0 kunde-a              # Private Instanz (nur SSH-Tunnel)"
    echo -e "  $0 dev-db --public      # Öffentliche Instanz (mit SSL)"
}

# Parameter prüfen
if [ -z "$1" ] || [ "$1" == "help" ] || [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    show_help
    exit 0
fi

INSTANCE_NAME=$1
IS_PUBLIC=false

# Prüfen ob --public Flag gesetzt ist
if [ "$2" == "--public" ]; then
    IS_PUBLIC=true
    INSTANCE_TYPE="public"
    echo -e "${YELLOW}⚠️  Öffentliche Instanz wird erstellt (extern erreichbar mit SSL)${NC}"
else
    INSTANCE_TYPE="private"
    echo -e "${GREEN}🔒 Private Instanz wird erstellt (nur SSH-Tunnel)${NC}"
fi

# Instanz-Namen validieren (nur Buchstaben, Zahlen, Bindestriche und Unterstriche)
if ! [[ "$INSTANCE_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo -e "${RED}Fehler: Instanz-Name darf nur Buchstaben, Zahlen, Bindestriche und Unterstriche enthalten.${NC}"
    exit 1
fi

# Instanz-Verzeichnis
INSTANCE_DIR="$INSTANCES_DIR/$INSTANCE_NAME"

# Prüfen ob Instanz bereits existiert
if [ -d "$INSTANCE_DIR" ]; then
    echo -e "${RED}Fehler: Instanz '$INSTANCE_NAME' existiert bereits in $INSTANCE_DIR${NC}"
    echo -e "${YELLOW}Verwenden Sie einen anderen Namen oder löschen Sie die bestehende Instanz.${NC}"
    exit 1
fi

echo -e "${GREEN}PostgreSQL Instanz '$INSTANCE_NAME' wird erstellt...${NC}"

# Funktion zum Finden eines freien Ports
find_free_port() {
    local start_port=$1
    local port=$start_port
    
    while true; do
        # Prüfen ob Port in Verwendung ist
        if ! netstat -tuln 2>/dev/null | grep -q ":$port " && \
           ! lsof -i :$port 2>/dev/null | grep -q "LISTEN" && \
           ! grep -r "POSTGRES_PORT=$port" "$INSTANCES_DIR" 2>/dev/null; then
            echo $port
            return
        fi
        port=$((port + 1))
    done
}

# Port ermitteln
if [ "$IS_PUBLIC" == true ]; then
    # Öffentliche Instanzen starten bei Port 6433
    POSTGRES_PORT=$(find_free_port 6433)
else
    # Private Instanzen starten bei Port 5433
    POSTGRES_PORT=$(find_free_port 5433)
fi

echo -e "${BLUE}📍 Port $POSTGRES_PORT wird verwendet${NC}"

# Instanz-Verzeichnisstruktur erstellen
echo -e "${YELLOW}Erstelle Verzeichnisstruktur...${NC}"
mkdir -p "$INSTANCE_DIR"/{config,init,backups}

# Passwörter generieren
echo -e "${YELLOW}Generiere sichere Passwörter...${NC}"
ADMIN_PASSWORD=$(bash "$SCRIPT_DIR/scripts/generate-password.sh" 32)
APP_PASSWORD=$(bash "$SCRIPT_DIR/scripts/generate-password.sh" 32)

# Datenbank- und User-Namen aus Instanz-Namen ableiten
DB_NAME="${INSTANCE_NAME//-/_}_db"
APP_USER="${INSTANCE_NAME//-/_}_app"

# .env Datei erstellen
echo -e "${YELLOW}Erstelle .env Datei...${NC}"
cat > "$INSTANCE_DIR/.env" << EOF
# PostgreSQL Instanz-Konfiguration
INSTANCE_NAME=${INSTANCE_NAME}
INSTANCE_TYPE=${INSTANCE_TYPE}

# PostgreSQL Admin-Zugangsdaten
POSTGRES_ADMIN_PASSWORD=${ADMIN_PASSWORD}

# PostgreSQL Datenbank
POSTGRES_DB=${DB_NAME}

# PostgreSQL Application User
POSTGRES_APP_USER=${APP_USER}
POSTGRES_APP_PASSWORD=${APP_PASSWORD}

# Port-Konfiguration
POSTGRES_PORT=${POSTGRES_PORT}

# Zeitzone
TIMEZONE=Europe/Berlin

# Erstellungsdatum
CREATED_AT=$(date +%Y-%m-%d)
EOF

# Docker Compose Datei kopieren
echo -e "${YELLOW}Kopiere Docker Compose Konfiguration...${NC}"
if [ "$IS_PUBLIC" == true ]; then
    cp "$SCRIPT_DIR/templates/docker-compose-public.yml" "$INSTANCE_DIR/docker-compose.yml"
else
    cp "$SCRIPT_DIR/templates/docker-compose-private.yml" "$INSTANCE_DIR/docker-compose.yml"
fi

# Init-Script für Application User erstellen
echo -e "${YELLOW}Erstelle Initialisierungs-Script...${NC}"
cat > "$INSTANCE_DIR/init/01-create-app-user.sh" << EOF
#!/bin/bash
set -e

echo "Creating application user and database..."

# Application User erstellen
psql -v ON_ERROR_STOP=1 --username "\$POSTGRES_USER" --dbname "\$POSTGRES_DB" <<-EOSQL
    -- Application User erstellen
    CREATE USER ${APP_USER} WITH PASSWORD '${APP_PASSWORD}';
    
    -- Berechtigungen gewähren
    GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${APP_USER};
    
    -- Schema Berechtigungen (PostgreSQL 15+)
    \c ${DB_NAME}
    GRANT ALL ON SCHEMA public TO ${APP_USER};
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${APP_USER};
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ${APP_USER};
    
    -- Standard-Berechtigungen für zukünftige Objekte
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ${APP_USER};
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO ${APP_USER};
    
    -- Nützliche Extensions aktivieren
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    CREATE EXTENSION IF NOT EXISTS "pgcrypto";
    CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
EOSQL

echo "Application user and database setup completed!"
EOF

chmod +x "$INSTANCE_DIR/init/01-create-app-user.sh"

# SSL-Zertifikate für öffentliche Instanzen generieren
if [ "$IS_PUBLIC" == true ]; then
    echo -e "${YELLOW}Generiere SSL-Zertifikate für sichere Verbindungen...${NC}"
    
    # Self-signed Zertifikat erstellen (für Produktion sollte ein echtes Zertifikat verwendet werden)
    openssl req -new -x509 -days 365 -nodes -text \
        -out "$INSTANCE_DIR/config/server.crt" \
        -keyout "$INSTANCE_DIR/config/server.key" \
        -subj "/CN=postgres-$INSTANCE_NAME" \
        2>/dev/null
    
    # Berechtigungen setzen
    chmod 600 "$INSTANCE_DIR/config/server.key"
    chmod 644 "$INSTANCE_DIR/config/server.crt"
    
    echo -e "${GREEN}✓ SSL-Zertifikate erstellt${NC}"
fi

# README mit Verbindungsinformationen erstellen
echo -e "${YELLOW}Erstelle README mit Verbindungsinformationen...${NC}"
cat > "$INSTANCE_DIR/README.txt" << EOF
PostgreSQL Instanz: ${INSTANCE_NAME}
=====================================

Typ: ${INSTANCE_TYPE}
Erstellt: $(date +"%Y-%m-%d %H:%M:%S")
Port: ${POSTGRES_PORT}
PostgreSQL Version: 18

ZUGANGSDATEN
============

Admin User:
  Username: postgres
  Password: ${ADMIN_PASSWORD}
  Database: ${DB_NAME}

Application User:
  Username: ${APP_USER}
  Password: ${APP_PASSWORD}
  Database: ${DB_NAME}

EOF

if [ "$IS_PUBLIC" == true ]; then
    cat >> "$INSTANCE_DIR/README.txt" << EOF
VERBINDUNG (Öffentlich)
=======================

Verbindung mit SSL:
  psql "postgresql://${APP_USER}:${APP_PASSWORD}@your-server-ip:${POSTGRES_PORT}/${DB_NAME}?sslmode=require"

Oder mit separaten Parametern:
  psql -h your-server-ip -p ${POSTGRES_PORT} -U ${APP_USER} -d ${DB_NAME}

⚠️  WICHTIG:
  - SSL ist ERZWUNGEN für externe Verbindungen
  - Standardmäßig sind alle IPs erlaubt (mit SSL)
  - Für erhöhte Sicherheit: IP-Whitelist in config/pg_hba.conf konfigurieren
  - Self-signed Zertifikat ist für Produktion NICHT empfohlen!

FIREWALL
========
Stellen Sie sicher, dass Port ${POSTGRES_PORT} in der Firewall geöffnet ist:
  sudo ufw allow ${POSTGRES_PORT}/tcp

EOF
else
    cat >> "$INSTANCE_DIR/README.txt" << EOF
VERBINDUNG (Privat - nur SSH-Tunnel)
=====================================

1. SSH-Tunnel aufbauen:
   ssh -L ${POSTGRES_PORT}:localhost:${POSTGRES_PORT} user@your-server

2. In einem neuen Terminal lokal verbinden:
   psql -h localhost -p ${POSTGRES_PORT} -U ${APP_USER} -d ${DB_NAME}

Oder mit Connection String:
   postgresql://${APP_USER}:${APP_PASSWORD}@localhost:${POSTGRES_PORT}/${DB_NAME}

EOF
fi

cat >> "$INSTANCE_DIR/README.txt" << EOF
VERWALTUNG
==========

Instanz starten:
  cd $INSTANCE_DIR && docker compose up -d

Instanz stoppen:
  cd $INSTANCE_DIR && docker compose stop

Instanz neustarten:
  cd $INSTANCE_DIR && docker compose restart

Logs anzeigen:
  cd $INSTANCE_DIR && docker compose logs -f

Backup erstellen:
  docker exec ${INSTANCE_NAME}_postgres pg_dump -U postgres ${DB_NAME} > backup.sql

Backup wiederherstellen:
  docker exec -i ${INSTANCE_NAME}_postgres psql -U postgres ${DB_NAME} < backup.sql

VERZEICHNISSTRUKTUR
===================

$INSTANCE_DIR/
├── .env                    # Umgebungsvariablen und Passwörter
├── docker-compose.yml      # Docker Compose Konfiguration
├── README.txt             # Diese Datei
├── config/                # SSL-Zertifikate (nur für public)
│   ├── server.crt
│   └── server.key
├── init/                  # Initialisierungs-Scripts
│   └── 01-create-app-user.sh
└── backups/               # Backup-Verzeichnis

Hinweis: PostgreSQL Daten werden in einem Docker Named Volume gespeichert.
PostgreSQL-Parameter sind direkt im docker-compose.yml konfiguriert.

MANAGEMENT SCRIPT
=================

Verwenden Sie das Management-Script für einfache Verwaltung:
  ~/postgres-instances/manage.sh list
  ~/postgres-instances/manage.sh info ${INSTANCE_NAME}
  ~/postgres-instances/manage.sh start ${INSTANCE_NAME}
  ~/postgres-instances/manage.sh stop ${INSTANCE_NAME}
  ~/postgres-instances/manage.sh backup ${INSTANCE_NAME}

EOF

# Management-Script ins Instanzen-Verzeichnis kopieren (beim ersten Mal)
if [ ! -f "$INSTANCES_DIR/manage.sh" ]; then
    echo -e "${YELLOW}Kopiere Management-Script nach $INSTANCES_DIR...${NC}"
    cp "$SCRIPT_DIR/postgres-manage.sh" "$INSTANCES_DIR/manage.sh"
    chmod +x "$INSTANCES_DIR/manage.sh"
fi

# Docker Compose starten
echo -e "${YELLOW}Starte PostgreSQL Instanz mit Docker Compose...${NC}"
cd "$INSTANCE_DIR"
docker compose up -d

# Warten bis Container healthy ist
echo -e "${YELLOW}Warte auf PostgreSQL...${NC}"
sleep 5

# Erfolgsausgabe
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ PostgreSQL Instanz '${INSTANCE_NAME}' erfolgreich erstellt!  ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📊 Instanz-Details:${NC}"
echo -e "   Name:     ${INSTANCE_NAME}"
if [ "$IS_PUBLIC" == true ]; then
    echo -e "   Typ:      ${YELLOW}Öffentlich (extern erreichbar mit SSL)${NC}"
else
    echo -e "   Typ:      ${GREEN}Privat (nur SSH-Tunnel)${NC}"
fi
echo -e "   Port:     ${POSTGRES_PORT}"
echo -e "   Version:  PostgreSQL 18"
echo ""
echo -e "${BLUE}🔐 Zugangsdaten:${NC}"
echo -e "   Admin User:     postgres"
echo -e "   Admin Password: ${ADMIN_PASSWORD}"
echo -e "   App User:       ${APP_USER}"
echo -e "   App Password:   ${APP_PASSWORD}"
echo -e "   Database:       ${DB_NAME}"
echo ""

if [ "$IS_PUBLIC" == true ]; then
    echo -e "${BLUE}🔌 Verbindung:${NC}"
    echo -e "   ${YELLOW}psql -h \$(hostname -I | awk '{print \$1}') -p ${POSTGRES_PORT} -U ${APP_USER} -d ${DB_NAME}${NC}"
    echo ""
    echo -e "${RED}⚠️  WICHTIG - Firewall:${NC}"
    echo -e "   ${YELLOW}sudo ufw allow ${POSTGRES_PORT}/tcp${NC}"
    echo ""
    echo -e "${RED}⚠️  SICHERHEITSHINWEIS:${NC}"
    echo -e "   - SSL ist aktiviert und erzwungen"
    echo -e "   - Self-signed Zertifikat (für Produktion echtes Zertifikat empfohlen)"
    echo -e "   - Alle IPs sind erlaubt (konfigurierbar in config/pg_hba.conf)"
else
    echo -e "${BLUE}🔌 Verbindung via SSH-Tunnel:${NC}"
    echo -e "   1. ${YELLOW}ssh -L ${POSTGRES_PORT}:localhost:${POSTGRES_PORT} user@your-server${NC}"
    echo -e "   2. ${YELLOW}psql -h localhost -p ${POSTGRES_PORT} -U ${APP_USER} -d ${DB_NAME}${NC}"
fi

echo ""
echo -e "${BLUE}📁 Verzeichnis:${NC} ${INSTANCE_DIR}"
echo -e "${BLUE}📄 Details:${NC} ${INSTANCE_DIR}/README.txt"
echo ""
echo -e "${GREEN}Verwenden Sie das Management-Script für weitere Operationen:${NC}"
echo -e "  ${YELLOW}~/postgres-instances/manage.sh list${NC}"
echo -e "  ${YELLOW}~/postgres-instances/manage.sh info ${INSTANCE_NAME}${NC}"
echo ""
