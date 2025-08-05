#!/bin/bash

# ---------------------------------------------
# TileDesk Docker-Compose Installation
# ---------------------------------------------

# Farben für die Ausgabe
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Aktuelles Verzeichnis des Skripts
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Zielverzeichnis im Home-Verzeichnis
TARGET_DIR=~/tiledesk-compose

echo -e "${GREEN}TileDesk Installation mit Docker Compose wird gestartet...${NC}"

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

# Token-Generator kopieren
if [ ! -f "generate-tokens.sh" ]; then
    echo -e "${YELLOW}Kopiere generate-tokens.sh nach $TARGET_DIR${NC}"
    cp "$SCRIPT_DIR/generate-tokens.sh" .
    chmod +x generate-tokens.sh
fi

# Überprüfen, ob die .env existiert, sonst example.env kopieren
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}Kopiere example.env nach $TARGET_DIR/.env${NC}"
    cp "$SCRIPT_DIR/.env" ./.env

    # Tokens generieren
    echo -e "${YELLOW}Generiere JWT Tokens...${NC}"
    ./generate-tokens.sh

    echo -e "${YELLOW}Bitte passen Sie die .env Datei in $TARGET_DIR an Ihre Bedürfnisse an.${NC}"
    echo -e "${RED}WICHTIG: Ändern Sie die Standard-Passwörter!${NC}"
fi

# Verzeichnisse erstellen, falls sie nicht existieren
echo -e "${YELLOW}Erstelle benötigte Verzeichnisse in $TARGET_DIR${NC}"
mkdir -p mongodb/data
mkdir -p redis/data
mkdir -p rabbitmq/data
mkdir -p uploads

# Docker Compose starten
echo -e "${YELLOW}Starte TileDesk mit Docker Compose in $TARGET_DIR...${NC}"
docker compose up -d

# Erfolgsmeldung
echo -e "${GREEN}TileDesk-Installation abgeschlossen!${NC}"
if [ -f ".env" ]; then
    # Laden der Umgebungsvariablen aus .env für die Ausgabe
    source .env
    echo -e "${GREEN}Ihre TileDesk-Instanz läuft jetzt.${NC}"
    echo -e ""
    echo -e "${YELLOW}=== NPM Proxy Host Konfiguration ===${NC}"
    echo -e "${YELLOW}Erstellen Sie folgende Proxy Hosts in Nginx Proxy Manager:${NC}"
    echo -e ""
    echo -e "${YELLOW}1. API Server:${NC}"
    echo -e "   - Domain: ${SUBDOMAIN}.${DOMAIN_NAME}"
    echo -e "   - Location: /api"
    echo -e "   - Forward Hostname/IP: tiledesk-server"
    echo -e "   - Forward Port: 3000"
    echo -e ""
    echo -e "${YELLOW}2. Dashboard:${NC}"
    echo -e "   - Domain: ${SUBDOMAIN}.${DOMAIN_NAME}"
    echo -e "   - Location: /dashboard"
    echo -e "   - Forward Hostname/IP: tiledesk-dashboard"
    echo -e "   - Forward Port: 80"
    echo -e ""
    echo -e "${YELLOW}3. WebSocket:${NC}"
    echo -e "   - Domain: ${SUBDOMAIN}.${DOMAIN_NAME}"
    echo -e "   - Location: /ws"
    echo -e "   - Forward Hostname/IP: tiledesk-server"
    echo -e "   - Forward Port: 3000"
    echo -e "   - WebSocket Support: ${RED}AKTIVIEREN${NC}"
    echo -e ""
    echo -e "${YELLOW}4. Chat API:${NC}"
    echo -e "   - Domain: ${SUBDOMAIN}.${DOMAIN_NAME}"
    echo -e "   - Location: /chatapi"
    echo -e "   - Forward Hostname/IP: tiledesk-chat21httpserver"
    echo -e "   - Forward Port: 8004"
    echo -e ""
    echo -e "${YELLOW}5. MQTT WebSocket:${NC}"
    echo -e "   - Domain: ${SUBDOMAIN}.${DOMAIN_NAME}"
    echo -e "   - Location: /mqws"
    echo -e "   - Forward Hostname/IP: tiledesk-rabbitmq"
    echo -e "   - Forward Port: 15675"
    echo -e "   - WebSocket Support: ${RED}AKTIVIEREN${NC}"
    echo -e ""
    echo -e "${YELLOW}6. Widget:${NC}"
    echo -e "   - Domain: ${SUBDOMAIN}.${DOMAIN_NAME}"
    echo -e "   - Location: /widget"
    echo -e "   - Forward Hostname/IP: tiledesk-webwidget"
    echo -e "   - Forward Port: 80"
    echo -e ""
    echo -e "${YELLOW}7. CDS (Design Studio):${NC}"
    echo -e "   - Domain: ${SUBDOMAIN}.${DOMAIN_NAME}"
    echo -e "   - Location: /cds"
    echo -e "   - Forward Hostname/IP: tiledesk-cds"
    echo -e "   - Forward Port: 80"
    echo -e ""
    echo -e "${YELLOW}8. Ionic Chat:${NC}"
    echo -e "   - Domain: ${SUBDOMAIN}.${DOMAIN_NAME}"
    echo -e "   - Location: /chat"
    echo -e "   - Forward Hostname/IP: tiledesk-ionic"
    echo -e "   - Forward Port: 80"
    echo -e ""
    echo -e "${YELLOW}9. Root Redirect (optional):${NC}"
    echo -e "   - Domain: ${SUBDOMAIN}.${DOMAIN_NAME}"
    echo -e "   - Location: /"
    echo -e "   - Custom Configuration:"
    echo -e "     return 301 /dashboard/;"
    echo -e ""
    echo -e "${YELLOW}=== Zugangsdaten ===${NC}"
    echo -e "URL: https://${SUBDOMAIN}.${DOMAIN_NAME}/dashboard"
    echo -e "Admin E-Mail: admin@tiledesk.com"
    echo -e "Admin Passwort: superadmin"
    echo -e ""
    echo -e "${RED}WICHTIG: Ändern Sie das Admin-Passwort nach dem ersten Login!${NC}"
fi
