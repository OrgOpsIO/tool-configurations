#!/bin/bash

# ---------------------------------------------
# Web-App Docker-Compose Installation
# Generische Deployment-Hülle für Web-Anwendungen
# ---------------------------------------------

# Farben für die Ausgabe
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Aktuelles Verzeichnis des Skripts
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# App-Name als Parameter
APP_NAME=$1

# Überprüfen, ob App-Name angegeben wurde
if [ -z "$APP_NAME" ]; then
    echo -e "${RED}Fehler: Kein App-Name angegeben!${NC}"
    echo -e "${YELLOW}Verwendung: $0 <app-name>${NC}"
    echo -e "${YELLOW}Beispiel: $0 shop${NC}"
    exit 1
fi

# Validierung des App-Namens (nur alphanumerisch und Bindestriche)
if ! [[ "$APP_NAME" =~ ^[a-zA-Z0-9-]+$ ]]; then
    echo -e "${RED}Fehler: App-Name darf nur Buchstaben, Zahlen und Bindestriche enthalten!${NC}"
    exit 1
fi

# Zielverzeichnis im Home-Verzeichnis
TARGET_DIR=~/web-apps/${APP_NAME}

echo -e "${GREEN}Web-App Installation für '${APP_NAME}' wird gestartet...${NC}"

# Prüfen ob das Proxy-Netzwerk existiert
if ! docker network inspect proxy_network &>/dev/null; then
    echo -e "${RED}Das Proxy-Netzwerk existiert nicht. Stellen Sie sicher, dass Nginx Proxy Manager installiert ist.${NC}"
    echo -e "${YELLOW}Führen Sie zuerst './install.sh npm' aus oder installieren Sie den Proxy manuell.${NC}"
    exit 1
fi

# Überprüfen, ob das Zielverzeichnis bereits existiert
if [ -d "$TARGET_DIR" ]; then
    echo -e "${RED}Fehler: Verzeichnis $TARGET_DIR existiert bereits!${NC}"
    echo -e "${YELLOW}Bitte wählen Sie einen anderen App-Namen oder löschen Sie das bestehende Verzeichnis.${NC}"
    exit 1
fi

# Verzeichnisstruktur erstellen
echo -e "${YELLOW}Erstelle Verzeichnisstruktur in $TARGET_DIR${NC}"
mkdir -p "$TARGET_DIR"
mkdir -p "$TARGET_DIR/app"

# Ins Zielverzeichnis wechseln
cd "$TARGET_DIR" || exit 1

# docker-compose.yml kopieren und Platzhalter ersetzen
echo -e "${YELLOW}Erstelle docker-compose.yml für App '${APP_NAME}'...${NC}"
sed "s/{{APP_NAME}}/${APP_NAME}/g" "$SCRIPT_DIR/docker-compose.yml" > docker-compose.yml

# example.env kopieren und Platzhalter ersetzen
echo -e "${YELLOW}Erstelle .env Datei für App '${APP_NAME}'...${NC}"
sed "s/{{APP_NAME}}/${APP_NAME}/g" "$SCRIPT_DIR/example.env" > .env

# Dockerfile.example als Referenz kopieren
echo -e "${YELLOW}Kopiere Dockerfile.example als Referenz...${NC}"
cp "$SCRIPT_DIR/Dockerfile.example" .

# Erfolgsmeldung
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Web-App '${APP_NAME}' erfolgreich vorbereitet!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e ""
echo -e "${BLUE}📁 Installationsverzeichnis: ${TARGET_DIR}${NC}"
echo -e ""
echo -e "${YELLOW}📋 NÄCHSTE SCHRITTE:${NC}"
echo -e "${YELLOW}──────────────────────────────────────────────────────────${NC}"
echo -e ""
echo -e "1️⃣  ${BLUE}Wechseln Sie ins Verzeichnis:${NC}"
echo -e "   cd $TARGET_DIR"
echo -e ""
echo -e "2️⃣  ${BLUE}Passen Sie die .env Datei an:${NC}"
echo -e "   nano .env"
echo -e "   ${YELLOW}→ Setzen Sie SUBDOMAIN, DOMAIN_NAME und weitere Variablen${NC}"
echo -e ""
echo -e "3️⃣  ${BLUE}Klonen Sie Ihre App ins app/ Verzeichnis:${NC}"
echo -e "   git clone <your-repo-url> app"
echo -e "   ${YELLOW}→ Ihre App muss ein Dockerfile im Root enthalten${NC}"
echo -e "   ${YELLOW}→ Siehe Dockerfile.example für Beispiele${NC}"
echo -e ""
echo -e "4️⃣  ${BLUE}Starten Sie die App:${NC}"
echo -e "   docker compose up -d"
echo -e ""
echo -e "5️⃣  ${BLUE}Konfigurieren Sie den Nginx Proxy Manager:${NC}"
echo -e "   ${YELLOW}→ Erstellen Sie einen neuen Proxy Host${NC}"
echo -e "   ${YELLOW}→ Domain: <subdomain>.<domain>${NC}"
echo -e "   ${YELLOW}→ Forward zu: web-app-${APP_NAME}:<port>${NC}"
echo -e "   ${YELLOW}→ Port ist typischerweise 3000 (siehe APP_PORT in .env)${NC}"
echo -e ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e ""
echo -e "${YELLOW}💡 TIPPS:${NC}"
echo -e "   • App aktualisieren: cd $TARGET_DIR && git -C app pull && docker compose up -d --build"
echo -e "   • Logs anzeigen: docker compose logs -f"
echo -e "   • App stoppen: docker compose down"
echo -e "   • App neu bauen: docker compose up -d --build"
echo -e ""
