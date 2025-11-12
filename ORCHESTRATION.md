# Music Projects - Orchestration Guide

This document explains how to manage and orchestrate multiple music-related applications in this repository using a smart profile-based system.

## Overview

The `music-projects` repository uses a **centralized API architecture** where the **Sheet-API backend** acts as the core API consumed by all frontend applications.

### Architecture

```
┌─────────────────────────────────────────────┐
│         Sheet-API Backend (Port 8000)       │
│         + PostgreSQL Database               │
│         [CORE API - Shared by all apps]     │
└──────────────┬──────────────┬───────────────┘
               │              │
               │              │
       ┌───────▼──────┐  ┌───▼────────────────┐
       │ Jam Frontend │  │ Music Learning     │
       │ (Port 3001)  │  │ Frontend           │
       │              │  │ (Port 3002)        │
       └──────────────┘  └────────────────────┘
```

**Key Point:** All frontends consume the **same** Sheet-API backend. There are no standalone backends for jam-de-vientos or music-learning-app.

## Applications

| Application | Port | Type | Description |
|-------------|------|------|-------------|
| **sheet-api** (frontend) | 3000 | React Admin | Sheet music management dashboard |
| **sheet-api** (backend) | 8000 | Django API | Core API consumed by all apps |
| **jam-de-vientos** | 3001 | Next.js | Music collaboration platform |
| **music-learning-app** | 3002 | React | Duolingo-style music learning |

## Smart Orchestration with Profiles

The orchestration system uses **profiles** to intelligently start only the services you need based on which application you're working on.

### Available Profiles

| Profile | What It Starts | Use Case |
|---------|----------------|----------|
| `jam` | Sheet-API backend + Jam frontend | Working on Jam de Vientos |
| `music-learning` | Sheet-API backend + Music Learning frontend | Working on Music Learning |
| `api` | Sheet-API backend + frontend + DB | Working on Sheet-API admin dashboard |
| `core` | Sheet-API backend + DB only | Backend-only development |
| `all` | All services | Full-stack development |

## Usage

### Start Services

```bash
./scripts/start.sh [profile]
```

**Examples:**

```bash
# Working on Jam de Vientos
./scripts/start.sh jam

# Working on Music Learning App
./scripts/start.sh music-learning

# Working on Sheet-API admin dashboard
./scripts/start.sh api

# Backend API development only
./scripts/start.sh core

# Start everything
./scripts/start.sh all
```

### Stop Services

```bash
./scripts/stop.sh [profile] [options]
```

**Examples:**

```bash
# Stop jam-de-vientos (keeps backend running)
./scripts/stop.sh jam

# Stop music-learning (keeps backend running)
./scripts/stop.sh music-learning

# Stop everything
./scripts/stop.sh all

# Stop everything and clear databases
./scripts/stop.sh all -v
```

**Important:** When you stop a frontend-only profile (`jam` or `music-learning`), the Sheet-API backend keeps running because it's shared. Use `./scripts/stop.sh core` to stop the backend, or `./scripts/stop.sh all` to stop everything.

### View Logs

```bash
./scripts/logs.sh [service-name] [options]
```

**Available Services:**
- `sheet-api` - Sheet Music API
- `jam` - Jam de Vientos
- `music-learning` - Music Learning App
- `all` - Aggregated logs from all services

**Options:**
- `-f` or `--follow`: Follow log output in real-time
- `-n N` or `--lines N`: Show last N lines (default: 100)
- `--no-color`: Disable colored output

**Examples:**

```bash
# View Sheet-API logs
./scripts/logs.sh sheet-api

# Follow Jam de Vientos logs in real-time
./scripts/logs.sh jam -f

# View last 50 lines of Music Learning logs
./scripts/logs.sh music-learning --lines 50

# View all service logs (aggregated)
./scripts/logs.sh all -f
```

## Common Workflows

### Scenario 1: Working on Jam de Vientos

You only need the Jam frontend and the Sheet-API backend:

```bash
# Start jam stack
./scripts/start.sh jam

# View logs
./scripts/logs.sh jam -f

# When done, stop jam (backend keeps running)
./scripts/stop.sh jam

# Or stop everything including backend
./scripts/stop.sh all
```

**URLs:**
- Jam de Vientos: http://localhost:3001
- API Backend: http://localhost:8000

### Scenario 2: Working on Music Learning App

You only need the Music Learning frontend and the Sheet-API backend:

```bash
# Start music-learning stack
./scripts/start.sh music-learning

# View logs
./scripts/logs.sh music-learning -f

# When done
./scripts/stop.sh music-learning
```

**URLs:**
- Music Learning: http://localhost:3002
- API Backend: http://localhost:8000

### Scenario 3: Working on Sheet-API

You need the full Sheet-API (backend + admin frontend):

```bash
# Start full API stack
./scripts/start.sh api

# View logs
./scripts/logs.sh sheet-api -f

# When done
./scripts/stop.sh api
```

**URLs:**
- Sheet-API Admin: http://localhost:3000
- API Backend: http://localhost:8000

### Scenario 4: Backend-Only Development

You only want the API backend without any frontends:

```bash
# Start only backend + database
./scripts/start.sh core

# View backend logs
./scripts/logs.sh sheet-api -f

# When done
./scripts/stop.sh core
```

**URLs:**
- API Backend: http://localhost:8000

### Scenario 5: Full-Stack Development

Working on multiple applications simultaneously:

```bash
# Start all services
./scripts/start.sh all

# View aggregated logs
./scripts/logs.sh all -f

# When done
./scripts/stop.sh all
```

**URLs:**
- Sheet-API Admin: http://localhost:3000
- API Backend: http://localhost:8000
- Jam de Vientos: http://localhost:3001
- Music Learning: http://localhost:3002

### Scenario 6: Fresh Database Reset

Reset databases for clean testing:

```bash
# Stop all services and remove volumes (clears databases)
./scripts/stop.sh all -v

# Start services fresh
./scripts/start.sh jam  # or any profile
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

## Understanding Service Dependencies

### What Happens When You Start Each Profile

**`./scripts/start.sh jam`**
1. Starts `sheet-api/backend` + `sheet-api/db`
2. Starts `jam-de-vientos/frontend`
3. Jam frontend connects to sheet-api backend via Docker network

**`./scripts/start.sh music-learning`**
1. Starts `sheet-api/backend` + `sheet-api/db` (if not running)
2. Starts `music-learning-app/frontend`
3. Music Learning frontend connects to sheet-api backend

**`./scripts/start.sh api`**
1. Starts `sheet-api/backend` + `sheet-api/db`
2. Starts `sheet-api/frontend`
3. Frontend is the admin dashboard for managing the API

**`./scripts/start.sh core`**
1. Starts `sheet-api/backend` + `sheet-api/db` only
2. No frontends started
3. Backend API available at http://localhost:8000

**`./scripts/start.sh all`**
1. Starts `sheet-api/backend` + `sheet-api/db` + `sheet-api/frontend`
2. Starts `jam-de-vientos/frontend`
3. Starts `music-learning-app/frontend`

### Docker Compose Services

**sheet-api/docker-compose.yml:**
- `backend` - Django API server (port 8000)
- `db` - PostgreSQL database (internal)
- `frontend` - React admin dashboard (port 3000)

**jam-de-vientos/docker-compose.yml:**
- `frontend` - Next.js application (port 3001)

**music-learning-app/docker-compose.yml:**
- `frontend` - React application (port 3002)
- ~~`backend`~~ - Not used (consumes sheet-api instead)
- ~~`db`~~ - Not used (consumes sheet-api instead)

## Inter-Service Communication

### Jam de Vientos → Sheet-API

Jam de Vientos connects to Sheet-API backend using an external Docker network:

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

The `backend` hostname resolves to the sheet-api backend container via Docker DNS.

### Music Learning → Sheet-API

Music Learning connects to Sheet-API backend similarly:

**Environment Variable:**
```bash
REACT_APP_API_URL=http://localhost:8000
```

## Troubleshooting

### Issue: "network sheetmusic_sheetmusic-network not found"

**Cause:** Jam de Vientos requires the Sheet-API Docker network to exist.

**Solution:** Start Sheet-API first, or use the orchestration scripts which handle this automatically:

```bash
./scripts/start.sh jam  # Automatically starts sheet-api backend first
```

### Issue: Port Already in Use

**Solution 1:** Stop conflicting services
```bash
# Check what's using the port
sudo lsof -i :3001

# Stop services
./scripts/stop.sh all
```

**Solution 2:** Change port in docker-compose.yml
```yaml
ports:
  - "3010:3000"  # Map to different host port
```

### Issue: Frontend Can't Connect to Backend

**Symptoms:** API requests failing, CORS errors

**Solutions:**

1. **Verify backend is running:**
   ```bash
   docker ps | grep sheet-api
   ```

2. **Check backend logs:**
   ```bash
   ./scripts/logs.sh sheet-api -f
   ```

3. **Verify CORS configuration** in sheet-api backend:
   ```python
   CORS_ALLOWED_ORIGINS = [
       "http://localhost:3001",  # jam-de-vientos
       "http://localhost:3002",  # music-learning
   ]
   ```

### Issue: Database Connection Errors

**Solution:** Ensure database is ready before backend starts

Add health check to docker-compose.yml:
```yaml
depends_on:
  db:
    condition: service_healthy
```

Or wait a few seconds after starting services.

### Issue: Volumes Not Cleared

**Solution:** Use the `-v` flag

```bash
# Stop and remove volumes
./scripts/stop.sh all -v

# Or for individual services
cd sheet-api
docker compose down -v
```

## Best Practices

### 1. Use Profiles for Focused Development
```bash
# Good: Start only what you need
./scripts/start.sh jam

# Avoid: Starting everything when working on one app
./scripts/start.sh all  # Only when necessary
```

### 2. Check Logs Regularly
```bash
# Follow logs to catch errors early
./scripts/logs.sh jam -f
```

### 3. Stop Services When Not Needed
```bash
# Stop to free resources
./scripts/stop.sh jam

# Or stop everything
./scripts/stop.sh all
```

### 4. Clean Volumes Periodically
```bash
# Remove old volumes to free disk space
./scripts/stop.sh all -v
```

### 5. Use Core Profile for API Testing
```bash
# Backend-only for API development/testing
./scripts/start.sh core
curl http://localhost:8000/api/v1/themes/
```

## API Endpoints

The Sheet-API backend provides REST endpoints consumed by all frontends:

**Base URL:** http://localhost:8000/api/v1/

**Main Endpoints:**
- `/themes/` - Musical themes/pieces
- `/versions/` - Arrangements of themes
- `/instruments/` - Instrument definitions
- `/sheet-music/` - Sheet music files
- `/events/` - Musical events
- `/repertoires/` - Event repertoires

**Documentation:**
- Swagger UI: http://localhost:8000/swagger/
- ReDoc: http://localhost:8000/redoc/

## Future Enhancements

### Potential Improvements

- **Environment Templates:** Create `.env.example` files for easier setup
- **Health Checks:** Add health check endpoints to all services
- **Auto-reload:** Implement file watching for automatic container restart
- **Production Configs:** Add production docker-compose files
- **Monitoring:** Integrate Prometheus + Grafana for metrics
- **Backup Scripts:** Automated database backup and restore

### Migration to Kubernetes (Optional)

For production deployments at scale:
- Helm charts for each application
- Ingress controller for routing
- Persistent volume claims for databases
- Horizontal pod autoscaling
- Service mesh (Istio/Linkerd)

## Resources

### Documentation

- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Docker Networking](https://docs.docker.com/network/)
- Individual application CLAUDE.md files for specific guidance

### Project-Specific Docs

- `/sheet-api/CLAUDE.md` - Sheet Music API documentation
- `/jam-de-vientos/CLAUDE.md` - Jam de Vientos documentation
- `/music-learning-app/CLAUDE.md` - Music Learning App documentation

---

**Last Updated:** 2025-11-12

**Architecture:** Centralized API with multiple frontend clients

**Maintained By:** Portfolio Projects Team
