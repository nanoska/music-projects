#!/bin/bash

# Music Projects - View Service Logs
# This script displays logs for music-related applications

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Base directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

# Function to show usage
show_usage() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Music Projects - View Logs${NC}"
    echo -e "${BLUE}========================================${NC}\n"

    echo -e "${YELLOW}Usage:${NC}"
    echo -e "  ./scripts/logs.sh [service-name] [options]\n"

    echo -e "${YELLOW}Available Services:${NC}"
    echo -e "  ${GREEN}sheet-api${NC}          - Sheet Music API (frontend + backend + db)"
    echo -e "  ${GREEN}jam-de-vientos${NC}     - Jam de Vientos frontend"
    echo -e "  ${GREEN}music-learning${NC}     - Music Learning App (frontend + backend + db)"
    echo -e "  ${GREEN}empiv${NC}              - EMPIV Web (frontend + backend + db)"
    echo -e "  ${GREEN}all${NC}                - All services (aggregated logs)\n"

    echo -e "${YELLOW}Options:${NC}"
    echo -e "  -f, --follow        Follow log output (tail -f)"
    echo -e "  -n, --lines N       Show last N lines (default: 100)"
    echo -e "  --no-color          Disable colored output\n"

    echo -e "${YELLOW}Examples:${NC}"
    echo -e "  ./scripts/logs.sh sheet-api -f"
    echo -e "  ./scripts/logs.sh jam-de-vientos --lines 50"
    echo -e "  ./scripts/logs.sh all -f\n"
}

# Parse arguments
SERVICE_NAME=""
FOLLOW=""
LINES="100"
NO_COLOR=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--follow)
            FOLLOW="-f"
            shift
            ;;
        -n|--lines)
            LINES="$2"
            shift 2
            ;;
        --no-color)
            NO_COLOR="--no-color"
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            SERVICE_NAME="$1"
            shift
            ;;
    esac
done

# Map service names to directories
get_service_dir() {
    case $1 in
        sheet-api)
            echo "$BASE_DIR/sheet-api"
            ;;
        jam-de-vientos)
            echo "$BASE_DIR/jam-de-vientos"
            ;;
        music-learning)
            echo "$BASE_DIR/music-learning-app"
            ;;
        empiv)
            echo "$BASE_DIR/empiv/empiv-web"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Show logs for a specific service
show_service_logs() {
    local SERVICE=$1
    local SERVICE_DIR=$(get_service_dir "$SERVICE")

    if [ -z "$SERVICE_DIR" ]; then
        echo -e "${RED}Error: Unknown service '$SERVICE'${NC}\n"
        show_usage
        exit 1
    fi

    if [ ! -d "$SERVICE_DIR" ]; then
        echo -e "${RED}Error: Service directory not found: $SERVICE_DIR${NC}"
        exit 1
    fi

    cd "$SERVICE_DIR"

    if [ ! -f "docker-compose.yml" ]; then
        echo -e "${RED}Error: docker-compose.yml not found in $SERVICE_DIR${NC}"
        exit 1
    fi

    echo -e "${BLUE}Showing logs for: ${GREEN}$SERVICE${NC}\n"

    # Build docker compose logs command
    CMD="docker compose logs --tail=$LINES $FOLLOW $NO_COLOR"

    eval $CMD
}

# Show logs for all services
show_all_logs() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}  Showing Logs for All Services${NC}"
    echo -e "${BLUE}========================================${NC}\n"

    # Get all running containers from music-projects
    CONTAINERS=$(docker ps --filter "name=sheet-api|jam-de-vientos|music-learning|empiv" --format "{{.Names}}")

    if [ -z "$CONTAINERS" ]; then
        echo -e "${YELLOW}No running containers found${NC}"
        exit 0
    fi

    echo -e "${GREEN}Running containers:${NC}"
    echo "$CONTAINERS" | while read container; do
        echo -e "  - $container"
    done
    echo ""

    # Build docker logs command for all containers
    if [ -n "$FOLLOW" ]; then
        echo -e "${YELLOW}Following logs (Ctrl+C to exit)...${NC}\n"
        docker logs $FOLLOW $(echo $CONTAINERS | tr '\n' ' ') 2>&1 | tail -n $LINES
    else
        echo $CONTAINERS | xargs -I {} sh -c "echo -e '${BLUE}=== {} ===${NC}' && docker logs --tail=$LINES {} 2>&1"
    fi
}

# Main logic
if [ -z "$SERVICE_NAME" ]; then
    show_usage
    exit 1
fi

case $SERVICE_NAME in
    all)
        show_all_logs
        ;;
    *)
        show_service_logs "$SERVICE_NAME"
        ;;
esac
