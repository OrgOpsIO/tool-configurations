#!/bin/bash

# ---------------------------------------------
# GitLab CE Docker-Compose Installation
# ---------------------------------------------

# Farben für die Ausgabe
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Aktuelles Verzeichnis des Skripts
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Zielverzeichnis im Home-Verzeichnis
TARGET_DIR=~/gitlab-compose

echo -e "${GREEN}GitLab CE Installation mit Docker Compose wird gestartet...${NC}"

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
    cp "$SCRIPT_DIR/example.env" ./.env

    echo ""
    echo -e "${YELLOW}================================================${NC}"
    echo -e "${YELLOW}WICHTIG: Bitte passen Sie die .env Datei an!${NC}"
    echo -e "${YELLOW}================================================${NC}"
    echo -e "${YELLOW}Die Datei befindet sich in: $TARGET_DIR/.env${NC}"
    echo ""
    echo -e "${YELLOW}Erforderliche Anpassungen:${NC}"
    echo -e "  1. GITLAB_HOSTNAME auf Ihre Domain setzen"
    echo -e "  2. SMTP Konfiguration für E-Mail-Versand:"
    echo -e "     - SMTP_HOST, SMTP_PORT, SMTP_USERNAME, SMTP_PASSWORD"
    echo -e "  3. Optional: GITLAB_PUMA_WORKERS und GITLAB_SIDEKIQ_CONCURRENCY"
    echo -e "     an Server-RAM anpassen"
    echo ""
    echo -e "${YELLOW}Nach der Anpassung führen Sie aus:${NC}"
    echo -e "  cd $TARGET_DIR && docker compose up -d"
    echo ""
    echo -e "${RED}HINWEIS: GitLab benötigt mindestens 4GB RAM!${NC}"
    echo -e "${RED}Der erste Start kann 5-10 Minuten dauern.${NC}"
    echo -e "${YELLOW}================================================${NC}"
    exit 0
else
    echo -e "${YELLOW}.env Datei existiert bereits in $TARGET_DIR${NC}"
fi

# Docker Compose starten
echo -e "${YELLOW}Starte GitLab CE mit Docker Compose in $TARGET_DIR...${NC}"
echo -e "${YELLOW}Der erste Start kann 5-10 Minuten dauern...${NC}"
docker compose up -d

# Erfolgsmeldung
echo -e "${GREEN}GitLab CE Installation abgeschlossen!${NC}"
echo ""
echo -e "${GREEN}Next Steps:${NC}"
echo -e "${YELLOW}1. Richten Sie einen Proxy Host in Nginx Proxy Manager ein:${NC}"
echo -e "   - Domain: gitlab.example.com (Ihre Domain aus .env)"
echo -e "   - Forward Hostname/IP: gitlab (Container-Name)"
echo -e "   - Forward Port: 80"
echo -e "   - WebSocket Support: Aktiviert"
echo -e "   - SSL: Let's Encrypt Zertifikat"
echo ""
echo -e "${YELLOW}2. Warten Sie bis GitLab bereit ist:${NC}"
echo -e "   docker compose logs -f gitlab"
echo -e "   (Warten auf: 'master process ready')"
echo ""
echo -e "${YELLOW}3. Initiales Root-Passwort abrufen:${NC}"
echo -e "   docker compose exec gitlab grep 'Password:' /etc/gitlab/initial_root_password"
echo ""
echo -e "${YELLOW}4. Einloggen unter: https://\$(grep GITLAB_HOSTNAME .env | cut -d= -f2)${NC}"
echo -e "   - User: root"
echo -e "   - Passwort: siehe Schritt 3"
echo ""
echo -e "${YELLOW}5. API Token erstellen für Conductor:${NC}"
echo -e "   - User Settings → Access Tokens → Personal Access Token"
echo -e "   - Scopes: api, read_user, read_repository, write_repository"
echo ""
echo -e "${GREEN}Dokumentation: https://docs.gitlab.com${NC}"
