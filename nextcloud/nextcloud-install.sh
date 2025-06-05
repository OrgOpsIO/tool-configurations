#!/bin/bash

# ---------------------------------------------
# Nextcloud Docker-Compose Installation
# ---------------------------------------------

# Farben für die Ausgabe
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Aktuelles Verzeichnis des Skripts
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Zielverzeichnis im Home-Verzeichnis
TARGET_DIR=~/nextcloud-compose

echo -e "${GREEN}Nextcloud Installation mit Docker Compose wird gestartet...${NC}"

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
    cp "$SCRIPT_DIR/.env" ./.env
    echo -e "${YELLOW}Bitte passen Sie die .env Datei in $TARGET_DIR an Ihre Bedürfnisse an.${NC}"
fi

# Verzeichnisse erstellen, falls sie nicht existieren
echo -e "${YELLOW}Erstelle benötigte Verzeichnisse in $TARGET_DIR${NC}"
mkdir -p mariadb/data
mkdir -p redis/data
mkdir -p nextcloud/html
mkdir -p nextcloud/data
mkdir -p nextcloud/config
mkdir -p nextcloud/apps
mkdir -p nextcloud/themes

# Berechtigungen setzen (wichtig für Nextcloud)
echo -e "${YELLOW}Setze korrekte Berechtigungen für Nextcloud-Verzeichnisse...${NC}"
# Nextcloud läuft als www-data (UID 33)
sudo chown -R 33:33 nextcloud/
chmod -R 755 nextcloud/

# Docker Compose starten
echo -e "${YELLOW}Starte Nextcloud mit Docker Compose in $TARGET_DIR...${NC}"
docker compose up -d

# Erfolgsmeldung
echo -e "${GREEN}Nextcloud-Installation abgeschlossen!${NC}"
if [ -f ".env" ]; then
    # Laden der Umgebungsvariablen aus .env für die Ausgabe
    source .env
    echo -e "${GREEN}Ihre Nextcloud-Instanz läuft jetzt.${NC}"
    echo -e "${YELLOW}Wichtig: Konfigurieren Sie einen Proxy Host in Nginx Proxy Manager:${NC}"
    echo -e "${YELLOW}1. Öffnen Sie http://$(hostname -I | awk '{print $1}'):81${NC}"
    echo -e "${YELLOW}2. Fügen Sie einen neuen Proxy Host hinzu:${NC}"
    echo -e "${YELLOW}   - Domain: ${SUBDOMAIN}.${DOMAIN_NAME}${NC}"
    echo -e "${YELLOW}   - Scheme: http${NC}"
    echo -e "${YELLOW}   - Forward Hostname/IP: nextcloud${NC}"
    echo -e "${YELLOW}   - Forward Port: 80${NC}"
    echo -e "${YELLOW}   - Aktivieren Sie SSL und wählen Sie Let's Encrypt${NC}"
    echo -e "${YELLOW}   - WICHTIG: Aktivieren Sie 'Block Common Exploits' und 'Websockets Support'${NC}"
    echo -e "${YELLOW}3. Stellen Sie sicher, dass ein DNS A-Record für ${SUBDOMAIN}.${DOMAIN_NAME} existiert${NC}"
    echo -e "${YELLOW}4. Nach der Proxy-Konfiguration: https://${SUBDOMAIN}.${DOMAIN_NAME} aufrufen${NC}"
    echo -e "${YELLOW}5. Erste Anmeldung mit Admin-Benutzer: ${NEXTCLOUD_ADMIN_USER}${NC}"
fi
