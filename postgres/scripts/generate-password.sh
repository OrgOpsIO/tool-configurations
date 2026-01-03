#!/bin/bash

# Generiert ein sicheres, zufälliges Passwort
# Verwendung: ./generate-password.sh [Länge]

LENGTH=${1:-32}

# Prüfe ob openssl verfügbar ist
if command -v openssl &> /dev/null; then
    # Generiere mit openssl (sicherer)
    openssl rand -base64 48 | tr -d "=+/" | cut -c1-${LENGTH}
else
    # Fallback auf /dev/urandom
    LC_ALL=C tr -dc 'A-Za-z0-9!@#$%^&*()_+-=' < /dev/urandom | head -c ${LENGTH}
fi
