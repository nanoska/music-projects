#!/bin/bash

# Music Projects - Start API Stack (Sheet-API + Jam de Vientos)
# This script starts only the applications that form the API ecosystem

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Base directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Music Projects - API Stack Startup${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Function to start a service
start_service() {
    local SERVICE_NAME=$1
    local SERVICE_DIR=$2
    local PORT_INFO=$3

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
    docker compose up -d

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $SERVICE_NAME started successfully${NC}"
        echo -e "  ${PORT_INFO}\n"
    else
        echo -e "${RED}✗ Failed to start $SERVICE_NAME${NC}\n"
        return 1
    fi
}

# Start API ecosystem services
echo -e "${BLUE}Step 1: Starting Sheet-API (Core API)${NC}"
start_service "Sheet-API" "$BASE_DIR/sheet-api" "Frontend: http://localhost:3000 | Backend: http://localhost:8000"

echo -e "${BLUE}Step 2: Starting Jam de Vientos (API Consumer)${NC}"
start_service "Jam de Vientos" "$BASE_DIR/jam-de-vientos" "Frontend: http://localhost:3001"

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}API Stack started successfully!${NC}"
echo -e "${BLUE}========================================${NC}\n"

echo -e "${YELLOW}Active Services:${NC}"
echo -e "  Sheet-API Frontend:     ${GREEN}http://localhost:3000${NC}"
echo -e "  Sheet-API Backend:      ${GREEN}http://localhost:8000${NC}"
echo -e "  Jam de Vientos:         ${GREEN}http://localhost:3001${NC}\n"

echo -e "${YELLOW}Note:${NC}"
echo -e "  Jam de Vientos consumes the Sheet-API backend via Docker network.\n"

echo -e "${YELLOW}Useful commands:${NC}"
echo -e "  View logs:    ${BLUE}./scripts/logs.sh sheet-api${NC}"
echo -e "  View logs:    ${BLUE}./scripts/logs.sh jam-de-vientos${NC}"
echo -e "  Stop stack:   ${BLUE}./scripts/stop-all.sh${NC} (or stop individual services)\n"

# Return to base directory
cd "$BASE_DIR"
