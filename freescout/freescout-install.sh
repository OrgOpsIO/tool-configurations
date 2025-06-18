#!/bin/bash

# ---------------------------------------------
# FreeScout Docker-Compose Installation
# ---------------------------------------------

# Farben für die Ausgabe
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Aktuelles Verzeichnis des Skripts
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Zielverzeichnis im Home-Verzeichnis
TARGET_DIR=~/freescout-compose

echo -e "${GREEN}FreeScout Installation mit Docker Compose wird gestartet...${NC}"

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
mkdir -p data
mkdir -p logs
mkdir -p db
mkdir -p dbbackup

# Docker Compose starten
echo -e "${YELLOW}Starte FreeScout mit Docker Compose in $TARGET_DIR...${NC}"
docker compose up -d

# Erfolgsmeldung
echo -e "${GREEN}FreeScout-Installation abgeschlossen!${NC}"
if [ -f ".env" ]; then
    # Laden der Umgebungsvariablen aus .env für die Ausgabe
    source .env
    echo -e "${GREEN}Ihre FreeScout-Instanz wird in Kürze unter https://${SUBDOMAIN}.${DOMAIN_NAME} verfügbar sein.${NC}"
    echo -e "${YELLOW}Wichtig: Stellen Sie sicher, dass Sie einen DNS A-Record für ${SUBDOMAIN}.${DOMAIN_NAME} auf die IP-Adresse Ihres Servers eingerichtet haben.${NC}"
fi