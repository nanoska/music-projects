#!/bin/bash

# Music Projects - Start All Applications
# This script starts all music-related applications in the correct order

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
echo -e "${BLUE}  Music Projects - Starting All Apps${NC}"
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

# Start services in order
echo -e "${BLUE}Step 1: Starting Sheet-API (Core API)${NC}"
start_service "Sheet-API" "$BASE_DIR/sheet-api" "Frontend: http://localhost:3000 | Backend: http://localhost:8000"

echo -e "${BLUE}Step 2: Starting Jam de Vientos${NC}"
start_service "Jam de Vientos" "$BASE_DIR/jam-de-vientos" "Frontend: http://localhost:3001"

echo -e "${BLUE}Step 3: Starting Music Learning App${NC}"
start_service "Music Learning App" "$BASE_DIR/music-learning-app" "Frontend: http://localhost:3002 | Backend: http://localhost:8001"

echo -e "${BLUE}Step 4: Starting EMPIV Web${NC}"
start_service "EMPIV Web" "$BASE_DIR/empiv/empiv-web" "Frontend: http://localhost:3003 | Backend: http://localhost:8002"

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}All services started successfully!${NC}"
echo -e "${BLUE}========================================${NC}\n"

echo -e "${YELLOW}Service URLs:${NC}"
echo -e "  Sheet-API Frontend:     ${GREEN}http://localhost:3000${NC}"
echo -e "  Sheet-API Backend:      ${GREEN}http://localhost:8000${NC}"
echo -e "  Jam de Vientos:         ${GREEN}http://localhost:3001${NC}"
echo -e "  Music Learning (FE):    ${GREEN}http://localhost:3002${NC}"
echo -e "  Music Learning (BE):    ${GREEN}http://localhost:8001${NC}"
echo -e "  EMPIV Web (FE):         ${GREEN}http://localhost:3003${NC}"
echo -e "  EMPIV Web (BE):         ${GREEN}http://localhost:8002${NC}\n"

echo -e "${YELLOW}Useful commands:${NC}"
echo -e "  View logs:    ${BLUE}./scripts/logs.sh [service-name]${NC}"
echo -e "  Stop all:     ${BLUE}./scripts/stop-all.sh${NC}"
echo -e "  API stack:    ${BLUE}./scripts/start-api-stack.sh${NC}\n"

# Return to base directory
cd "$BASE_DIR"
