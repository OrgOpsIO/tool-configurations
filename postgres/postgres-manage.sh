#!/bin/bash

# ---------------------------------------------
# PostgreSQL Instanzen Management Script
# ---------------------------------------------

# Farben für die Ausgabe
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Basis-Verzeichnis für alle Instanzen
INSTANCES_DIR=~/postgres-instances

# Funktion zum Anzeigen der Hilfe
show_help() {
    echo -e "${GREEN}PostgreSQL Instanzen Management${NC}"
    echo -e "Verwendung: $0 <command> [instance-name]"
    echo -e ""
    echo -e "Befehle:"
    echo -e "  list                     - Zeigt alle Instanzen an"
    echo -e "  info <name>             - Zeigt Details einer Instanz"
    echo -e "  start <name>            - Startet eine Instanz"
    echo -e "  stop <name>             - Stoppt eine Instanz"
    echo -e "  restart <name>          - Startet eine Instanz neu"
    echo -e "  logs <name>             - Zeigt Logs einer Instanz"
    echo -e "  status <name>           - Zeigt Status einer Instanz"
    echo -e "  backup <name> [file]    - Erstellt Backup einer Instanz"
    echo -e "  restore <name> <file>   - Stellt Backup wieder her"
    echo -e "  delete <name>           - Löscht eine Instanz (mit Bestätigung)"
    echo -e "  help                    - Zeigt diese Hilfe"
    echo -e ""
    echo -e "Beispiele:"
    echo -e "  $0 list"
    echo -e "  $0 info kunde-a"
    echo -e "  $0 start kunde-a"
    echo -e "  $0 backup kunde-a"
    echo -e "  $0 backup kunde-a /path/to/backup.sql"
}

# Prüfen ob Instanzen-Verzeichnis existiert
check_instances_dir() {
    if [ ! -d "$INSTANCES_DIR" ]; then
        echo -e "${RED}Fehler: Keine Instanzen gefunden in $INSTANCES_DIR${NC}"
        echo -e "${YELLOW}Erstellen Sie zuerst eine Instanz mit dem Installations-Script.${NC}"
        exit 1
    fi
}

# Prüfen ob Instanz existiert
check_instance_exists() {
    local instance_name=$1
    if [ ! -d "$INSTANCES_DIR/$instance_name" ]; then
        echo -e "${RED}Fehler: Instanz '$instance_name' existiert nicht.${NC}"
        echo -e "${YELLOW}Verfügbare Instanzen:${NC}"
        list_instances
        exit 1
    fi
}

# Liste aller Instanzen anzeigen
list_instances() {
    check_instances_dir
    
    echo -e "${GREEN}PostgreSQL Instanzen:${NC}"
    echo ""
    
    local count=0
    for dir in "$INSTANCES_DIR"/*; do
        if [ -d "$dir" ] && [ -f "$dir/.env" ]; then
            local instance_name=$(basename "$dir")
            
            # .env laden
            source "$dir/.env"
            
            # Container Status prüfen
            local container_name="${INSTANCE_NAME}_postgres"
            local status=$(docker ps -a --filter "name=${container_name}" --format "{{.Status}}" 2>/dev/null)
            
            if [ -z "$status" ]; then
                status="${RED}Nicht gefunden${NC}"
            elif echo "$status" | grep -q "Up"; then
                status="${GREEN}Läuft${NC}"
            else
                status="${YELLOW}Gestoppt${NC}"
            fi
            
            # Typ-Farbe
            local type_display
            if [ "$INSTANCE_TYPE" == "public" ]; then
                type_display="${YELLOW}Öffentlich${NC}"
            else
                type_display="${GREEN}Privat${NC}"
            fi
            
            echo -e "  ${BLUE}●${NC} ${instance_name}"
            echo -e "    Status:  ${status}"
            echo -e "    Typ:     ${type_display}"
            echo -e "    Port:    ${POSTGRES_PORT}"
            echo -e "    Erstellt: ${CREATED_AT}"
            echo ""
            
            count=$((count + 1))
        fi
    done
    
    if [ $count -eq 0 ]; then
        echo -e "${YELLOW}Keine Instanzen gefunden.${NC}"
    else
        echo -e "${GREEN}Gesamt: $count Instanz(en)${NC}"
    fi
}

# Details einer Instanz anzeigen
show_instance_info() {
    local instance_name=$1
    check_instance_exists "$instance_name"
    
    local instance_dir="$INSTANCES_DIR/$instance_name"
    
    # .env laden
    source "$instance_dir/.env"
    
    # Container Status
    local container_name="${INSTANCE_NAME}_postgres"
    local status=$(docker ps -a --filter "name=${container_name}" --format "{{.Status}}" 2>/dev/null)
    
    if [ -z "$status" ]; then
        status="${RED}Container nicht gefunden${NC}"
    elif echo "$status" | grep -q "Up"; then
        status="${GREEN}Läuft${NC}"
    else
        status="${YELLOW}Gestoppt${NC}"
    fi
    
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  PostgreSQL Instanz: ${instance_name}${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}Status:${NC}        ${status}"
    echo -e "${BLUE}Typ:${NC}          ${INSTANCE_TYPE}"
    echo -e "${BLUE}Port:${NC}         ${POSTGRES_PORT}"
    echo -e "${BLUE}Datenbank:${NC}    ${POSTGRES_DB}"
    echo -e "${BLUE}App User:${NC}     ${POSTGRES_APP_USER}"
    echo -e "${BLUE}Erstellt:${NC}     ${CREATED_AT}"
    echo -e "${BLUE}Verzeichnis:${NC}  ${instance_dir}"
    echo ""
    
    # Zugangsdaten anzeigen
    echo -e "${BLUE}🔐 Zugangsdaten:${NC}"
    echo -e "   Admin Password:  ${POSTGRES_ADMIN_PASSWORD}"
    echo -e "   App Password:    ${POSTGRES_APP_PASSWORD}"
    echo ""
    
    # Verbindungsinformationen
    if [ "$INSTANCE_TYPE" == "public" ]; then
        echo -e "${BLUE}🔌 Verbindung (Öffentlich):${NC}"
        echo -e "   ${YELLOW}psql -h <server-ip> -p ${POSTGRES_PORT} -U ${POSTGRES_APP_USER} -d ${POSTGRES_DB}${NC}"
    else
        echo -e "${BLUE}🔌 Verbindung (SSH-Tunnel):${NC}"
        echo -e "   ${YELLOW}ssh -L ${POSTGRES_PORT}:localhost:${POSTGRES_PORT} user@server${NC}"
        echo -e "   ${YELLOW}psql -h localhost -p ${POSTGRES_PORT} -U ${POSTGRES_APP_USER} -d ${POSTGRES_DB}${NC}"
    fi
    echo ""
    
    # Docker Stats wenn Container läuft
    if echo "$status" | grep -q "Up"; then
        echo -e "${BLUE}📊 Ressourcen-Nutzung:${NC}"
        docker stats --no-stream --format "   CPU: {{.CPUPerc}}\t\tMemory: {{.MemUsage}}" "${container_name}" 2>/dev/null
        echo ""
    fi
    
    echo -e "${BLUE}📄 Details:${NC} ${instance_dir}/README.txt"
    echo ""
}

# Instanz starten
start_instance() {
    local instance_name=$1
    check_instance_exists "$instance_name"
    
    local instance_dir="$INSTANCES_DIR/$instance_name"
    
    echo -e "${YELLOW}Starte Instanz '${instance_name}'...${NC}"
    cd "$instance_dir"
    docker compose up -d
    
    echo -e "${GREEN}✓ Instanz '${instance_name}' gestartet${NC}"
}

# Instanz stoppen
stop_instance() {
    local instance_name=$1
    check_instance_exists "$instance_name"
    
    local instance_dir="$INSTANCES_DIR/$instance_name"
    
    echo -e "${YELLOW}Stoppe Instanz '${instance_name}'...${NC}"
    cd "$instance_dir"
    docker compose stop
    
    echo -e "${GREEN}✓ Instanz '${instance_name}' gestoppt${NC}"
}

# Instanz neustarten
restart_instance() {
    local instance_name=$1
    check_instance_exists "$instance_name"
    
    local instance_dir="$INSTANCES_DIR/$instance_name"
    
    echo -e "${YELLOW}Starte Instanz '${instance_name}' neu...${NC}"
    cd "$instance_dir"
    docker compose restart
    
    echo -e "${GREEN}✓ Instanz '${instance_name}' neugestartet${NC}"
}

# Logs anzeigen
show_logs() {
    local instance_name=$1
    check_instance_exists "$instance_name"
    
    local instance_dir="$INSTANCES_DIR/$instance_name"
    
    echo -e "${YELLOW}Zeige Logs für Instanz '${instance_name}' (Ctrl+C zum Beenden)...${NC}"
    cd "$instance_dir"
    docker compose logs -f
}

# Status anzeigen
show_status() {
    local instance_name=$1
    check_instance_exists "$instance_name"
    
    local instance_dir="$INSTANCES_DIR/$instance_name"
    
    cd "$instance_dir"
    docker compose ps
}

# Backup erstellen
backup_instance() {
    local instance_name=$1
    local backup_file=$2
    check_instance_exists "$instance_name"
    
    local instance_dir="$INSTANCES_DIR/$instance_name"
    
    # .env laden
    source "$instance_dir/.env"
    
    # Backup-Dateiname generieren wenn nicht angegeben
    if [ -z "$backup_file" ]; then
        backup_file="$instance_dir/backups/${instance_name}_$(date +%Y%m%d_%H%M%S).sql"
    fi
    
    # Verzeichnis erstellen falls nicht vorhanden
    mkdir -p "$(dirname "$backup_file")"
    
    echo -e "${YELLOW}Erstelle Backup von Instanz '${instance_name}'...${NC}"
    
    # Container Name
    local container_name="${INSTANCE_NAME}_postgres"
    
    # Backup erstellen
    docker exec "$container_name" pg_dump -U postgres "$POSTGRES_DB" > "$backup_file"
    
    if [ $? -eq 0 ]; then
        local size=$(du -h "$backup_file" | cut -f1)
        echo -e "${GREEN}✓ Backup erfolgreich erstellt${NC}"
        echo -e "${BLUE}Datei:${NC} ${backup_file}"
        echo -e "${BLUE}Größe:${NC} ${size}"
    else
        echo -e "${RED}✗ Backup fehlgeschlagen${NC}"
        exit 1
    fi
}

# Backup wiederherstellen
restore_instance() {
    local instance_name=$1
    local backup_file=$2
    
    if [ -z "$backup_file" ]; then
        echo -e "${RED}Fehler: Keine Backup-Datei angegeben${NC}"
        echo -e "${YELLOW}Verwendung: $0 restore <instance-name> <backup-file>${NC}"
        exit 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        echo -e "${RED}Fehler: Backup-Datei '$backup_file' existiert nicht${NC}"
        exit 1
    fi
    
    check_instance_exists "$instance_name"
    
    local instance_dir="$INSTANCES_DIR/$instance_name"
    
    # .env laden
    source "$instance_dir/.env"
    
    echo -e "${RED}⚠️  WARNUNG: Alle Daten in der Datenbank werden überschrieben!${NC}"
    echo -e "${YELLOW}Instanz: ${instance_name}${NC}"
    echo -e "${YELLOW}Datenbank: ${POSTGRES_DB}${NC}"
    echo -e "${YELLOW}Backup: ${backup_file}${NC}"
    echo ""
    read -p "Fortfahren? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        echo -e "${YELLOW}Abgebrochen.${NC}"
        exit 0
    fi
    
    echo -e "${YELLOW}Stelle Backup wieder her...${NC}"
    
    # Container Name
    local container_name="${INSTANCE_NAME}_postgres"
    
    # Backup wiederherstellen
    docker exec -i "$container_name" psql -U postgres "$POSTGRES_DB" < "$backup_file"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Backup erfolgreich wiederhergestellt${NC}"
    else
        echo -e "${RED}✗ Wiederherstellung fehlgeschlagen${NC}"
        exit 1
    fi
}

# Instanz löschen
delete_instance() {
    local instance_name=$1
    check_instance_exists "$instance_name"
    
    local instance_dir="$INSTANCES_DIR/$instance_name"
    
    echo -e "${RED}⚠️  WARNUNG: Dies wird die Instanz und ALLE Daten unwiderruflich löschen!${NC}"
    echo -e "${YELLOW}Instanz: ${instance_name}${NC}"
    echo -e "${YELLOW}Verzeichnis: ${instance_dir}${NC}"
    echo ""
    echo -e "${YELLOW}Geben Sie den Namen der Instanz zur Bestätigung ein:${NC}"
    read -p "> " confirm
    
    if [ "$confirm" != "$instance_name" ]; then
        echo -e "${YELLOW}Abgebrochen - Namen stimmen nicht überein.${NC}"
        exit 0
    fi
    
    echo -e "${YELLOW}Stoppe und entferne Container...${NC}"
    cd "$instance_dir"
    docker compose down -v
    
    echo -e "${YELLOW}Lösche Verzeichnis...${NC}"
    rm -rf "$instance_dir"
    
    echo -e "${GREEN}✓ Instanz '${instance_name}' wurde gelöscht${NC}"
}

# Hauptlogik
case "$1" in
    list)
        list_instances
        ;;
    info)
        if [ -z "$2" ]; then
            echo -e "${RED}Fehler: Instanz-Name erforderlich${NC}"
            echo -e "${YELLOW}Verwendung: $0 info <instance-name>${NC}"
            exit 1
        fi
        show_instance_info "$2"
        ;;
    start)
        if [ -z "$2" ]; then
            echo -e "${RED}Fehler: Instanz-Name erforderlich${NC}"
            echo -e "${YELLOW}Verwendung: $0 start <instance-name>${NC}"
            exit 1
        fi
        start_instance "$2"
        ;;
    stop)
        if [ -z "$2" ]; then
            echo -e "${RED}Fehler: Instanz-Name erforderlich${NC}"
            echo -e "${YELLOW}Verwendung: $0 stop <instance-name>${NC}"
            exit 1
        fi
        stop_instance "$2"
        ;;
    restart)
        if [ -z "$2" ]; then
            echo -e "${RED}Fehler: Instanz-Name erforderlich${NC}"
            echo -e "${YELLOW}Verwendung: $0 restart <instance-name>${NC}"
            exit 1
        fi
        restart_instance "$2"
        ;;
    logs)
        if [ -z "$2" ]; then
            echo -e "${RED}Fehler: Instanz-Name erforderlich${NC}"
            echo -e "${YELLOW}Verwendung: $0 logs <instance-name>${NC}"
            exit 1
        fi
        show_logs "$2"
        ;;
    status)
        if [ -z "$2" ]; then
            echo -e "${RED}Fehler: Instanz-Name erforderlich${NC}"
            echo -e "${YELLOW}Verwendung: $0 status <instance-name>${NC}"
            exit 1
        fi
        show_status "$2"
        ;;
    backup)
        if [ -z "$2" ]; then
            echo -e "${RED}Fehler: Instanz-Name erforderlich${NC}"
            echo -e "${YELLOW}Verwendung: $0 backup <instance-name> [backup-file]${NC}"
            exit 1
        fi
        backup_instance "$2" "$3"
        ;;
    restore)
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo -e "${RED}Fehler: Instanz-Name und Backup-Datei erforderlich${NC}"
            echo -e "${YELLOW}Verwendung: $0 restore <instance-name> <backup-file>${NC}"
            exit 1
        fi
        restore_instance "$2" "$3"
        ;;
    delete)
        if [ -z "$2" ]; then
            echo -e "${RED}Fehler: Instanz-Name erforderlich${NC}"
            echo -e "${YELLOW}Verwendung: $0 delete <instance-name>${NC}"
            exit 1
        fi
        delete_instance "$2"
        ;;
    help|--help|-h|"")
        show_help
        ;;
    *)
        echo -e "${RED}Unbekannter Befehl: $1${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac
