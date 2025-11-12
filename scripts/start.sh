#!/bin/bash

# Music Projects - Smart Orchestration Start Script
# Starts only the necessary services based on the stack/profile

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
    echo -e "${BLUE}  Music Projects - Smart Start${NC}"
    echo -e "${BLUE}========================================${NC}\n"

    echo -e "${YELLOW}Usage:${NC}"
    echo -e "  ./scripts/start.sh [profile]\n"

    echo -e "${YELLOW}Available Profiles:${NC}"
    echo -e "  ${GREEN}all${NC}              - Start all applications (sheet-api + all frontends)"
    echo -e "  ${GREEN}jam${NC}              - Start jam-de-vientos stack (sheet-api backend + jam frontend)"
    echo -e "  ${GREEN}music-learning${NC}   - Start music-learning stack (sheet-api backend + music-learning frontend)"
    echo -e "  ${GREEN}api${NC}              - Start only sheet-api (backend + frontend + db)"
    echo -e "  ${GREEN}core${NC}             - Start only sheet-api backend + db (no frontends)\n"

    echo -e "${YELLOW}Examples:${NC}"
    echo -e "  ${CYAN}./scripts/start.sh jam${NC}              # Work on Jam de Vientos"
    echo -e "  ${CYAN}./scripts/start.sh music-learning${NC}   # Work on Music Learning"
    echo -e "  ${CYAN}./scripts/start.sh all${NC}              # Start everything"
    echo -e "  ${CYAN}./scripts/start.sh core${NC}             # Only backend API\n"

    echo -e "${YELLOW}Architecture:${NC}"
    echo -e "  ${CYAN}sheet-api backend (8000)${NC} is the ${GREEN}CORE API${NC} consumed by all frontends"
    echo -e "  - jam-de-vientos (3001) → sheet-api backend"
    echo -e "  - music-learning-app (3002) → sheet-api backend\n"
}

# Function to start a service component
start_component() {
    local SERVICE_NAME=$1
    local SERVICE_DIR=$2
    local SERVICES=$3  # Specific docker-compose services to start (optional)

    echo -e "${YELLOW}Starting $SERVICE_NAME...${NC}"

    if [ ! -d "$SERVICE_DIR" ]; then
        echo -e "${RED}Error: Directory $SERVICE_DIR not found${NC}"
        return 1
    fi

    cd "$SERVICE_DIR"

    if [ ! -f "docker-compose.yml" ]; then
        echo -e "${RED}Error: docker-compose.yml not found in $SERVICE_DIR${NC}"
        return 1
    fi

    # Start service in detached mode
    if [ -n "$SERVICES" ]; then
        docker compose up -d $SERVICES
    else
        docker compose up -d
    fi

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $SERVICE_NAME started successfully${NC}\n"
    else
        echo -e "${RED}✗ Failed to start $SERVICE_NAME${NC}\n"
        return 1
    fi
}

# Function to start sheet-api backend only
start_core() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  Starting CORE: Sheet-API Backend${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

    start_component "Sheet-API Backend + DB" "$BASE_DIR/sheet-api" "backend db"

    echo -e "${GREEN}✓ Core API ready at http://localhost:8000${NC}\n"
}

# Function to start full sheet-api
start_api() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  Starting Sheet-API (Full Stack)${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

    start_component "Sheet-API (Backend + Frontend + DB)" "$BASE_DIR/sheet-api"

    echo -e "${GREEN}✓ Sheet-API ready:${NC}"
    echo -e "  Frontend: ${CYAN}http://localhost:3000${NC}"
    echo -e "  Backend:  ${CYAN}http://localhost:8000${NC}\n"
}

# Function to start jam-de-vientos stack
start_jam() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  Starting Jam de Vientos Stack${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

    echo -e "${BLUE}[1/2] Starting Sheet-API backend (dependency)${NC}"
    start_component "Sheet-API Backend + DB" "$BASE_DIR/sheet-api" "backend db"

    echo -e "${BLUE}[2/2] Starting Jam de Vientos frontend${NC}"
    start_component "Jam de Vientos Frontend" "$BASE_DIR/jam-de-vientos"

    echo -e "${GREEN}✓ Jam de Vientos stack ready:${NC}"
    echo -e "  Jam Frontend: ${CYAN}http://localhost:3001${NC}"
    echo -e "  API Backend:  ${CYAN}http://localhost:8000${NC}\n"
}

# Function to start music-learning stack
start_music_learning() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  Starting Music Learning Stack${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

    echo -e "${BLUE}[1/2] Starting Sheet-API backend (dependency)${NC}"
    start_component "Sheet-API Backend + DB" "$BASE_DIR/sheet-api" "backend db"

    echo -e "${BLUE}[2/2] Starting Music Learning frontend${NC}"
    start_component "Music Learning Frontend" "$BASE_DIR/music-learning-app" "frontend"

    echo -e "${GREEN}✓ Music Learning stack ready:${NC}"
    echo -e "  Music Learning: ${CYAN}http://localhost:3002${NC}"
    echo -e "  API Backend:    ${CYAN}http://localhost:8000${NC}\n"
}

# Function to start all services
start_all() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  Starting All Applications${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

    echo -e "${BLUE}[1/3] Starting Sheet-API (core + frontend)${NC}"
    start_component "Sheet-API (Full)" "$BASE_DIR/sheet-api"

    echo -e "${BLUE}[2/3] Starting Jam de Vientos${NC}"
    start_component "Jam de Vientos" "$BASE_DIR/jam-de-vientos"

    echo -e "${BLUE}[3/3] Starting Music Learning App${NC}"
    start_component "Music Learning Frontend" "$BASE_DIR/music-learning-app" "frontend"

    echo -e "${GREEN}✓ All services ready:${NC}"
    echo -e "  Sheet-API (FE): ${CYAN}http://localhost:3000${NC}"
    echo -e "  Sheet-API (BE): ${CYAN}http://localhost:8000${NC}"
    echo -e "  Jam de Vientos: ${CYAN}http://localhost:3001${NC}"
    echo -e "  Music Learning: ${CYAN}http://localhost:3002${NC}\n"
}

# Main logic
PROFILE="${1:-}"

if [ -z "$PROFILE" ]; then
    show_usage
    exit 1
fi

case "$PROFILE" in
    core)
        start_core
        ;;
    api)
        start_api
        ;;
    jam|jam-de-vientos)
        start_jam
        ;;
    music-learning|musiclearn)
        start_music_learning
        ;;
    all)
        start_all
        ;;
    -h|--help|help)
        show_usage
        exit 0
        ;;
    *)
        echo -e "${RED}Error: Unknown profile '$PROFILE'${NC}\n"
        show_usage
        exit 1
        ;;
esac

# Useful tips
echo -e "${YELLOW}Useful commands:${NC}"
echo -e "  View logs:  ${BLUE}./scripts/logs.sh [service-name] -f${NC}"
echo -e "  Stop:       ${BLUE}./scripts/stop.sh $PROFILE${NC}"
echo -e "  Stop all:   ${BLUE}./scripts/stop.sh all${NC}\n"

# Return to base directory
cd "$BASE_DIR"
