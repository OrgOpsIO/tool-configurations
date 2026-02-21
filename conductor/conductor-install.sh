#!/bin/bash

# ---------------------------------------------
# Conductor Docker-Compose Installation
# ---------------------------------------------

# Farben für die Ausgabe
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Aktuelles Verzeichnis des Skripts
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Zielverzeichnis im Home-Verzeichnis
TARGET_DIR=~/conductor-compose

echo -e "${GREEN}Conductor Installation mit Docker Compose wird gestartet...${NC}"

# Prüfen ob das Proxy-Netzwerk existiert
if ! docker network inspect proxy_network &>/dev/null; then
    echo -e "${RED}Das Proxy-Netzwerk existiert nicht. Stellen Sie sicher, dass Nginx Proxy Manager installiert ist.${NC}"
    echo -e "${YELLOW}Führen Sie zuerst './install.sh npm' aus oder installieren Sie den Proxy manuell.${NC}"
    exit 1
fi

# Prüfen ob der Conductor Quellcode vorhanden ist
CONDUCTOR_SRC="${SCRIPT_DIR}/../../../conductor"
if [ ! -f "${CONDUCTOR_SRC}/Dockerfile" ]; then
    echo -e "${RED}Conductor Quellcode nicht gefunden unter: ${CONDUCTOR_SRC}${NC}"
    echo -e "${YELLOW}Bitte stellen Sie sicher, dass das Conductor-Repository unter ~/repos/conductor/ liegt.${NC}"
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

    # Conductor Source Path setzen
    CONDUCTOR_ABS=$(cd "${CONDUCTOR_SRC}" && pwd)
    sed -i "s|CONDUCTOR_SOURCE_PATH=.*|CONDUCTOR_SOURCE_PATH=${CONDUCTOR_ABS}|" ./.env

    echo ""
    echo -e "${YELLOW}================================================${NC}"
    echo -e "${YELLOW}WICHTIG: Bitte passen Sie die .env Datei an!${NC}"
    echo -e "${YELLOW}================================================${NC}"
    echo -e "${YELLOW}Die Datei befindet sich in: $TARGET_DIR/.env${NC}"
    echo ""
    echo -e "${YELLOW}Erforderliche Anpassungen:${NC}"
    echo -e "  1. GITLAB_URL und GITLAB_TOKEN setzen"
    echo -e "  2. ANTHROPIC_API_KEY setzen (Claude API Key)"
    echo -e "  3. WEBHOOK_SECRET generieren:"
    echo -e "     openssl rand -hex 32"
    echo ""
    echo -e "${YELLOW}Nach der Anpassung führen Sie aus:${NC}"
    echo -e "  cd $TARGET_DIR && docker compose up -d --build"
    echo ""
    echo -e "${YELLOW}================================================${NC}"
    exit 0
else
    echo -e "${YELLOW}.env Datei existiert bereits in $TARGET_DIR${NC}"
fi

# Docker Compose starten (mit Build)
echo -e "${YELLOW}Starte Conductor mit Docker Compose in $TARGET_DIR...${NC}"
docker compose up -d --build

# Erfolgsmeldung
echo -e "${GREEN}Conductor Installation abgeschlossen!${NC}"
echo ""
echo -e "${GREEN}Next Steps:${NC}"
echo -e "${YELLOW}1. Richten Sie einen Proxy Host in Nginx Proxy Manager ein:${NC}"
echo -e "   - Domain: conductor.example.com (Ihre Domain)"
echo -e "   - Forward Hostname/IP: conductor (Container-Name)"
echo -e "   - Forward Port: 8080"
echo -e "   - SSL: Let's Encrypt Zertifikat"
echo ""
echo -e "${YELLOW}2. GitLab Webhook konfigurieren:${NC}"
echo -e "   - URL: https://conductor.example.com/webhook"
echo -e "   - Secret Token: (gleicher Wert wie WEBHOOK_SECRET in .env)"
echo -e "   - Trigger: Issues events, Comments, Merge request events"
echo ""
echo -e "${YELLOW}3. Pipeline-Konfiguration:${NC}"
echo -e "   - Erstellen Sie eine .conductor.yml im Root Ihres Projekts"
echo -e "   - Oder kopieren Sie conductor.yml nach $TARGET_DIR/"
echo ""
echo -e "${YELLOW}4. Testen:${NC}"
echo -e "   curl https://conductor.example.com/health"
echo ""
echo -e "${GREEN}Health-Check: curl http://localhost:8080/health${NC}"
