#!/bin/bash

# ---------------------------------------------
# TileDesk JWT Token Generator
# ---------------------------------------------

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${GREEN}TileDesk Token Generator${NC}"
echo -e "${YELLOW}Dieses Script generiert die benötigten JWT Tokens${NC}"

# Check if .env exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}Keine .env gefunden, kopiere example.env${NC}"
    cp example.env .env
fi

# Load existing .env
source .env

# Check if JWT_SECRET is set
if [ -z "$JWT_SECRET" ] || [ "$JWT_SECRET" == "your-secure-jwt-secret-change-this" ]; then
    echo -e "${YELLOW}Generiere neuen JWT_SECRET...${NC}"
    JWT_SECRET=$(openssl rand -base64 32)
    sed -i "s/^JWT_SECRET=.*/JWT_SECRET=$JWT_SECRET/" .env
fi

# Generate tokens using Node.js
echo -e "${YELLOW}Generiere JWT Tokens...${NC}"

# Create temporary Node.js script
cat > generate-jwt.js << 'EOF'
const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'tokenKey';

// Admin Token
const adminPayload = {
    jti: require('crypto').randomUUID(),
    sub: "100-APIADMIN",
    scope: ["rabbitmq.read:*/*/*", "rabbitmq.write:*/*/*", "rabbitmq.configure:*/*/*"],
    client_id: "100-APIADMIN",
    cid: "100-APIADMIN",
    azp: "100-APIADMIN",
    user_id: "100-APIADMIN",
    app_id: "tilechat",
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + (365 * 24 * 60 * 60 * 10), // 10 years
    aud: ["rabbitmq", "100-APIADMIN"],
    kid: "tiledesk-key",
    tiledesk_api_roles: "admin"
};

// Observer Token
const observerPayload = {
    jti: require('crypto').randomUUID(),
    sub: "01-OBSERVER",
    scope: ["rabbitmq.read:*/*/*", "rabbitmq.write:*/*/*", "rabbitmq.configure:*/*/*"],
    client_id: "01-OBSERVER",
    cid: "01-OBSERVER",
    azp: "01-OBSERVER",
    user_id: "01-OBSERVER",
    app_id: "tilechat",
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + (365 * 24 * 60 * 60 * 10), // 10 years
    aud: ["rabbitmq", "01-OBSERVER"],
    kid: "tiledesk-key",
    tiledesk_api_roles: "user"
};

const adminToken = jwt.sign(adminPayload, JWT_SECRET);
const observerToken = jwt.sign(observerPayload, JWT_SECRET);

// Webhook token
const webhookToken = require('crypto').randomBytes(32).toString('hex');

console.log('CHAT21_ADMIN_TOKEN=' + adminToken);
console.log('PUSH_WH_CHAT21_API_ADMIN_TOKEN=' + adminToken);
console.log('PUSH_WH_WEBHOOK_TOKEN=' + webhookToken);
console.log('AMQP_MANAGER_URL=amqp://ignored:' + observerToken + '@rabbitmq:5672?heartbeat=60');
console.log('CHAT21_RABBITMQ_URI=amqp://ignored:' + adminToken + '@rabbitmq:5672?heartbeat=60');
EOF

# Install jsonwebtoken if needed
if ! npm list jsonwebtoken >/dev/null 2>&1; then
    echo -e "${YELLOW}Installiere jsonwebtoken...${NC}"
    npm install jsonwebtoken --no-save >/dev/null 2>&1
fi

# Generate tokens
TOKENS=$(JWT_SECRET=$JWT_SECRET node generate-jwt.js)

# Update .env with generated tokens
while IFS= read -r line; do
    key=$(echo $line | cut -d'=' -f1)
    value=$(echo $line | cut -d'=' -f2-)
    sed -i "s|^$key=.*|$key=$value|" .env
done <<< "$TOKENS"

# Cleanup
rm -f generate-jwt.js
rm -rf node_modules package-lock.json

echo -e "${GREEN}Tokens erfolgreich generiert und in .env gespeichert!${NC}"
echo -e "${YELLOW}Wichtig: Ändern Sie noch die anderen Passwörter in der .env Datei!${NC}"
