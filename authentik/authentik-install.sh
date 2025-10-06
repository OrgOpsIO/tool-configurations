#!/bin/bash

# ---------------------------------------------
# Authentik Docker-Compose Installation
# ---------------------------------------------

# Farben für die Ausgabe
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Aktuelles Verzeichnis des Skripts
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Zielverzeichnis im Home-Verzeichnis
TARGET_DIR=~/authentik-compose

echo -e "${GREEN}Authentik Installation mit Docker Compose wird gestartet...${NC}"

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
    
    # generate-secrets.sh kopieren
    if [ -f "$SCRIPT_DIR/generate-secrets.sh" ]; then
        cp "$SCRIPT_DIR/generate-secrets.sh" ./generate-secrets.sh
        chmod +x ./generate-secrets.sh
        
        echo -e "${GREEN}Generiere sichere Secrets...${NC}"
        ./generate-secrets.sh
    fi
    
    echo ""
    echo -e "${YELLOW}================================================${NC}"
    echo -e "${YELLOW}WICHTIG: Bitte passen Sie die .env Datei an!${NC}"
    echo -e "${YELLOW}================================================${NC}"
    echo -e "${YELLOW}Die Datei befindet sich in: $TARGET_DIR/.env${NC}"
    echo ""
    echo -e "${YELLOW}Erforderliche Anpassungen:${NC}"
    echo -e "  1. SMTP Konfiguration:"
    echo -e "     - AUTHENTIK_EMAIL__HOST (z.B. smtp.gmail.com)"
    echo -e "     - AUTHENTIK_EMAIL__PORT (z.B. 587 für TLS)"
    echo -e "     - AUTHENTIK_EMAIL__USERNAME (z.B. authentik@orgops.io)"
    echo -e "     - AUTHENTIK_EMAIL__PASSWORD (Ihr SMTP Passwort)"
    echo -e "     - AUTHENTIK_EMAIL__FROM (z.B. authentik@orgops.io)"
    echo ""
    echo -e "${YELLOW}Nach der Anpassung führen Sie aus:${NC}"
    echo -e "  cd $TARGET_DIR && docker compose up -d"
    echo ""
    echo -e "${YELLOW}================================================${NC}"
    exit 0
else
    echo -e "${YELLOW}.env Datei existiert bereits in $TARGET_DIR${NC}"
fi

# Docker Compose starten
echo -e "${YELLOW}Starte Authentik mit Docker Compose in $TARGET_DIR...${NC}"
docker compose up -d

# Erfolgsmeldung
echo -e "${GREEN}Authentik-Installation abgeschlossen!${NC}"
echo ""
echo -e "${GREEN}Next Steps:${NC}"
echo -e "${YELLOW}1. Richten Sie einen Proxy Host in Nginx Proxy Manager ein:${NC}"
echo -e "   - Domain: auth.orgops.io (oder Ihre Domain)"
echo -e "   - Forward Hostname/IP: authentik_server (oder die IP Ihres Servers)"
echo -e "   - Forward Port: 9000"
echo -e "   - WebSocket Support: Aktiviert"
echo -e "   - SSL: Let's Encrypt Zertifikat"
echo ""
echo -e "${YELLOW}2. Öffnen Sie: https://auth.orgops.io/if/flow/initial-setup/${NC}"
echo -e "   - Erstellen Sie Ihren Admin-Account"
echo ""
echo -e "${YELLOW}3. Konfigurieren Sie Ihre Services in Authentik:${NC}"
echo -e "   - Applications → Neue Application erstellen"
echo -e "   - Providers → OAuth2, SAML oder LDAP Provider"
echo ""
echo -e "${GREEN}Dokumentation: https://docs.goauthentik.io${NC}"
