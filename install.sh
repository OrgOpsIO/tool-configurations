#!/bin/bash

# ---------------------------------------------
# Hauptinstallationsskript für Nginx Proxy Manager, n8n, FreeScout, Mattermost, Ghost und Nextcloud
# ---------------------------------------------

# Farben für die Ausgabe
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Aktuelles Verzeichnis des Skripts
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Funktion zum Anzeigen der Hilfe
show_help() {
    echo -e "${GREEN}OrgOps Installation Helper${NC}"
    echo -e "Verwendung: $0 [npm|n8n|freescout|mattermost|ghost|nextcloud|all]"
    echo -e ""
    echo -e "Optionen:"
    echo -e "  npm        - Installiert nur Nginx Proxy Manager in ~/nginx-proxy-manager"
    echo -e "  n8n        - Installiert nur n8n in ~/n8n-compose (erfordert vorherige npm-Installation)"
    echo -e "  freescout  - Installiert nur FreeScout in ~/freescout-compose (erfordert vorherige npm-Installation)"
    echo -e "  mattermost - Installiert nur Mattermost in ~/mattermost-compose (erfordert vorherige npm-Installation)"
    echo -e "  ghost      - Installiert nur Ghost CMS in ~/ghost-compose (erfordert vorherige npm-Installation)"
    echo -e "  nextcloud  - Installiert nur Nextcloud in ~/nextcloud-compose (erfordert vorherige npm-Installation)"
    echo -e "  all        - Installiert alle Services"
    echo -e "  help       - Zeigt diese Hilfe an"
}

# Funktion zum Installieren von Nginx Proxy Manager
install_npm() {
    echo -e "${GREEN}Starte Nginx Proxy Manager Installation...${NC}"
    bash "${SCRIPT_DIR}/nginx-proxy-manager/npm-install.sh"
}

# Funktion zum Installieren von n8n
install_n8n() {
    echo -e "${GREEN}Starte n8n-Installation...${NC}"
    bash "${SCRIPT_DIR}/n8n/n8n-install.sh"
}

# Funktion zum Installieren von FreeScout
install_freescout() {
    echo -e "${GREEN}Starte FreeScout-Installation...${NC}"
    bash "${SCRIPT_DIR}/freescout/freescout-install.sh"
}

# Funktion zum Installieren von Mattermost
install_mattermost() {
    echo -e "${GREEN}Starte Mattermost-Installation...${NC}"
    bash "${SCRIPT_DIR}/mattermost/mattermost-install.sh"
}

# Funktion zum Installieren von Ghost
install_ghost() {
    echo -e "${GREEN}Starte Ghost CMS Installation...${NC}"
    bash "${SCRIPT_DIR}/ghost/ghost-install.sh"
}

# Funktion zum Installieren von Nextcloud
install_nextcloud() {
    echo -e "${GREEN}Starte Nextcloud-Installation...${NC}"
    bash "${SCRIPT_DIR}/nextcloud/nextcloud-install.sh"
}

# Hauptlogik
case "$1" in
    npm)
        install_npm
        ;;
    n8n)
        install_n8n
        ;;
    freescout)
        install_freescout
        ;;
    mattermost)
        install_mattermost
        ;;
    ghost)
        install_ghost
        ;;
    nextcloud)
        install_nextcloud
        ;;
    all)
        install_npm
        sleep 10  # Längere Pause, damit NPM vollständig starten kann
        install_n8n
        install_freescout
        install_mattermost
        install_ghost
        install_nextcloud
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}Unbekannte Option: $1${NC}"
        show_help
        exit 1
        ;;
esac

echo -e "${GREEN}Installation abgeschlossen!${NC}"
