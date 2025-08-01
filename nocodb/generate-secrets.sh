#!/bin/bash

# ---------------------------------------------
# NocoDB Secret Generator
# ---------------------------------------------

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}NocoDB Secret Generator${NC}"
echo -e "${YELLOW}Dieses Script generiert sichere Secrets für NocoDB${NC}"

# Check if .env exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}Keine .env gefunden, kopiere example.env${NC}"
    cp example.env .env
fi

# Function to generate secure random string
generate_secret() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-32
}

# Load current .env
source .env

# Generate JWT Secret if needed
if [ -z "$NC_AUTH_JWT_SECRET" ] || [ "$NC_AUTH_JWT_SECRET" == "your-very-secure-jwt-secret-min-32-chars" ]; then
    echo -e "${YELLOW}Generiere neuen NC_AUTH_JWT_SECRET...${NC}"
    NEW_JWT_SECRET=$(generate_secret)
    sed -i "s/^NC_AUTH_JWT_SECRET=.*/NC_AUTH_JWT_SECRET=$NEW_JWT_SECRET/" .env
fi

# Generate Connection Encryption Key if needed
if [ -z "$NC_CONNECTION_ENCRYPT_KEY" ] || [ "$NC_CONNECTION_ENCRYPT_KEY" == "your-32-character-encryption-key-here" ]; then
    echo -e "${YELLOW}Generiere neuen NC_CONNECTION_ENCRYPT_KEY...${NC}"
    NEW_ENCRYPT_KEY=$(generate_secret)
    sed -i "s/^NC_CONNECTION_ENCRYPT_KEY=.*/NC_CONNECTION_ENCRYPT_KEY=$NEW_ENCRYPT_KEY/" .env
fi

# Generate secure passwords if still default
if [ "$POSTGRES_PASSWORD" == "nocodb_secure_password" ]; then
    echo -e "${YELLOW}Generiere sicheres PostgreSQL Passwort...${NC}"
    NEW_PG_PASS=$(openssl rand -base64 16)
    sed -i "s/^POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$NEW_PG_PASS/" .env
fi

if [ "$REDIS_PASSWORD" == "redis_secure_password" ]; then
    echo -e "${YELLOW}Generiere sicheres Redis Passwort...${NC}"
    NEW_REDIS_PASS=$(openssl rand -base64 16)
    sed -i "s/^REDIS_PASSWORD=.*/REDIS_PASSWORD=$NEW_REDIS_PASS/" .env
fi

# Generate admin password if default
if [ "$NC_ADMIN_PASSWORD" == "Admin123!@#" ]; then
    echo -e "${YELLOW}Generiere sicheres Admin Passwort...${NC}"
    # Password must be at least 8 chars with uppercase, number, and special char
    NEW_ADMIN_PASS="Nc$(openssl rand -base64 6)!@"
    sed -i "s/^NC_ADMIN_PASSWORD=.*/NC_ADMIN_PASSWORD=$NEW_ADMIN_PASS/" .env
    echo -e "${GREEN}Neues Admin-Passwort: $NEW_ADMIN_PASS${NC}"
    echo -e "${RED}WICHTIG: Notieren Sie sich dieses Passwort!${NC}"
fi

echo -e "${GREEN}Secrets erfolgreich generiert und in .env gespeichert!${NC}"
echo -e "${YELLOW}Bitte überprüfen Sie die .env Datei und passen Sie weitere Einstellungen an.${NC}"
