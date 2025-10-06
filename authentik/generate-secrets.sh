#!/bin/bash

# ---------------------------------------------
# Generierung von sicheren Secrets für Authentik
# ---------------------------------------------

# Farben für die Ausgabe
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Aktuelles Verzeichnis des Skripts
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo -e "${GREEN}Generiere sichere Secrets für Authentik...${NC}"

# Überprüfen ob openssl verfügbar ist
if ! command -v openssl &> /dev/null; then
    echo -e "${RED}openssl ist nicht installiert. Bitte installieren Sie openssl.${NC}"
    exit 1
fi

# PostgreSQL Password generieren (36 Zeichen)
PG_PASS=$(openssl rand -base64 36 | tr -d '\n')
echo -e "${YELLOW}PostgreSQL Password generiert.${NC}"

# Authentik Secret Key generieren (60 Zeichen, mindestens 50 erforderlich)
AUTHENTIK_SECRET_KEY=$(openssl rand -base64 60 | tr -d '\n')
echo -e "${YELLOW}Authentik Secret Key generiert.${NC}"

# .env Datei erstellen oder aktualisieren
ENV_FILE="${SCRIPT_DIR}/.env"

if [ -f "$ENV_FILE" ]; then
    echo -e "${YELLOW}.env Datei existiert bereits. Aktualisiere nur die Secrets...${NC}"
    
    # Secrets in bestehender .env aktualisieren
    if grep -q "^PG_PASS=" "$ENV_FILE"; then
        sed -i.bak "s|^PG_PASS=.*|PG_PASS=${PG_PASS}|" "$ENV_FILE"
    else
        echo "PG_PASS=${PG_PASS}" >> "$ENV_FILE"
    fi
    
    if grep -q "^AUTHENTIK_SECRET_KEY=" "$ENV_FILE"; then
        sed -i.bak "s|^AUTHENTIK_SECRET_KEY=.*|AUTHENTIK_SECRET_KEY=${AUTHENTIK_SECRET_KEY}|" "$ENV_FILE"
    else
        echo "AUTHENTIK_SECRET_KEY=${AUTHENTIK_SECRET_KEY}" >> "$ENV_FILE"
    fi
    
    # Backup-Datei entfernen
    rm -f "${ENV_FILE}.bak"
else
    echo -e "${YELLOW}Erstelle neue .env Datei aus example.env...${NC}"
    
    # example.env kopieren
    if [ -f "${SCRIPT_DIR}/example.env" ]; then
        cp "${SCRIPT_DIR}/example.env" "$ENV_FILE"
        
        # Generierte Secrets eintragen
        sed -i.bak "s|^PG_PASS=.*|PG_PASS=${PG_PASS}|" "$ENV_FILE"
        sed -i.bak "s|^AUTHENTIK_SECRET_KEY=.*|AUTHENTIK_SECRET_KEY=${AUTHENTIK_SECRET_KEY}|" "$ENV_FILE"
        
        # Backup-Datei entfernen
        rm -f "${ENV_FILE}.bak"
    else
        echo -e "${RED}example.env nicht gefunden!${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}Secrets erfolgreich generiert und in .env eingetragen!${NC}"
echo -e "${YELLOW}Bitte passen Sie noch die folgenden Werte in der .env an:${NC}"
echo -e "  - AUTHENTIK_EMAIL__HOST"
echo -e "  - AUTHENTIK_EMAIL__PORT"
echo -e "  - AUTHENTIK_EMAIL__USERNAME"
echo -e "  - AUTHENTIK_EMAIL__PASSWORD"
echo -e "  - AUTHENTIK_EMAIL__FROM"
echo ""
echo -e "${GREEN}Hinweis: Die generierten Secrets sind sicher und sollten nicht geändert werden.${NC}"
