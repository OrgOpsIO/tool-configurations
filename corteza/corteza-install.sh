#!/bin/bash

# ---------------------------------------------
# Corteza CRM Docker-Compose Installation
# ---------------------------------------------

# Farben für die Ausgabe
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Aktuelles Verzeichnis des Skripts
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Zielverzeichnis im Home-Verzeichnis
TARGET_DIR=~/corteza-compose

echo -e "${GREEN}Corteza CRM Installation mit Docker Compose wird gestartet...${NC}"

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

# Überprüfen, ob die .env existiert, sonst .env kopieren
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}Kopiere example.env nach $TARGET_DIR/.env${NC}"
    cp "$SCRIPT_DIR/.env" ./.env

    # Generiere sicheres JWT Secret
    echo -e "${YELLOW}Generiere sicheres JWT Secret...${NC}"
    JWT_SECRET=$(openssl rand -base64 45 | tr -d '\n')
    sed -i "s|^AUTH_JWT_SECRET=.*|AUTH_JWT_SECRET=$JWT_SECRET|" .env

    # Generiere sicheres DB Passwort
    DB_PASS=$(openssl rand -base64 32 | tr -d '\n')
    sed -i "s|^DB_PASSWORD=.*|DB_PASSWORD=$DB_PASS|" .env

    echo -e "${YELLOW}Bitte passen Sie die .env Datei in $TARGET_DIR an Ihre Bedürfnisse an.${NC}"
fi

# Verzeichnisse erstellen, falls sie nicht existieren
echo -e "${YELLOW}Erstelle benötigte Verzeichnisse in $TARGET_DIR${NC}"
mkdir -p corteza/server
mkdir -p postgres/data

# Berechtigungen setzen
echo -e "${YELLOW}Setze korrekte Berechtigungen...${NC}"
# Corteza Server läuft als User 4242
sudo chown -R 4242:4242 corteza/server
chmod -R 755 corteza/server

# PostgreSQL läuft als User 1001 (postgres container default)
sudo chown -R 999:999 postgres/data
chmod -R 700 postgres/data

# Docker Compose starten
echo -e "${YELLOW}Starte Corteza CRM mit Docker Compose in $TARGET_DIR...${NC}"
docker compose up -d

# Warte auf den Start
echo -e "${YELLOW}Warte auf Corteza Start (Datenbank-Migration läuft)...${NC}"
sleep 20

# Health Check
if curl -s --fail http://localhost/healthcheck >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Corteza läuft erfolgreich!${NC}"
else
    echo -e "${YELLOW}⚠️  Corteza startet noch... Prüfe in 30 Sekunden erneut.${NC}"
fi

# Erfolgsmeldung
echo -e "${GREEN}Corteza CRM Installation abgeschlossen!${NC}"
if [ -f ".env" ]; then
    # Laden der Umgebungsvariablen aus .env für die Ausgabe
    source .env
    echo -e "${GREEN}Ihre Corteza CRM Instanz läuft jetzt.${NC}"
    echo -e "${YELLOW}Wichtig: Konfigurieren Sie einen Proxy Host in Nginx Proxy Manager:${NC}"
    echo -e "${YELLOW}1. Öffnen Sie http://$(hostname -I | awk '{print $1}'):81${NC}"
    echo -e "${YELLOW}2. Fügen Sie einen neuen Proxy Host hinzu:${NC}"
    echo -e "${YELLOW}   - Domain: ${SUBDOMAIN}.${DOMAIN_NAME}${NC}"
    echo -e "${YELLOW}   - Scheme: http${NC}"
    echo -e "${YELLOW}   - Forward Hostname/IP: corteza${NC}"
    echo -e "${YELLOW}   - Forward Port: 80${NC}"
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
    echo -e "API Docs: https://${SUBDOMAIN}.${DOMAIN_NAME}/api/docs/"
    echo -e "Version: https://${SUBDOMAIN}.${DOMAIN_NAME}/version"
    echo -e "Health: https://${SUBDOMAIN}.${DOMAIN_NAME}/healthcheck"
fi
