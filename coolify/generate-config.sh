#!/bin/bash

# ---------------------------------------------
# Coolify Configuration Generator
# ---------------------------------------------

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Coolify Configuration Generator${NC}"
echo -e "${YELLOW}Dieses Script generiert die benötigten Konfigurationswerte${NC}"

# Check if .env exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}Keine .env gefunden, kopiere example.env${NC}"
    cp example.env .env
fi

# Load current .env
source .env

# Function to generate random string
generate_random() {
    local length=${1:-32}
    openssl rand -hex $((length / 2))
}

# Generate APP_KEY if needed (Laravel format)
if [ -z "$COOLIFY_APP_KEY" ]; then
    echo -e "${YELLOW}Generiere COOLIFY_APP_KEY...${NC}"
    # Laravel expects base64:key format
    KEY=$(openssl rand -base64 32)
    sed -i "s|^COOLIFY_APP_KEY=.*|COOLIFY_APP_KEY=base64:$KEY|" .env
fi

# Generate Instance ID
if [ -z "$COOLIFY_INSTANCE_ID" ]; then
    echo -e "${YELLOW}Generiere COOLIFY_INSTANCE_ID...${NC}"
    INSTANCE_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')
    sed -i "s/^COOLIFY_INSTANCE_ID=.*/COOLIFY_INSTANCE_ID=$INSTANCE_ID/" .env
fi

# Generate Pusher credentials
if [ -z "$PUSHER_APP_ID" ]; then
    echo -e "${YELLOW}Generiere Pusher/Soketi Credentials...${NC}"
    PUSHER_ID=$(generate_random 8)
    PUSHER_KEY=$(generate_random 20)
    PUSHER_SECRET=$(generate_random 20)

    sed -i "s/^PUSHER_APP_ID=.*/PUSHER_APP_ID=$PUSHER_ID/" .env
    sed -i "s/^PUSHER_APP_KEY=.*/PUSHER_APP_KEY=$PUSHER_KEY/" .env
    sed -i "s/^PUSHER_APP_SECRET=.*/PUSHER_APP_SECRET=$PUSHER_SECRET/" .env
fi

# Generate Redis password if default
if [ "$REDIS_PASSWORD" == "redis_secure_password" ]; then
    echo -e "${YELLOW}Generiere sicheres Redis Passwort...${NC}"
    NEW_REDIS_PASS=$(openssl rand -base64 16)
    sed -i "s/^REDIS_PASSWORD=.*/REDIS_PASSWORD=$NEW_REDIS_PASS/" .env
fi

echo -e "${GREEN}Konfiguration erfolgreich generiert und in .env gespeichert!${NC}"