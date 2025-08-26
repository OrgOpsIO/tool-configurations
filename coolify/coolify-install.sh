#!/bin/bash

# ---------------------------------------------
# Coolify Docker-Compose Installation
# ---------------------------------------------

# Farben für die Ausgabe
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Aktuelles Verzeichnis des Skripts
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Zielverzeichnis im Home-Verzeichnis
TARGET_DIR=~/coolify-compose

echo -e "${GREEN}Coolify Installation mit Docker Compose wird gestartet...${NC}"
echo -e "${YELLOW}HINWEIS: Diese Installation nutzt NPM als Proxy, nicht Coolify's eingebauten Traefik!${NC}"

# Prüfen ob das Proxy-Netzwerk existiert
if ! docker network inspect proxy_network &>/dev/null; then
    echo -e "${RED}Das Proxy-Netzwerk existiert nicht. Stellen Sie sicher, dass Nginx Proxy Manager installiert ist.${NC}"
    echo -e "${YELLOW}Führen Sie zuerst './install.sh npm' aus oder installieren Sie den Proxy manuell.${NC}"
    exit 1
fi

# Docker-Version prüfen
DOCKER_VERSION=$(docker version --format '{{.Server.Version}}' | cut -d. -f1)
if [ "$DOCKER_VERSION" -lt 20 ]; then
    echo -e "${RED}Docker Version 20+ wird benötigt. Aktuelle Version: $(docker version --format '{{.Server.Version}}')${NC}"
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

# Config Generator kopieren
if [ ! -f "generate-config.sh" ]; then
    echo -e "${YELLOW}Kopiere generate-config.sh nach $TARGET_DIR${NC}"
    cp "$SCRIPT_DIR/generate-config.sh" .
    chmod +x generate-config.sh
fi

# NPM Helper Script kopieren
if [ ! -f "add-app-to-npm.sh" ]; then
    echo -e "${YELLOW}Kopiere add-app-to-npm.sh nach $TARGET_DIR${NC}"
    cp "$SCRIPT_DIR/add-app-to-npm.sh" .
    chmod +x add-app-to-npm.sh
fi

# Überprüfen, ob die .env existiert, sonst example.env kopieren
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}Kopiere example.env nach $TARGET_DIR/.env${NC}"
    cp "$SCRIPT_DIR/.env" ./.env

    # Konfiguration generieren
    echo -e "${YELLOW}Generiere Coolify Konfiguration...${NC}"
    ./generate-config.sh
fi

# Verzeichnisse erstellen, falls sie nicht existieren
echo -e "${YELLOW}Erstelle benötigte Verzeichnisse in $TARGET_DIR${NC}"
mkdir -p data/coolify
mkdir -p backups
mkdir -p ssh
mkdir -p redis/data

# SSH Keys generieren falls nicht vorhanden
if [ ! -f ssh/id_rsa ]; then
    echo -e "${YELLOW}Generiere SSH Keys für Coolify...${NC}"
    ssh-keygen -t rsa -b 4096 -f ssh/id_rsa -N "" -q
fi

# Berechtigungen setzen
echo -e "${YELLOW}Setze korrekte Berechtigungen...${NC}"
chmod 700 ssh
chmod 600 ssh/id_rsa 2>/dev/null
chmod 644 ssh/id_rsa.pub 2>/dev/null

# Docker Compose starten
echo -e "${YELLOW}Starte Coolify mit Docker Compose in $TARGET_DIR...${NC}"
docker compose up -d

# Warte auf den Start
echo -e "${YELLOW}Warte auf Coolify Start...${NC}"
sleep 15

# Erfolgsmeldung
echo -e "${GREEN}Coolify-Installation abgeschlossen!${NC}"
if [ -f ".env" ]; then
    # Laden der Umgebungsvariablen aus .env für die Ausgabe
    source .env
    echo -e "${GREEN}Ihre Coolify-Instanz läuft jetzt.${NC}"
    echo -e "${YELLOW}Wichtig: Konfigurieren Sie einen Proxy Host in Nginx Proxy Manager:${NC}"
    echo -e "${YELLOW}1. Öffnen Sie http://$(hostname -I | awk '{print $1}'):81${NC}"
    echo -e "${YELLOW}2. Fügen Sie einen neuen Proxy Host hinzu:${NC}"
    echo -e "${YELLOW}   - Domain: ${SUBDOMAIN}.${DOMAIN_NAME}${NC}"
    echo -e "${YELLOW}   - Scheme: http${NC}"
    echo -e "${YELLOW}   - Forward Hostname/IP: coolify${NC}"
    echo -e "${YELLOW}   - Forward Port: 8000${NC}"
    echo -e "${YELLOW}   - WebSocket Support: Aktivieren${NC}"
    echo -e "${YELLOW}   - Block Common Exploits: Aktivieren${NC}"
    echo -e "${YELLOW}   - Aktivieren Sie SSL und wählen Sie Let's Encrypt${NC}"
    echo -e ""
    echo -e "${YELLOW}3. Stellen Sie sicher, dass ein DNS A-Record für ${SUBDOMAIN}.${DOMAIN_NAME} existiert${NC}"
    echo -e ""
    echo -e "${GREEN}Nach der Proxy-Konfiguration:${NC}"
    echo -e "URL: https://${SUBDOMAIN}.${DOMAIN_NAME}"
    echo -e ""
    echo -e "${RED}WICHTIG für deployed Apps:${NC}"
    echo -e "${YELLOW}Da Coolify kein eigenes Proxy-Management macht, müssen Sie:${NC}"
    echo -e "${YELLOW}1. Jede deployed App manuell in NPM hinzufügen${NC}"
    echo -e "${YELLOW}2. Nutzen Sie ./add-app-to-npm.sh für eine Anleitung${NC}"
    echo -e "${YELLOW}3. Apps nutzen das 'proxy_network' für Erreichbarkeit${NC}"
fi