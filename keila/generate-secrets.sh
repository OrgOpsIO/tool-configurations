#!/bin/bash

# ---------------------------------------------
# Keila Secret Generator
# ---------------------------------------------

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Keila Secret Generator${NC}"
echo -e "${YELLOW}Dieses Script generiert sichere Secrets für Keila${NC}"

# Check if .env exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}Keine .env gefunden, kopiere example.env${NC}"
    cp example.env .env
fi

# Load current .env
source .env

# Function to generate secure secret
generate_secret() {
    local length=${1:-64}
    head -c $((length * 3 / 4)) /dev/urandom | base64 | tr -d '\n'
}

# Generate SECRET_KEY_BASE if needed (minimum 64 characters)
if [ -z "$SECRET_KEY_BASE" ]; then
    echo -e "${YELLOW}Generiere SECRET_KEY_BASE (64+ Zeichen)...${NC}"
    NEW_SECRET=$(generate_secret 64)
    sed -i "s/^SECRET_KEY_BASE=.*/SECRET_KEY_BASE=$NEW_SECRET/" .env
fi

# Generate HASHID_SALT if needed
if [ -z "$HASHID_SALT" ]; then
    echo -e "${YELLOW}Generiere HASHID_SALT...${NC}"
    NEW_SALT=$(generate_secret 32)
    sed -i "s/^HASHID_SALT=.*/HASHID_SALT=$NEW_SALT/" .env
fi

# Generate secure passwords if still default
if [ "$POSTGRES_PASSWORD" == "keila_secure_password" ]; then
    echo -e "${YELLOW}Generiere sicheres PostgreSQL Passwort...${NC}"
    NEW_PG_PASS=$(openssl rand -base64 16)
    sed -i "s/^POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$NEW_PG_PASS/" .env
fi

# Generate root password if default (minimum 10 characters)
if [ "$KEILA_ROOT_PASSWORD" == "Admin123!@#Keila" ]; then
    echo -e "${YELLOW}Generiere sicheres Root Passwort (min. 10 Zeichen)...${NC}"
    # Password must be at least 10 chars
    NEW_ROOT_PASS="Kl$(openssl rand -base64 12)!@"
    sed -i "s/^KEILA_ROOT_PASSWORD=.*/KEILA_ROOT_PASSWORD=$NEW_ROOT_PASS/" .env
    echo -e "${GREEN}Neues Root-Passwort: $NEW_ROOT_PASS${NC}"
    echo -e "${RED}WICHTIG: Notieren Sie sich dieses Passwort!${NC}"
fi

echo -e "${GREEN}Secrets erfolgreich generiert und in .env gespeichert!${NC}"
echo -e "${YELLOW}WICHTIG: Konfigurieren Sie noch die SMTP-Einstellungen in der .env!${NC}"
echo -e "${YELLOW}Ohne korrekte SMTP-Konfiguration können keine System-E-Mails versendet werden.${NC}"