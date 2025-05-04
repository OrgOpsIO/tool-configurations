#!/bin/bash

# ---------------------------------------------
# Hauptinstallationsskript für Traefik und n8n
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
    echo -e "Verwendung: $0 [traefik|n8n|all]"
    echo -e ""
    echo -e "Optionen:"
    echo -e "  traefik   - Installiert nur Traefik in ~/traefik-compose"
    echo -e "  n8n       - Installiert nur n8n in ~/n8n-compose (erfordert vorherige Traefik-Installation)"
    echo -e "  all       - Installiert Traefik und n8n"
    echo -e "  help      - Zeigt diese Hilfe an"
}

# Funktion zum Installieren von Traefik
install_traefik() {
    echo -e "${GREEN}Starte Traefik-Installation...${NC}"
    bash "${SCRIPT_DIR}/traefik/traefik-install.sh"
}

# Funktion zum Installieren von n8n
install_n8n() {
    echo -e "${GREEN}Starte n8n-Installation...${NC}"
    bash "${SCRIPT_DIR}/n8n/n8n-install.sh"
}

# Hauptlogik
case "$1" in
    traefik)
        install_traefik
        ;;
    n8n)
        install_n8n
        ;;
    all)
        install_traefik
        sleep 5  # Kurze Pause, damit Traefik vollständig starten kann
        install_n8n
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
