#!/bin/bash

# ---------------------------------------------
# Twenty CRM Docker-Compose Installation
# ---------------------------------------------

# Farben für die Ausgabe
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Aktuelles Verzeichnis des Skripts
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Zielverzeichnis im Home-Verzeichnis
TARGET_DIR=~/twenty-compose

echo -e "${GREEN}Twenty CRM Installation mit Docker Compose wird gestartet...${NC}"

# Prüfen ob das Proxy-Netzwerk existiert
if ! docker network inspect proxy_network &>/dev/null; then
    echo -e "${RED}Das Proxy-Netzwerk existiert nicht. Stellen Sie sicher, dass Nginx Proxy Manager installiert ist.${NC}"
    echo -e "${YELLOW}Führen Sie zuerst './install.sh npm' aus oder installieren Sie den Proxy manuell.${NC}"
    exit 1
fi

# Überprüfen, ob das Zielverzeichnis existiert, sonst erstellen
if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${YELLOW}Erstelle Verzeichnis $TARGET_DIR${NC}"
    mkdir -p "$TARGET_DIR"
fi

# Ins Zielverzeichnis wechseln
cd "$TARGET_DIR" || exit 1

# Überprüfen, ob die docker-compose.yml existiert, sonst kopieren
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${YELLOW}Kopiere docker-compose.yml nach $TARGET_DIR${NC}"
    cp "$SCRIPT_DIR/docker-compose.yml" .
else
    echo -e "${YELLOW}docker-compose.yml existiert bereits in $TARGET_DIR${NC}"
fi

# Überprüfen, ob die .env existiert, sonst example.env kopieren
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}Kopiere example.env nach $TARGET_DIR/.env${NC}"
    cp "$SCRIPT_DIR/example.env" ./.env

    # Generiere sicheres APP_SECRET
    echo -e "${YELLOW}Generiere sicheres APP_SECRET...${NC}"
    APP_SECRET=$(openssl rand -base64 32 | tr -d '\n')
    sed -i "s|^APP_SECRET=.*|APP_SECRET=$APP_SECRET|" .env

    # Generiere sicheres DB Passwort (nur alphanumerische Zeichen für URL-Kompatibilität)
    echo -e "${YELLOW}Generiere sicheres PostgreSQL Passwort...${NC}"
    DB_PASS=$(openssl rand -hex 32)
    sed -i "s|^PG_DATABASE_PASSWORD=.*|PG_DATABASE_PASSWORD=$DB_PASS|" .env

    echo -e "${YELLOW}Bitte passen Sie die .env Datei in $TARGET_DIR an Ihre Bedürfnisse an.${NC}"
else
    echo -e "${YELLOW}.env existiert bereits in $TARGET_DIR${NC}"
fi

# Docker Compose starten
echo -e "${YELLOW}Starte Twenty CRM mit Docker Compose in $TARGET_DIR...${NC}"
docker compose up -d

# Warte auf den Start
echo -e "${YELLOW}Warte auf Twenty CRM Start (Datenbank-Migration läuft)...${NC}"
sleep 20

# Health Check
if curl -s --fail http://localhost:3000/healthz >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Twenty CRM läuft erfolgreich!${NC}"
else
    echo -e "${YELLOW}⚠️  Twenty CRM startet noch... Prüfe in 30 Sekunden erneut.${NC}"
fi

# Erfolgsmeldung
echo -e "${GREEN}Twenty CRM Installation abgeschlossen!${NC}"
if [ -f ".env" ]; then
    # Laden der Umgebungsvariablen aus .env für die Ausgabe
    source .env
    echo -e "${GREEN}Ihre Twenty CRM Instanz läuft jetzt.${NC}"
    echo -e "${YELLOW}Wichtig: Konfigurieren Sie einen Proxy Host in Nginx Proxy Manager:${NC}"
    echo -e "${YELLOW}1. Öffnen Sie http://$(hostname -I | awk '{print $1}'):81${NC}"
    echo -e "${YELLOW}2. Fügen Sie einen neuen Proxy Host hinzu:${NC}"
    echo -e "${YELLOW}   - Domain: ${SUBDOMAIN}.${DOMAIN_NAME}${NC}"
    echo -e "${YELLOW}   - Scheme: http${NC}"
    echo -e "${YELLOW}   - Forward Hostname/IP: server${NC}"
    echo -e "${YELLOW}   - Forward Port: 3000${NC}"
    echo -e "${YELLOW}   - Block Common Exploits: Aktivieren${NC}"
    echo -e "${YELLOW}   - Aktivieren Sie SSL und wählen Sie Let's Encrypt${NC}"
    echo -e ""
    echo -e "${YELLOW}   Erweiterte Nginx-Konfiguration (Custom Nginx Configuration):${NC}"
    echo -e "${YELLOW}   client_max_body_size 100M;${NC}"
    echo -e "${YELLOW}   proxy_read_timeout 86400s;${NC}"
    echo -e ""
    echo -e "${YELLOW}3. Stellen Sie sicher, dass ein DNS A-Record für ${SUBDOMAIN}.${DOMAIN_NAME} existiert${NC}"
    echo -e ""
    echo -e "${GREEN}Nach der Proxy-Konfiguration:${NC}"
    echo -e "URL: https://${SUBDOMAIN}.${DOMAIN_NAME}"
    echo -e ""
    echo -e "${YELLOW}Der erste erstellte Account wird automatisch Administrator!${NC}"
    echo -e ""
    echo -e "${GREEN}Nützliche URLs:${NC}"
    echo -e "Health Check: https://${SUBDOMAIN}.${DOMAIN_NAME}/healthz"
    echo -e ""
    echo -e "${YELLOW}Hinweis:${NC}"
    echo -e "- Twenty CRM benötigt mindestens 2GB RAM"
    echo -e "- Der erste Login kann einige Sekunden dauern"
    echo -e "- Logs anzeigen: cd $TARGET_DIR && docker compose logs -f"
fi
