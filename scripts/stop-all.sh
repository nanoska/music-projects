#!/bin/bash

# Music Projects - Stop All Applications
# This script stops all running music-related applications

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
echo -e "${BLUE}  Music Projects - Stopping All Apps${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Function to stop a service
stop_service() {
    local SERVICE_NAME=$1
    local SERVICE_DIR=$2
    local REMOVE_VOLUMES=$3

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
        docker compose down -v
        echo -e "${GREEN}✓ $SERVICE_NAME stopped (volumes removed)${NC}\n"
    else
        docker compose down
        echo -e "${GREEN}✓ $SERVICE_NAME stopped${NC}\n"
    fi
}

# Check for volume removal flag
REMOVE_VOLUMES="false"
if [ "$1" = "-v" ] || [ "$1" = "--volumes" ]; then
    REMOVE_VOLUMES="true"
    echo -e "${YELLOW}Note: Will remove all volumes (databases will be cleared!)${NC}\n"
fi

# Stop services (reverse order of startup)
stop_service "EMPIV Web" "$BASE_DIR/empiv/empiv-web" "$REMOVE_VOLUMES"
stop_service "Music Learning App" "$BASE_DIR/music-learning-app" "$REMOVE_VOLUMES"
stop_service "Jam de Vientos" "$BASE_DIR/jam-de-vientos" "$REMOVE_VOLUMES"
stop_service "Sheet-API" "$BASE_DIR/sheet-api" "$REMOVE_VOLUMES"

# Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}All services stopped successfully!${NC}"
echo -e "${BLUE}========================================${NC}\n"

if [ "$REMOVE_VOLUMES" = "false" ]; then
    echo -e "${YELLOW}Tip: Use './scripts/stop-all.sh -v' to also remove volumes (databases)${NC}\n"
fi

# Return to base directory
cd "$BASE_DIR"
