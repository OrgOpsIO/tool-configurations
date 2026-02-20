#!/bin/bash

# ---------------------------------------------
# Vibe Kanban Docker-Compose Installation
# ---------------------------------------------

# Farben für die Ausgabe
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Aktuelles Verzeichnis des Skripts
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Zielverzeichnis im Home-Verzeichnis
TARGET_DIR=~/vibekanban-compose

echo -e "${GREEN}Vibe Kanban Installation mit Docker Compose wird gestartet...${NC}"

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

# Vibe Kanban Repository klonen oder aktualisieren
if [ ! -d "vibe-kanban" ]; then
    echo -e "${YELLOW}Klone Vibe Kanban Repository...${NC}"
    git clone --depth 1 https://github.com/BloopAI/vibe-kanban.git vibe-kanban
else
    echo -e "${YELLOW}Vibe Kanban Repository existiert bereits, aktualisiere...${NC}"
    cd vibe-kanban && git pull && cd ..
fi

# Überprüfen, ob die .env existiert, sonst example.env kopieren
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}Kopiere example.env nach $TARGET_DIR/.env${NC}"
    cp "$SCRIPT_DIR/example.env" ./.env

    # Generiere sicheres JWT Secret
    echo -e "${YELLOW}Generiere sicheres JWT Secret...${NC}"
    JWT_SECRET=$(openssl rand -hex 32)
    sed -i "s|^VIBEKANBAN_REMOTE_JWT_SECRET=.*|VIBEKANBAN_REMOTE_JWT_SECRET=$JWT_SECRET|" .env

    # Generiere sicheres DB Passwort (nur alphanumerische Zeichen für URL-Kompatibilität)
    echo -e "${YELLOW}Generiere sicheres PostgreSQL Passwort...${NC}"
    DB_PASS=$(openssl rand -hex 32)
    sed -i "s|^POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=$DB_PASS|" .env

    # Generiere sicheres ElectricSQL Passwort
    echo -e "${YELLOW}Generiere sicheres ElectricSQL Passwort...${NC}"
    ELECTRIC_PASS=$(openssl rand -hex 32)
    sed -i "s|^ELECTRIC_ROLE_PASSWORD=.*|ELECTRIC_ROLE_PASSWORD=$ELECTRIC_PASS|" .env

    echo -e "${RED}Wichtig: Konfigurieren Sie mindestens einen OAuth-Provider (GitHub oder Google) in .env${NC}"
    echo -e "${YELLOW}Bitte passen Sie die .env Datei in $TARGET_DIR an Ihre Bedürfnisse an.${NC}"
else
    echo -e "${YELLOW}.env existiert bereits in $TARGET_DIR${NC}"
fi

# Docker Compose bauen und starten
echo -e "${YELLOW}Baue und starte Vibe Kanban mit Docker Compose in $TARGET_DIR...${NC}"
echo -e "${YELLOW}Hinweis: Der erste Build kann 5-10 Minuten dauern (Rust-Kompilierung)...${NC}"
docker compose up -d --build

# Warte auf den Start
echo -e "${YELLOW}Warte auf Vibe Kanban Start (Datenbank-Migration läuft)...${NC}"
sleep 30

# Health Check
if docker compose exec -T server wget --spider -q http://127.0.0.1:8081/v1/health 2>/dev/null; then
    echo -e "${GREEN}✅ Vibe Kanban läuft erfolgreich!${NC}"
else
    echo -e "${YELLOW}⚠️  Vibe Kanban startet noch... Prüfe in 60 Sekunden erneut.${NC}"
    echo -e "${YELLOW}   Erster Build kann mehrere Minuten dauern.${NC}"
fi

# Erfolgsmeldung
echo -e "${GREEN}Vibe Kanban Installation abgeschlossen!${NC}"
if [ -f ".env" ]; then
    # Laden der Umgebungsvariablen aus .env für die Ausgabe
    source .env
    echo -e "${GREEN}Ihre Vibe Kanban Instanz wird jetzt gebaut und gestartet.${NC}"
    echo -e "${YELLOW}Wichtig: Konfigurieren Sie einen Proxy Host in Nginx Proxy Manager:${NC}"
    echo -e "${YELLOW}1. Öffnen Sie http://$(hostname -I | awk '{print $1}'):81${NC}"
    echo -e "${YELLOW}2. Fügen Sie einen neuen Proxy Host hinzu:${NC}"
    echo -e "${YELLOW}   - Domain: ${SUBDOMAIN}.${DOMAIN_NAME}${NC}"
    echo -e "${YELLOW}   - Scheme: http${NC}"
    echo -e "${YELLOW}   - Forward Hostname/IP: server${NC}"
    echo -e "${YELLOW}   - Forward Port: 8081${NC}"
    echo -e "${YELLOW}   - Block Common Exploits: Aktivieren${NC}"
    echo -e "${YELLOW}   - Aktivieren Sie SSL und wählen Sie Let's Encrypt${NC}"
    echo -e ""
    echo -e "${YELLOW}   Erweiterte Nginx-Konfiguration (Custom Nginx Configuration):${NC}"
    echo -e "${YELLOW}   client_max_body_size 100M;${NC}"
    echo -e "${YELLOW}   proxy_read_timeout 86400s;${NC}"
    echo -e ""
    echo -e "${YELLOW}3. Stellen Sie sicher, dass ein DNS A-Record für ${SUBDOMAIN}.${DOMAIN_NAME} existiert${NC}"
    echo -e ""
    echo -e "${GREEN}Nach der Proxy-Konfiguration:${NC}"
    echo -e "URL: https://${SUBDOMAIN}.${DOMAIN_NAME}"
    echo -e ""
    echo -e "${RED}Hinweis: Konfigurieren Sie mindestens einen OAuth-Provider in der .env!${NC}"
    echo -e "GitHub OAuth Callback: https://${SUBDOMAIN}.${DOMAIN_NAME}/v1/oauth/github/callback"
    echo -e "Google OAuth Callback: https://${SUBDOMAIN}.${DOMAIN_NAME}/v1/oauth/google/callback"
    echo -e ""
    echo -e "${GREEN}Nützliche Befehle:${NC}"
    echo -e "- Logs anzeigen: cd $TARGET_DIR && docker compose logs -f"
    echo -e "- Health Check: docker compose exec server wget --spider -q http://127.0.0.1:8081/v1/health"
    echo -e "- Neustart: cd $TARGET_DIR && docker compose restart"
    echo -e "- Update: cd $TARGET_DIR/vibe-kanban && git pull && cd .. && docker compose up -d --build"
fi
