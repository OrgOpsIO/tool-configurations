#!/bin/bash

# ---------------------------------------------
# Carbone JWT Key-Paar und Token Generator
# ---------------------------------------------

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
KEYS_DIR="${1:-$SCRIPT_DIR/keys}"

echo -e "${GREEN}Carbone JWT Keys Generator${NC}"
echo ""

# Keys-Verzeichnis erstellen
mkdir -p "$KEYS_DIR"

# Pruefen ob Keys bereits existieren
if [ -f "$KEYS_DIR/key.pem" ] && [ -f "$KEYS_DIR/key.pub" ]; then
    echo -e "${YELLOW}Keys existieren bereits in $KEYS_DIR${NC}"
    read -p "Ueberschreiben? (j/N): " confirm
    if [ "$confirm" != "j" ] && [ "$confirm" != "J" ]; then
        echo -e "${YELLOW}Abgebrochen.${NC}"
        exit 0
    fi
fi

echo -e "${YELLOW}Generiere ES512 Key-Paar...${NC}"

# Private Key generieren (ES512 = secp521r1)
openssl ecparam -name secp521r1 -genkey -noout -out "$KEYS_DIR/key.pem"

# Public Key extrahieren
openssl ec -in "$KEYS_DIR/key.pem" -pubout -out "$KEYS_DIR/key.pub"

# Berechtigungen setzen
chmod 600 "$KEYS_DIR/key.pem"
chmod 644 "$KEYS_DIR/key.pub"

echo -e "${GREEN}Keys generiert:${NC}"
echo -e "  Private Key: $KEYS_DIR/key.pem"
echo -e "  Public Key:  $KEYS_DIR/key.pub"
echo ""

# JWT Token generieren
echo -e "${YELLOW}Generiere JWT Token...${NC}"
echo ""

# Token mit Docker generieren
TOKEN=$(docker run --rm -v "$KEYS_DIR/key.pem:/key.pem:ro" --platform "linux/amd64" carbone/carbone-ee:full sh -c "cat /key.pem | node dist/index.js generate-token --stdin" 2>/dev/null)

if [ -n "$TOKEN" ]; then
    echo -e "${GREEN}API Token:${NC}"
    echo ""
    echo "$TOKEN"
    echo ""
    echo "$TOKEN" > "$KEYS_DIR/api-token.txt"
    chmod 600 "$KEYS_DIR/api-token.txt"
    echo -e "${GREEN}Token gespeichert in: $KEYS_DIR/api-token.txt${NC}"
else
    echo -e "${YELLOW}Token konnte nicht automatisch generiert werden.${NC}"
    echo -e "${YELLOW}Manuell generieren mit:${NC}"
    echo ""
    echo "  docker run -it --platform \"linux/amd64\" carbone/carbone-ee:full generate-token"
    echo ""
    echo -e "${YELLOW}Dann den Private Key (key.pem) einfuegen.${NC}"
fi

echo ""
echo -e "${GREEN}Fertig!${NC}"
echo -e "${YELLOW}Starten Sie Carbone neu: docker compose up -d --force-recreate${NC}"
