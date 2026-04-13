#!/bin/bash

# ---------------------------------------------
# vLLM + Open WebUI Docker-Compose Installation
# CPU-Modus (kein GPU erforderlich)
# ---------------------------------------------

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
TARGET_DIR=~/vllm-compose

echo -e "${GREEN}vLLM + Open WebUI Installation wird gestartet...${NC}"

# Proxy-Netzwerk prüfen
if ! docker network inspect proxy_network &>/dev/null; then
    echo -e "${RED}Das Proxy-Netzwerk existiert nicht. Stellen Sie sicher, dass Nginx Proxy Manager installiert ist.${NC}"
    echo -e "${YELLOW}Führen Sie zuerst './install.sh npm' aus oder installieren Sie den Proxy manuell.${NC}"
    exit 1
fi

# Zielverzeichnis anlegen
if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${YELLOW}Erstelle Verzeichnis $TARGET_DIR${NC}"
    mkdir -p "$TARGET_DIR"
fi

cd "$TARGET_DIR" || exit 1

# docker-compose.yml kopieren
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${YELLOW}Kopiere docker-compose.yml nach $TARGET_DIR${NC}"
    cp "$SCRIPT_DIR/docker-compose.yml" .
else
    echo -e "${YELLOW}docker-compose.yml existiert bereits in $TARGET_DIR${NC}"
fi

# .env anlegen
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}Kopiere example.env nach $TARGET_DIR/.env${NC}"
    cp "$SCRIPT_DIR/example.env" ./.env

    # WEBUI_SECRET_KEY automatisch generieren
    if command -v openssl &>/dev/null; then
        SECRET=$(openssl rand -hex 32)
        sed -i "s/your-secret-key-here-generate-with-openssl/$SECRET/" ./.env
        echo -e "${GREEN}WEBUI_SECRET_KEY wurde automatisch generiert.${NC}"
    fi

    echo ""
    echo -e "${YELLOW}================================================${NC}"
    echo -e "${YELLOW}WICHTIG: Bitte passen Sie die .env Datei an!${NC}"
    echo -e "${YELLOW}================================================${NC}"
    echo -e "${YELLOW}Datei: $TARGET_DIR/.env${NC}"
    echo ""
    echo -e "${YELLOW}Erforderliche Anpassungen:${NC}"
    echo -e "  1. DOMAIN_NAME und SUBDOMAIN setzen"
    echo -e "  2. VLLM_MODEL wählen (Standard: Qwen/Qwen2.5-1.5B-Instruct)"
    echo -e "     Für gated Models (z.B. Llama): HF_TOKEN setzen"
    echo ""
    echo -e "${YELLOW}Nach der Anpassung:${NC}"
    echo -e "  cd $TARGET_DIR && docker compose up -d"
    echo ""
    echo -e "${YELLOW}Hinweis: Erster Start dauert länger – Modell wird von HuggingFace geladen.${NC}"
    echo -e "${YELLOW}================================================${NC}"
    exit 0
else
    echo -e "${YELLOW}.env Datei existiert bereits in $TARGET_DIR${NC}"
fi

# Stack starten
echo -e "${YELLOW}Starte vLLM + Open WebUI...${NC}"
docker compose up -d

echo -e "${GREEN}Installation abgeschlossen!${NC}"
echo ""
echo -e "${GREEN}Next Steps:${NC}"
echo ""
echo -e "${YELLOW}1. Proxy Host in Nginx Proxy Manager einrichten:${NC}"
echo -e "   - Domain: chat.IHRE_DOMAIN"
echo -e "   - Forward: openwebui:8080"
echo -e "   - WebSocket: aktiviert"
echo -e "   - SSL: Let's Encrypt"
echo ""
echo -e "${YELLOW}2. Erster Start – Modell wird heruntergeladen:${NC}"
echo -e "   docker compose logs -f vllm"
echo -e "   (Abwarten bis: 'Application startup complete')"
echo ""
echo -e "${YELLOW}3. Open WebUI öffnen und Admin-Account erstellen.${NC}"
echo ""
echo -e "${GREEN}─── RunPod GPU on-demand hinzufügen ───────────────────────${NC}"
echo -e "${YELLOW}Wenn Sie RunPod als GPU-Backend nutzen möchten:${NC}"
echo ""
echo -e "  a) RunPod Pod mit vLLM-Template starten (siehe vllm-runpod-setup.sh)"
echo -e "  b) RunPod-URL in Open WebUI eintragen:"
echo -e "     Admin Panel → Einstellungen → Verbindungen → OpenAI"
echo -e "     URL: https://<pod-id>-8000.proxy.runpod.net/v1"
echo -e "     API Key: (leer oder aus RunPod-Einstellungen)"
echo -e "  c) Modelle aus RunPod erscheinen automatisch im Modell-Selector"
echo -e "  d) Pod stoppen wenn nicht mehr benötigt → keine Kosten"
echo ""
echo -e "${YELLOW}Lokales CPU-Backend bleibt parallel verfügbar.${NC}"
echo -e "${GREEN}────────────────────────────────────────────────────────────${NC}"
