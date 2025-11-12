#!/bin/bash

# Music Projects - Smart Orchestration Stop Script
# Stops services based on the stack/profile

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Base directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

# Function to show usage
show_usage() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Music Projects - Smart Stop${NC}"
    echo -e "${BLUE}========================================${NC}\n"

    echo -e "${YELLOW}Usage:${NC}"
    echo -e "  ./scripts/stop.sh [profile] [options]\n"

    echo -e "${YELLOW}Available Profiles:${NC}"
    echo -e "  ${GREEN}all${NC}              - Stop all running services"
    echo -e "  ${GREEN}jam${NC}              - Stop jam-de-vientos stack"
    echo -e "  ${GREEN}music-learning${NC}   - Stop music-learning stack"
    echo -e "  ${GREEN}api${NC}              - Stop sheet-api only"
    echo -e "  ${GREEN}core${NC}             - Stop sheet-api backend only\n"

    echo -e "${YELLOW}Options:${NC}"
    echo -e "  ${CYAN}-v, --volumes${NC}    - Also remove volumes (clears databases)\n"

    echo -e "${YELLOW}Examples:${NC}"
    echo -e "  ${CYAN}./scripts/stop.sh jam${NC}              # Stop jam-de-vientos"
    echo -e "  ${CYAN}./scripts/stop.sh all -v${NC}           # Stop everything and clear databases"
    echo -e "  ${CYAN}./scripts/stop.sh core${NC}             # Stop only backend\n"
}

# Function to stop a service component
stop_component() {
    local SERVICE_NAME=$1
    local SERVICE_DIR=$2
    local REMOVE_VOLUMES=$3
    local SERVICES=$4  # Specific docker-compose services to stop (optional)

    echo -e "${YELLOW}Stopping $SERVICE_NAME...${NC}"

    if [ ! -d "$SERVICE_DIR" ]; then
        echo -e "${RED}Warning: Directory $SERVICE_DIR not found, skipping${NC}\n"
        return 0
    fi

    cd "$SERVICE_DIR"

    if [ ! -f "docker-compose.yml" ]; then
        echo -e "${RED}Warning: docker-compose.yml not found in $SERVICE_DIR, skipping${NC}\n"
        return 0
    fi

    # Stop service
    if [ "$REMOVE_VOLUMES" = "true" ]; then
        if [ -n "$SERVICES" ]; then
            docker compose stop $SERVICES
            docker compose rm -f -v $SERVICES
        else
            docker compose down -v
        fi
        echo -e "${GREEN}✓ $SERVICE_NAME stopped (volumes removed)${NC}\n"
    else
        if [ -n "$SERVICES" ]; then
            docker compose stop $SERVICES
        else
            docker compose down
        fi
        echo -e "${GREEN}✓ $SERVICE_NAME stopped${NC}\n"
    fi
}

# Parse arguments
PROFILE=""
REMOVE_VOLUMES="false"

while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--volumes)
            REMOVE_VOLUMES="true"
            shift
            ;;
        -h|--help|help)
            show_usage
            exit 0
            ;;
        *)
            PROFILE="$1"
            shift
            ;;
    esac
done

if [ -z "$PROFILE" ]; then
    show_usage
    exit 1
fi

if [ "$REMOVE_VOLUMES" = "true" ]; then
    echo -e "${YELLOW}Note: Will remove volumes (databases will be cleared!)${NC}\n"
fi

# Stop based on profile
case "$PROFILE" in
    all)
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${CYAN}  Stopping All Services${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

        stop_component "Music Learning Frontend" "$BASE_DIR/music-learning-app" "$REMOVE_VOLUMES" "frontend"
        stop_component "Jam de Vientos" "$BASE_DIR/jam-de-vientos" "$REMOVE_VOLUMES"
        stop_component "Sheet-API" "$BASE_DIR/sheet-api" "$REMOVE_VOLUMES"
        ;;

    jam|jam-de-vientos)
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${CYAN}  Stopping Jam de Vientos Stack${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

        stop_component "Jam de Vientos" "$BASE_DIR/jam-de-vientos" "$REMOVE_VOLUMES"

        echo -e "${YELLOW}Note: Sheet-API backend is still running (shared by other apps)${NC}"
        echo -e "${YELLOW}Use './scripts/stop.sh core' to stop the backend${NC}\n"
        ;;

    music-learning|musiclearn)
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${CYAN}  Stopping Music Learning Stack${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

        stop_component "Music Learning Frontend" "$BASE_DIR/music-learning-app" "$REMOVE_VOLUMES" "frontend"

        echo -e "${YELLOW}Note: Sheet-API backend is still running (shared by other apps)${NC}"
        echo -e "${YELLOW}Use './scripts/stop.sh core' to stop the backend${NC}\n"
        ;;

    api)
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${CYAN}  Stopping Sheet-API (Full)${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

        stop_component "Sheet-API" "$BASE_DIR/sheet-api" "$REMOVE_VOLUMES"
        ;;

    core)
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${CYAN}  Stopping Sheet-API Backend${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

        stop_component "Sheet-API Backend + DB" "$BASE_DIR/sheet-api" "$REMOVE_VOLUMES" "backend db"

        echo -e "${YELLOW}Warning: This will affect jam-de-vientos and music-learning-app!${NC}\n"
        ;;

    *)
        echo -e "${RED}Error: Unknown profile '$PROFILE'${NC}\n"
        show_usage
        exit 1
        ;;
esac

echo -e "${GREEN}✓ Stop complete${NC}\n"

if [ "$REMOVE_VOLUMES" = "false" ]; then
    echo -e "${YELLOW}Tip: Use '-v' flag to also remove volumes (databases)${NC}"
    echo -e "  ${CYAN}./scripts/stop.sh $PROFILE -v${NC}\n"
fi

# Return to base directory
cd "$BASE_DIR"
