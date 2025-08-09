#!/bin/bash

# ---------------------------------------------
# Keila Docker-Compose Installation
# ---------------------------------------------

# Farben für die Ausgabe
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Aktuelles Verzeichnis des Skripts
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Zielverzeichnis im Home-Verzeichnis
TARGET_DIR=~/keila-compose

echo -e "${GREEN}Keila Installation mit Docker Compose wird gestartet...${NC}"

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

# Secret Generator kopieren
if [ ! -f "generate-secrets.sh" ]; then
    echo -e "${YELLOW}Kopiere generate-secrets.sh nach $TARGET_DIR${NC}"
    cp "$SCRIPT_DIR/generate-secrets.sh" .
    chmod +x generate-secrets.sh
fi

# Überprüfen, ob die .env existiert, sonst example.env kopieren
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}Kopiere example.env nach $TARGET_DIR/.env${NC}"
    cp "$SCRIPT_DIR/.env" ./.env

    # Secrets generieren
    echo -e "${YELLOW}Generiere sichere Secrets...${NC}"
    ./generate-secrets.sh

    echo -e "${RED}WICHTIG: Konfigurieren Sie die SMTP-Einstellungen in der .env Datei!${NC}"
    echo -e "${YELLOW}Ohne SMTP können keine System-E-Mails (Registrierung, Passwort-Reset) versendet werden.${NC}"
fi

# Verzeichnisse erstellen, falls sie nicht existieren
echo -e "${YELLOW}Erstelle benötigte Verzeichnisse in $TARGET_DIR${NC}"
mkdir -p postgres/data
mkdir -p uploads
mkdir -p keila/data

# Berechtigungen setzen
echo -e "${YELLOW}Setze korrekte Berechtigungen...${NC}"
chmod -R 755 uploads/
chmod -R 755 keila/

# Docker Compose starten
echo -e "${YELLOW}Starte Keila mit Docker Compose in $TARGET_DIR...${NC}"
docker compose up -d

# Warte auf den Start
echo -e "${YELLOW}Warte auf Keila Start...${NC}"
sleep 10

# Erfolgsmeldung
echo -e "${GREEN}Keila-Installation abgeschlossen!${NC}"
if [ -f ".env" ]; then
    # Laden der Umgebungsvariablen aus .env für die Ausgabe
    source .env
    echo -e "${GREEN}Ihre Keila-Instanz läuft jetzt.${NC}"
    echo -e "${YELLOW}Wichtig: Konfigurieren Sie einen Proxy Host in Nginx Proxy Manager:${NC}"
    echo -e "${YELLOW}1. Öffnen Sie http://$(hostname -I | awk '{print $1}'):81${NC}"
    echo -e "${YELLOW}2. Fügen Sie einen neuen Proxy Host hinzu:${NC}"
    echo -e "${YELLOW}   - Domain: ${SUBDOMAIN}.${DOMAIN_NAME}${NC}"
    echo -e "${YELLOW}   - Scheme: http${NC}"
    echo -e "${YELLOW}   - Forward Hostname/IP: keila${NC}"
    echo -e "${YELLOW}   - Forward Port: 4000${NC}"
    echo -e "${YELLOW}   - Block Common Exploits: Aktivieren${NC}"
    echo -e "${YELLOW}   - Aktivieren Sie SSL und wählen Sie Let's Encrypt${NC}"
    echo -e ""
    echo -e "${YELLOW}3. Für User-Uploads fügen Sie eine Custom Location hinzu:${NC}"
    echo -e "${YELLOW}   - Location: /uploads${NC}"
    echo -e "${YELLOW}   - Forward Hostname/IP: keila${NC}"
    echo -e "${YELLOW}   - Forward Port: 4000${NC}"
    echo -e ""
    echo -e "${YELLOW}4. Stellen Sie sicher, dass ein DNS A-Record für ${SUBDOMAIN}.${DOMAIN_NAME} existiert${NC}"
    echo -e ""
    echo -e "${GREEN}Nach der Proxy-Konfiguration:${NC}"
    echo -e "URL: https://${SUBDOMAIN}.${DOMAIN_NAME}"
    echo -e "Root E-Mail: ${KEILA_ROOT_EMAIL}"
    echo -e "Root Passwort: ${KEILA_ROOT_PASSWORD}"
    echo -e ""
    echo -e "${RED}WICHTIG:${NC}"
    echo -e "${RED}1. Notieren Sie sich das Root-Passwort!${NC}"
    echo -e "${RED}2. Konfigurieren Sie die SMTP-Einstellungen in der .env Datei!${NC}"
    echo -e "${RED}3. Starten Sie Container neu nach SMTP-Konfiguration: docker compose restart keila${NC}"
fi

# Check SMTP configuration
if [ -z "$SMTP_HOST" ] || [ "$SMTP_HOST" == "smtp.example.com" ]; then
    echo -e ""
    echo -e "${RED}⚠️  WARNUNG: SMTP ist noch nicht konfiguriert!${NC}"
    echo -e "${YELLOW}Bearbeiten Sie die .env Datei und setzen Sie:${NC}"
    echo -e "  - SMTP_HOST"
    echo -e "  - SMTP_USER"
    echo -e "  - SMTP_PASSWORD"
    echo -e "${YELLOW}Dann: docker compose restart keila${NC}"
fi