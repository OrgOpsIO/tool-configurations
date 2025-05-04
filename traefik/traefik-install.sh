#!/bin/bash

# ---------------------------------------------
# Traefik Docker-Compose Installation
# ---------------------------------------------

# Farben für die Ausgabe
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Aktuelles Verzeichnis des Skripts
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Zielverzeichnis im Home-Verzeichnis
TARGET_DIR=~/traefik-compose

echo -e "${GREEN}Traefik Installation mit Docker Compose wird gestartet...${NC}"

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
    echo -e "${YELLOW}Bitte passen Sie die .env Datei in $TARGET_DIR an Ihre Bedürfnisse an.${NC}"
fi

# Erstellen des externen Netzwerks, falls es nicht existiert
echo -e "${YELLOW}Erstelle externes Docker-Netzwerk für Traefik...${NC}"
docker network create traefik_network 2>/dev/null || true

# Docker Compose starten
echo -e "${YELLOW}Starte Traefik mit Docker Compose in $TARGET_DIR...${NC}"
docker compose up -d

echo -e "${GREEN}Traefik-Installation abgeschlossen!${NC}"
echo -e "${YELLOW}Traefik ist nun bereit, Anfragen entgegenzunehmen und auf registrierte Dienste weiterzuleiten.${NC}"
echo -e "${YELLOW}Stellen Sie sicher, dass die Ports 80 und 443 in Ihrer Firewall geöffnet sind.${NC}"