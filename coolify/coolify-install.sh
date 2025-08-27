#!/bin/bash

# ---------------------------------------------
# Coolify Docker-Compose Installation
# Based on official Coolify installation
# ---------------------------------------------

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Aktuelles Verzeichnis des Skripts
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Zielverzeichnis im Home-Verzeichnis
TARGET_DIR=~/coolify-compose
CURRENT_USER=$USER

echo -e "${GREEN}Coolify Installation mit Docker Compose wird gestartet...${NC}"
echo -e "${YELLOW}Basierend auf der offiziellen Coolify-Installation${NC}"

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

# Überprüfen, ob die .env existiert, sonst example.env kopieren und generieren
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}Kopiere example.env nach .env und generiere sichere Werte...${NC}"
    cp "$SCRIPT_DIR/example.env" ./.env

    # Generate secure values (wie im offiziellen Script)
    sed -i "s|^APP_ID=.*|APP_ID=$(openssl rand -hex 16)|" .env
    sed -i "s|^APP_KEY=.*|APP_KEY=base64:$(openssl rand -base64 32)|" .env
    sed -i "s|^DB_PASSWORD=.*|DB_PASSWORD=$(openssl rand -base64 32)|" .env
    sed -i "s|^REDIS_PASSWORD=.*|REDIS_PASSWORD=$(openssl rand -base64 32)|" .env
    sed -i "s|^PUSHER_APP_ID=.*|PUSHER_APP_ID=$(openssl rand -hex 32)|" .env
    sed -i "s|^PUSHER_APP_KEY=.*|PUSHER_APP_KEY=$(openssl rand -hex 32)|" .env
    sed -i "s|^PUSHER_APP_SECRET=.*|PUSHER_APP_SECRET=$(openssl rand -hex 32)|" .env

    # Generate Instance ID
    INSTANCE_ID=$(uuidgen 2>/dev/null | tr '[:upper:]' '[:lower:]' || openssl rand -hex 16)
    sed -i "s|^COOLIFY_INSTANCE_ID=.*|COOLIFY_INSTANCE_ID=$INSTANCE_ID|" .env

    echo -e "${GREEN}Sichere Werte wurden generiert!${NC}"
else
    echo -e "${YELLOW}.env existiert bereits${NC}"
fi

# Verzeichnisstruktur erstellen (wie im offiziellen Script)
echo -e "${YELLOW}Erstelle Coolify-Verzeichnisstruktur...${NC}"
mkdir -p coolify/{ssh,applications,databases,services,backups,webhooks-during-maintenance}
mkdir -p coolify/ssh/{keys,mux}

# SSH-Key für localhost generieren
if [ ! -f coolify/ssh/keys/id.${CURRENT_USER}@host.docker.internal ]; then
    echo -e "${YELLOW}Generiere SSH-Key für localhost-Zugriff...${NC}"
    ssh-keygen -t ed25519 -a 100 -f coolify/ssh/keys/id.${CURRENT_USER}@host.docker.internal -q -N "" -C coolify

    # SSH-Key zu authorized_keys hinzufügen
    if [ ! -f ~/.ssh/authorized_keys ]; then
        mkdir -p ~/.ssh
        chmod 700 ~/.ssh
        touch ~/.ssh/authorized_keys
        chmod 600 ~/.ssh/authorized_keys
    fi

    cat coolify/ssh/keys/id.${CURRENT_USER}@host.docker.internal.pub >> ~/.ssh/authorized_keys
    rm -f coolify/ssh/keys/id.${CURRENT_USER}@host.docker.internal.pub
fi

# Berechtigungen setzen (UID 9999 wie im offiziellen Script)
echo -e "${YELLOW}Setze korrekte Berechtigungen...${NC}"
sudo chown -R 9999:root coolify
sudo chmod -R 700 coolify

# Docker Compose starten
echo -e "${YELLOW}Starte Coolify mit Docker Compose...${NC}"
docker compose up -d

# Warte auf den Start
echo -e "${YELLOW}Warte auf Coolify Start (30 Sekunden für Datenbank-Migrationen)...${NC}"
sleep 30

# Check ob Coolify läuft
if curl -s --fail http://localhost:8080/api/health >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Coolify läuft erfolgreich!${NC}"
else
    echo -e "${RED}⚠️  Coolify Health-Check fehlgeschlagen. Prüfe die Logs mit: docker logs coolify${NC}"
fi

# Erfolgsmeldung
echo -e "${GREEN}Coolify-Installation abgeschlossen!${NC}"
echo -e ""
echo -e "${YELLOW}=== NPM Proxy Host Konfiguration ===${NC}"
echo -e "${YELLOW}1. Öffnen Sie http://$(hostname -I | awk '{print $1}'):81${NC}"
echo -e "${YELLOW}2. Fügen Sie einen neuen Proxy Host hinzu:${NC}"
echo -e "   - Domain: deploy.orgops.io"
echo -e "   - Scheme: http"
echo -e "   - Forward Hostname/IP: coolify"
echo -e "   - Forward Port: 8080"
echo -e "   - WebSocket Support: Aktivieren"
echo -e "   - Block Common Exploits: Aktivieren"
echo -e "   - SSL: Let's Encrypt aktivieren"
echo -e ""
echo -e "${YELLOW}3. Für Soketi/Realtime fügen Sie einen weiteren Proxy Host hinzu:${NC}"
echo -e "   - Domain: soketi.deploy.orgops.io"
echo -e "   - Forward Hostname/IP: coolify-realtime"
echo -e "   - Forward Port: 6001"
echo -e "   - WebSocket Support: Aktivieren"
echo -e ""
echo -e "${GREEN}Nach der NPM-Konfiguration:${NC}"
echo -e "URL: https://deploy.orgops.io"
echo -e ""
echo -e "${YELLOW}Bei der ersten Anmeldung werden Sie aufgefordert, einen Admin-Account zu erstellen.${NC}"
echo -e ""
echo -e "${RED}WICHTIG: Sichern Sie Ihre .env-Datei an einem sicheren Ort!${NC}"

# Backup der .env erstellen
cp .env .env.backup