#!/bin/bash

# ---------------------------------------------
# OpenClaw Docker-Compose Installation
# Personal AI Assistant Gateway
# ---------------------------------------------

# Farben fuer die Ausgabe
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Aktuelles Verzeichnis des Skripts
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Zielverzeichnis im Home-Verzeichnis
TARGET_DIR=~/openclaw-compose

echo -e "${GREEN}OpenClaw Installation mit Docker Compose wird gestartet...${NC}"

# Pruefen ob das Proxy-Netzwerk existiert
if ! docker network inspect proxy_network &>/dev/null; then
    echo -e "${RED}Das Proxy-Netzwerk existiert nicht. Stellen Sie sicher, dass Nginx Proxy Manager installiert ist.${NC}"
    echo -e "${YELLOW}Fuehren Sie zuerst './install.sh npm' aus oder installieren Sie den Proxy manuell.${NC}"
    exit 1
fi

# Ueberpruefen, ob das Zielverzeichnis existiert, sonst erstellen
if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${YELLOW}Erstelle Verzeichnis $TARGET_DIR${NC}"
    mkdir -p "$TARGET_DIR"
fi

# Ins Zielverzeichnis wechseln
cd "$TARGET_DIR" || exit 1

# Ueberpruefen, ob die docker-compose.yml existiert, sonst kopieren
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${YELLOW}Kopiere docker-compose.yml nach $TARGET_DIR${NC}"
    cp "$SCRIPT_DIR/docker-compose.yml" .
else
    echo -e "${YELLOW}docker-compose.yml existiert bereits in $TARGET_DIR${NC}"
fi

# Ueberpruefen, ob die .env existiert, sonst example.env kopieren und Token generieren
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}Kopiere example.env nach $TARGET_DIR/.env${NC}"
    cp "$SCRIPT_DIR/example.env" ./.env

    # Gateway Token generieren
    if command -v openssl &> /dev/null; then
        GENERATED_TOKEN=$(openssl rand -hex 32)
        sed -i.bak "s/^OPENCLAW_GATEWAY_TOKEN=$/OPENCLAW_GATEWAY_TOKEN=${GENERATED_TOKEN}/" .env
        rm -f .env.bak
        echo -e "${GREEN}Gateway Token wurde automatisch generiert.${NC}"
    else
        echo -e "${YELLOW}Bitte generieren Sie manuell einen Gateway Token und tragen Sie ihn in .env ein.${NC}"
    fi
fi

# Onboarding durchfuehren falls noch nicht geschehen
echo -e "${YELLOW}Starte Onboarding (API Key Konfiguration)...${NC}"
echo -e "${YELLOW}Waehlen Sie Ihren LLM Provider (Anthropic, OpenAI, etc.) und geben Sie den API Key ein.${NC}"
echo ""
docker compose --profile cli run --rm openclaw-cli onboard

# Docker Compose starten
echo -e "${YELLOW}Starte OpenClaw Gateway mit Docker Compose in $TARGET_DIR...${NC}"
docker compose up -d openclaw-gateway

# Erfolgsmeldung
echo -e "${GREEN}OpenClaw-Installation abgeschlossen!${NC}"
if [ -f ".env" ]; then
    source .env
    echo -e "${GREEN}Ihre OpenClaw-Instanz ist unter https://${SUBDOMAIN}.${DOMAIN_NAME} verfuegbar.${NC}"
    echo -e "${YELLOW}Lokaler Zugriff (Control UI): http://127.0.0.1:18789${NC}"
    echo -e "${YELLOW}Wichtig: Stellen Sie sicher, dass Sie einen DNS A-Record fuer ${SUBDOMAIN}.${DOMAIN_NAME} eingerichtet haben.${NC}"
    echo ""
    echo -e "${GREEN}Nuetzliche Befehle:${NC}"
    echo -e "${YELLOW}  Chat starten:     docker compose --profile cli run --rm openclaw-cli chat${NC}"
    echo -e "${YELLOW}  Erneut onboarden: docker compose --profile cli run --rm openclaw-cli onboard${NC}"
    echo -e "${YELLOW}  Dashboard:        http://127.0.0.1:18789${NC}"
fi
