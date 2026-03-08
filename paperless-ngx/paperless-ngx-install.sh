#!/bin/bash

# ---------------------------------------------
# Paperless-ngx Docker-Compose Installation
# ---------------------------------------------

# Farben für die Ausgabe
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Aktuelles Verzeichnis des Skripts
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Zielverzeichnis im Home-Verzeichnis
TARGET_DIR=~/paperless-ngx-compose

echo -e "${GREEN}Paperless-ngx Installation mit Docker Compose wird gestartet...${NC}"

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

# Überprüfen, ob die .env existiert, sonst example.env kopieren und Secrets generieren
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}Kopiere example.env nach $TARGET_DIR/.env${NC}"
    cp "$SCRIPT_DIR/example.env" ./.env

    # Sichere Secrets automatisch generieren
    echo -e "${YELLOW}Generiere sichere Secrets...${NC}"
    SECRET_KEY=$(openssl rand -base64 45 | tr -d '\n')
    sed -i "s|^PAPERLESS_SECRET_KEY=.*|PAPERLESS_SECRET_KEY=$SECRET_KEY|" .env

    DB_PASS=$(openssl rand -hex 32)
    sed -i "s|^PAPERLESS_DB_PASSWORD=.*|PAPERLESS_DB_PASSWORD=$DB_PASS|" .env

    ADMIN_PASS=$(openssl rand -base64 16 | tr -d '\n/+=')
    sed -i "s|^PAPERLESS_ADMIN_PASSWORD=.*|PAPERLESS_ADMIN_PASSWORD=$ADMIN_PASS|" .env

    echo -e "${GREEN}Secrets wurden automatisch generiert.${NC}"
    echo -e "${YELLOW}Bitte passen Sie DOMAIN_NAME und SUBDOMAIN in $TARGET_DIR/.env an Ihre Bedürfnisse an.${NC}"
fi

# Verzeichnisse erstellen, falls sie nicht existieren
echo -e "${YELLOW}Erstelle benötigte Verzeichnisse in $TARGET_DIR${NC}"
mkdir -p export
mkdir -p consume

# Docker Compose starten
echo -e "${YELLOW}Starte Paperless-ngx mit Docker Compose in $TARGET_DIR...${NC}"
docker compose up -d

# Erfolgsmeldung
echo -e "${GREEN}Paperless-ngx Installation abgeschlossen!${NC}"
if [ -f ".env" ]; then
    source .env
    echo -e "${GREEN}Ihre Paperless-ngx Instanz läuft jetzt.${NC}"
    echo -e "${YELLOW}Wichtig: Konfigurieren Sie einen Proxy Host in Nginx Proxy Manager:${NC}"
    echo -e "${YELLOW}1. Öffnen Sie http://$(hostname -I | awk '{print $1}'):81${NC}"
    echo -e "${YELLOW}2. Fügen Sie einen neuen Proxy Host hinzu:${NC}"
    echo -e "${YELLOW}   - Domain: ${SUBDOMAIN}.${DOMAIN_NAME}${NC}"
    echo -e "${YELLOW}   - Scheme: http${NC}"
    echo -e "${YELLOW}   - Forward Hostname/IP: paperless${NC}"
    echo -e "${YELLOW}   - Forward Port: 8000${NC}"
    echo -e "${YELLOW}   - Aktivieren Sie SSL und wählen Sie Let's Encrypt${NC}"
    echo -e "${YELLOW}3. Stellen Sie sicher, dass ein DNS A-Record für ${SUBDOMAIN}.${DOMAIN_NAME} existiert${NC}"
    echo -e "${YELLOW}4. Besuchen Sie https://${SUBDOMAIN}.${DOMAIN_NAME} und loggen Sie sich ein${NC}"
fi
