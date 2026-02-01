#!/bin/bash

# ---------------------------------------------
# Carbone Docker-Compose Installation
# Document Generation Engine
# ---------------------------------------------

# Farben fuer die Ausgabe
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Aktuelles Verzeichnis des Skripts
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Zielverzeichnis im Home-Verzeichnis
TARGET_DIR=~/carbone-compose

echo -e "${GREEN}Carbone Installation mit Docker Compose wird gestartet...${NC}"

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

# Ueberpruefen, ob die .env existiert, sonst example.env kopieren
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}Kopiere example.env nach $TARGET_DIR/.env${NC}"
    cp "$SCRIPT_DIR/example.env" ./.env
    echo -e "${YELLOW}Bitte passen Sie die .env Datei in $TARGET_DIR an Ihre Beduerfnisse an.${NC}"
fi

# generate-keys.sh kopieren
if [ ! -f "generate-keys.sh" ]; then
    cp "$SCRIPT_DIR/generate-keys.sh" .
    chmod +x generate-keys.sh
fi

# JWT Keys generieren falls noch nicht vorhanden
if [ ! -d "keys" ] || [ ! -f "keys/key.pub" ]; then
    echo -e "${YELLOW}Generiere JWT Keys fuer API-Authentifizierung...${NC}"
    mkdir -p keys

    # ES512 Key-Paar generieren
    openssl ecparam -name secp521r1 -genkey -noout -out keys/key.pem
    openssl ec -in keys/key.pem -pubout -out keys/key.pub
    chmod 600 keys/key.pem
    chmod 644 keys/key.pub

    echo -e "${GREEN}Keys generiert in $TARGET_DIR/keys/${NC}"
fi

# Docker Compose starten
echo -e "${YELLOW}Starte Carbone mit Docker Compose in $TARGET_DIR...${NC}"
docker compose up -d

# JWT Token generieren
if [ -f "keys/key.pem" ] && [ ! -f "keys/api-token.txt" ]; then
    echo -e "${YELLOW}Generiere API Token...${NC}"

    # Warten bis Container laeuft
    sleep 5

    TOKEN=$(docker run --rm -v "$TARGET_DIR/keys/key.pem:/key.pem:ro" --platform "linux/amd64" carbone/carbone-ee:full sh -c "cat /key.pem | node dist/index.js generate-token --stdin" 2>/dev/null)

    if [ -n "$TOKEN" ]; then
        echo "$TOKEN" > keys/api-token.txt
        chmod 600 keys/api-token.txt
        echo -e "${GREEN}API Token gespeichert in: $TARGET_DIR/keys/api-token.txt${NC}"
    else
        echo -e "${YELLOW}Token konnte nicht automatisch generiert werden.${NC}"
        echo -e "${YELLOW}Manuell generieren: ./generate-keys.sh${NC}"
    fi
fi

# Erfolgsmeldung
echo -e "${GREEN}Carbone-Installation abgeschlossen!${NC}"
echo ""
if [ -f ".env" ]; then
    source .env
    echo -e "${GREEN}Ihre Carbone-Instanz ist unter https://${SUBDOMAIN}.${DOMAIN_NAME} verfuegbar.${NC}"
    echo -e "${YELLOW}DNS A-Record fuer ${SUBDOMAIN}.${DOMAIN_NAME} nicht vergessen!${NC}"
    echo ""
    echo -e "${GREEN}Zugangsdaten:${NC}"
    echo -e "  Studio URL:    https://${SUBDOMAIN}.${DOMAIN_NAME}"
    echo -e "  Studio Login:  ${CARBONE_EE_STUDIOUSER%%:*} / ${CARBONE_EE_STUDIOUSER#*:}"
    echo ""
    if [ -f "keys/api-token.txt" ]; then
        echo -e "${GREEN}API Token:${NC}"
        cat keys/api-token.txt
        echo ""
        echo -e "${YELLOW}(Gespeichert in: $TARGET_DIR/keys/api-token.txt)${NC}"
    fi
    echo ""
    echo -e "${GREEN}API Nutzung:${NC}"
    echo -e "  curl -X POST https://${SUBDOMAIN}.${DOMAIN_NAME}/render \\"
    echo -e "    -H 'Authorization: Bearer <API_TOKEN>' \\"
    echo -e "    -H 'Content-Type: application/json' \\"
    echo -e "    -d '{\"data\": {...}, \"template\": \"base64...\"}'"
fi
