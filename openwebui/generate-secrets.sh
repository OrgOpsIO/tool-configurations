#!/bin/bash

# ---------------------------------------------
# Generierung von sicheren Secrets für Open WebUI
# ---------------------------------------------

# Farben für die Ausgabe
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Aktuelles Verzeichnis des Skripts
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

echo -e "${GREEN}Generiere sichere Secrets für Open WebUI...${NC}"

# Überprüfen ob openssl verfügbar ist
if ! command -v openssl &> /dev/null; then
    echo -e "${RED}openssl ist nicht installiert. Bitte installieren Sie openssl.${NC}"
    exit 1
fi

# WEBUI Secret Key generieren (32 Bytes = 64 Zeichen hex)
WEBUI_SECRET_KEY=$(openssl rand -hex 32)
echo -e "${YELLOW}WEBUI Secret Key generiert.${NC}"

# .env Datei erstellen oder aktualisieren
ENV_FILE="${SCRIPT_DIR}/.env"

if [ -f "$ENV_FILE" ]; then
    echo -e "${YELLOW}.env Datei existiert bereits. Aktualisiere nur die Secrets...${NC}"
    
    # Secret in bestehender .env aktualisieren
    if grep -q "^WEBUI_SECRET_KEY=" "$ENV_FILE"; then
        sed -i.bak "s|^WEBUI_SECRET_KEY=.*|WEBUI_SECRET_KEY=${WEBUI_SECRET_KEY}|" "$ENV_FILE"
    else
        echo "WEBUI_SECRET_KEY=${WEBUI_SECRET_KEY}" >> "$ENV_FILE"
    fi
    
    # Backup-Datei entfernen
    rm -f "${ENV_FILE}.bak"
else
    echo -e "${YELLOW}Erstelle neue .env Datei aus example.env...${NC}"
    
    # example.env kopieren
    if [ -f "${SCRIPT_DIR}/example.env" ]; then
        cp "${SCRIPT_DIR}/example.env" "$ENV_FILE"
        
        # Generierte Secrets eintragen
        sed -i.bak "s|^WEBUI_SECRET_KEY=.*|WEBUI_SECRET_KEY=${WEBUI_SECRET_KEY}|" "$ENV_FILE"
        
        # Backup-Datei entfernen
        rm -f "${ENV_FILE}.bak"
    else
        echo -e "${RED}example.env nicht gefunden!${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}Secrets erfolgreich generiert und in .env eingetragen!${NC}"
echo -e "${YELLOW}Bitte passen Sie noch die folgenden Werte in der .env an:${NC}"
echo -e "  - SUBDOMAIN (z.B. chat, openwebui)"
echo -e "  - DOMAIN_NAME (z.B. orgops.io)"
echo -e "  - OLLAMA_BASE_URL (optional, falls Sie Ollama verwenden)"
echo ""
echo -e "${GREEN}Hinweis: Der generierte Secret Key ist sicher und sollte nicht geändert werden.${NC}"
