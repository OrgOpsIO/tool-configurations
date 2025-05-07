#!/bin/bash

# ---------------------------------------------
# n8n Docker-Compose Installation mit PostgreSQL
# ---------------------------------------------

# Farben für die Ausgabe
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Aktuelles Verzeichnis des Skripts
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Zielverzeichnis im Home-Verzeichnis
TARGET_DIR=~/n8n-compose

echo -e "${GREEN}n8n Installation mit Docker Compose und PostgreSQL wird gestartet...${NC}"

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

# local-files Verzeichnis erstellen, falls es nicht existiert
if [ ! -d "local-files" ]; then
    echo -e "${YELLOW}Erstelle local-files Verzeichnis in $TARGET_DIR${NC}"
    mkdir -p local-files
fi

# PostgreSQL Verzeichnisstrukturen erstellen und Datei kopieren
if [ ! -d "postgresql/docker-entrypoint-initdb.d" ]; then
    echo -e "${YELLOW}Erstelle PostgreSQL Initialisierungsverzeichnis in $TARGET_DIR${NC}"
    mkdir -p postgresql/docker-entrypoint-initdb.d

    # Initialisierungsskript kopieren
    cp "$SCRIPT_DIR/postgresql/docker-entrypoint-initdb.d/init-non-root-user.sh" postgresql/docker-entrypoint-initdb.d/

    # Berechtigungen für das PostgreSQL-Skript setzen
    echo -e "${YELLOW}Setze Berechtigungen für PostgreSQL Initialisierungsskript...${NC}"
    chmod +x postgresql/docker-entrypoint-initdb.d/init-non-root-user.sh
else
    echo -e "${YELLOW}PostgreSQL Verzeichnisstruktur existiert bereits in $TARGET_DIR${NC}"
fi

# Docker Compose starten
echo -e "${YELLOW}Starte n8n mit PostgreSQL und Docker Compose in $TARGET_DIR...${NC}"
docker compose up -d

# Erfolgsmeldung
echo -e "${GREEN}n8n-Installation mit PostgreSQL abgeschlossen!${NC}"
if [ -f ".env" ]; then
    # Laden der Umgebungsvariablen aus .env für die Ausgabe
    source .env
    echo -e "${GREEN}Ihre n8n-Instanz wird in Kürze unter https://${SUBDOMAIN}.${DOMAIN_NAME} verfügbar sein.${NC}"
    echo -e "${YELLOW}Wichtig: Stellen Sie sicher, dass Sie einen DNS A-Record für ${SUBDOMAIN}.${DOMAIN_NAME} auf die IP-Adresse Ihres Servers eingerichtet haben.${NC}"
fi