# Music Projects - Orchestration Guide

This document explains how to manage and orchestrate multiple music-related applications in this repository.

## Overview

The `music-projects` repository contains several independent full-stack applications that can be run individually or together. Each application maintains its own Docker Compose configuration for maximum flexibility and isolation.

## Architecture

### Applications Included

| Application | Frontend Port | Backend Port | Database Port | Description |
|-------------|---------------|--------------|---------------|-------------|
| **sheet-api** | 3000 | 8000 | 5432 (internal) | Core Sheet Music API |
| **jam-de-vientos** | 3001 | Uses sheet-api:8000 | N/A | Music collaboration platform |
| **music-learning-app** | 3002 | 8001 | 5435 | Duolingo-style music learning |
| **empiv-web** | 3003 | 8002 | 5432 (conflicts resolved) | Music school management |

### Integration Points

- **jam-de-vientos** → **sheet-api**: Jam de Vientos consumes the Sheet-API backend via Docker network (`sheetmusic_sheetmusic-network`)
- Other applications are currently standalone but can be integrated using similar network patterns

## Orchestration Scripts

Located in the `/scripts` directory, these bash scripts provide convenient ways to manage all applications.

### Available Scripts

#### 1. Start All Applications

```bash
./scripts/start-all.sh
```

Starts all music applications in the correct order:
1. Sheet-API (core dependency)
2. Jam de Vientos
3. Music Learning App
4. EMPIV Web

**Output:**
- Colored status messages for each service
- URLs for all running services
- Success/failure indicators

**Post-startup URLs:**
- Sheet-API Frontend: http://localhost:3000
- Sheet-API Backend: http://localhost:8000
- Jam de Vientos: http://localhost:3001
- Music Learning (FE): http://localhost:3002
- Music Learning (BE): http://localhost:8001
- EMPIV Web (FE): http://localhost:3003
- EMPIV Web (BE): http://localhost:8002

#### 2. Stop All Applications

```bash
./scripts/stop-all.sh
```

Stops all running applications in reverse order.

**Options:**
- `-v` or `--volumes`: Also remove Docker volumes (clears databases)

```bash
# Stop services but keep databases
./scripts/stop-all.sh

# Stop services and clear all data
./scripts/stop-all.sh -v
```

#### 3. Start API Stack Only

```bash
./scripts/start-api-stack.sh
```

Starts only the API ecosystem:
- Sheet-API (frontend + backend + database)
- Jam de Vientos (frontend)

**Use Case:** When you only need to work on the Sheet-API and its consumer (Jam de Vientos) without running all applications.

#### 4. View Logs

```bash
./scripts/logs.sh [service-name] [options]
```

View logs for specific services or all services.

**Available Services:**
- `sheet-api` - Sheet Music API
- `jam-de-vientos` - Jam de Vientos
- `music-learning` - Music Learning App
- `empiv` - EMPIV Web
- `all` - Aggregated logs from all services

**Options:**
- `-f` or `--follow`: Follow log output in real-time
- `-n` or `--lines N`: Show last N lines (default: 100)
- `--no-color`: Disable colored output

**Examples:**
```bash
# View last 100 lines of Sheet-API logs
./scripts/logs.sh sheet-api

# Follow Jam de Vientos logs in real-time
./scripts/logs.sh jam-de-vientos -f

# View last 50 lines of Music Learning logs
./scripts/logs.sh music-learning --lines 50

# View all service logs (aggregated)
./scripts/logs.sh all -f
```

## Individual Service Management

Each application can still be managed independently using Docker Compose directly:

```bash
# Navigate to specific application directory
cd sheet-api

# Start service
docker compose up -d

# View logs
docker compose logs -f

# Stop service
docker compose down

# Stop service and remove volumes
docker compose down -v

# Rebuild and start
docker compose up --build
```

## Common Development Workflows

### Scenario 1: Full Stack Development

Working on multiple applications simultaneously:

```bash
# Start all services
./scripts/start-all.sh

# View aggregated logs
./scripts/logs.sh all -f

# When done, stop all services
./scripts/stop-all.sh
```

### Scenario 2: API Development

Working only on Sheet-API and Jam de Vientos:

```bash
# Start just the API stack
./scripts/start-api-stack.sh

# View Sheet-API logs
./scripts/logs.sh sheet-api -f

# View Jam de Vientos logs (in another terminal)
./scripts/logs.sh jam-de-vientos -f
```

### Scenario 3: Single Application Development

Working on one application in isolation:

```bash
# Navigate to app directory
cd music-learning-app

# Start service
docker compose up -d

# View logs
docker compose logs -f backend

# Rebuild after changes
docker compose up --build

# Stop when done
docker compose down
```

### Scenario 4: Fresh Database Reset

Reset databases for clean testing:

```bash
# Stop all services and remove volumes (clears databases)
./scripts/stop-all.sh -v

# Start all services fresh
./scripts/start-all.sh

# Each database will be re-initialized
```

## Port Conflict Resolution

If you encounter port conflicts, the applications use the following ports:

**Frontend Ports:**
- 3000: sheet-api
- 3001: jam-de-vientos
- 3002: music-learning-app
- 3003: empiv-web

**Backend Ports:**
- 8000: sheet-api
- 8001: music-learning-app
- 8002: empiv-web

**Database Ports:**
- 5432: sheet-api PostgreSQL (internal)
- 5435: music-learning-app PostgreSQL
- 5432: empiv-web PostgreSQL (conflicts with sheet-api if both DBs exposed)

**Note:** Some databases are not exposed to the host to avoid conflicts. Access them via `docker compose exec db psql` instead.

## Inter-Service Communication

### Current Integration: Jam de Vientos → Sheet-API

Jam de Vientos connects to Sheet-API's backend using a Docker network:

**In jam-de-vientos/docker-compose.yml:**
```yaml
networks:
  default:
    external: true
    name: sheetmusic_sheetmusic-network
```

**Environment Variable:**
```bash
NEXT_PUBLIC_SHEETMUSIC_API_URL=http://backend:8000
```

### Adding New Integrations

To connect other applications:

1. **Create or reuse a Docker network:**
   ```bash
   docker network create music-projects-network
   ```

2. **Add network to both docker-compose.yml files:**
   ```yaml
   networks:
     music-projects-network:
       external: true
   ```

3. **Reference services by container name:**
   ```bash
   API_URL=http://backend:8000
   ```

## Troubleshooting

### Issue: Port Already in Use

**Solution 1:** Stop the conflicting service
```bash
# Check what's using the port
sudo lsof -i :3000

# Stop the service
./scripts/stop-all.sh
```

**Solution 2:** Change the port in docker-compose.yml
```yaml
ports:
  - "3010:3000"  # Map to different host port
```

### Issue: Database Connection Errors

**Solution:** Ensure database is ready before backend starts

```yaml
depends_on:
  db:
    condition: service_healthy
```

Or wait a few seconds after starting services.

### Issue: Docker Network Not Found

**For jam-de-vientos error: "network sheetmusic_sheetmusic-network not found"**

```bash
# Start sheet-api first (creates the network)
cd sheet-api
docker compose up -d

# Then start jam-de-vientos
cd ../jam-de-vientos
docker compose up -d
```

Or use `start-api-stack.sh` which handles this automatically.

### Issue: Volumes Not Cleared

**Solution:** Use the `-v` flag

```bash
# Stop and remove volumes
./scripts/stop-all.sh -v

# Or for individual services
cd music-learning-app
docker compose down -v
```

## Best Practices

### 1. Use Scripts for Multi-Service Operations
```bash
# Good: Use orchestration scripts
./scripts/start-all.sh

# Avoid: Manually starting each service
cd sheet-api && docker compose up -d && cd ../jam-de-vientos && ...
```

### 2. Check Logs Regularly
```bash
# Follow logs to catch errors early
./scripts/logs.sh all -f
```

### 3. Stop Services When Not Needed
```bash
# Stop services to free resources
./scripts/stop-all.sh

# Or stop individual services
cd empiv/empiv-web && docker compose down
```

### 4. Clean Volumes Periodically
```bash
# Remove old volumes to free disk space
./scripts/stop-all.sh -v
```

### 5. Use API Stack for Frontend-Only Work
```bash
# Don't start all services if you only need the API
./scripts/start-api-stack.sh
```

## Future Enhancements

### Potential Improvements

- **Service Discovery:** Implement Traefik or nginx reverse proxy for automatic routing
- **Shared Database:** Consolidate databases to reduce resource usage (optional)
- **Environment Management:** Create `.env` templates for easier configuration
- **Health Checks:** Add health check endpoints to all services
- **Production Deployment:** Add production docker-compose configurations
- **Monitoring:** Integrate Prometheus + Grafana for metrics
- **Backup Scripts:** Automated database backup and restore

### Migration to Kubernetes (Optional)

For production deployments, consider migrating to Kubernetes:
- Helm charts for each application
- Ingress controller for routing
- Persistent volume claims for databases
- Horizontal pod autoscaling
- Service mesh (Istio/Linkerd) for advanced networking

## Resources

### Documentation

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Docker Networking](https://docs.docker.com/network/)
- Individual application CLAUDE.md files for specific guidance

### Project-Specific Docs

- `/sheet-api/CLAUDE.md` - Sheet Music API documentation
- `/jam-de-vientos/CLAUDE.md` - Jam de Vientos documentation
- `/music-learning-app/CLAUDE.md` - Music Learning App documentation
- `/empiv/empiv-web/CLAUDE.md` - EMPIV Web documentation

---

**Last Updated:** 2025-11-12

**Maintained By:** Portfolio Projects Team
