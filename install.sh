#!/bin/bash

# ---------------------------------------------
# Hauptinstallationsskript für alle Services
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
    echo -e "Verwendung: $0 [npm|n8n|freescout|mattermost|ghost|nextcloud|minio|tiledesk|nocodb|keila|all]"
    echo -e ""
    echo -e "Optionen:"
    echo -e "  npm        - Installiert nur Nginx Proxy Manager"
    echo -e "  n8n        - Installiert nur n8n"
    echo -e "  freescout  - Installiert nur FreeScout"
    echo -e "  mattermost - Installiert nur Mattermost"
    echo -e "  ghost      - Installiert nur Ghost CMS"
    echo -e "  nextcloud  - Installiert nur Nextcloud"
    echo -e "  minio      - Installiert nur MinIO"
    echo -e "  tiledesk   - Installiert nur TileDesk"
    echo -e "  nocodb     - Installiert nur NocoDB"
    echo -e "  keila      - Installiert nur Keila Newsletter"
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

# Funktion zum Installieren von MinIO
install_minio() {
    echo -e "${GREEN}Starte MinIO-Installation...${NC}"
    bash "${SCRIPT_DIR}/minio/minio-install.sh"
}

# Funktion zum Installieren von TileDesk
install_tiledesk() {
    echo -e "${GREEN}Starte TileDesk-Installation...${NC}"
    bash "${SCRIPT_DIR}/tiledesk/tiledesk-install.sh"
}

# Funktion zum Installieren von NocoDB
install_nocodb() {
    echo -e "${GREEN}Starte NocoDB-Installation...${NC}"
    bash "${SCRIPT_DIR}/nocodb/nocodb-install.sh"
}

# Funktion zum Installieren von Keila
install_keila() {
    echo -e "${GREEN}Starte Keila-Installation...${NC}"
    bash "${SCRIPT_DIR}/keila/keila-install.sh"
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
    minio)
        install_minio
        ;;
    tiledesk)
        install_tiledesk
        ;;
    nocodb)
        install_nocodb
        ;;
    keila)
        install_keila
        ;;
    all)
        install_npm
        sleep 10
        install_n8n
        install_freescout
        install_mattermost
        install_ghost
        install_nextcloud
        install_minio
        install_tiledesk
        install_nocodb
        install_keila
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
