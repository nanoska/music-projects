# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This directory contains a collection of music-related web applications, each with distinct purposes and technology stacks. All projects are full-stack applications with separate frontend and backend implementations.

## Project Directory Structure

```
music-projects/
├── empiv/                          # Music school management platforms
│   ├── empiv-django-templates/     # Django templates version
│   └── empiv-web/                  # React + Django REST API version
├── jam-de-vientos/                 # Music collaboration platform (Next.js)
├── music-learning-app/             # Duolingo-style music learning (React + Django)
└── sheet-api/                      # Sheet music management system (React + Django)
```

## Individual Project Descriptions

### EMPIV (empiv/)

Two versions of a music school management platform:

**empiv-django-templates**: Traditional Django application with server-rendered templates
- **Tech Stack**: Django 5.1, Bootstrap 5, jQuery
- **Database**: SQLite (dev), PostgreSQL (prod)
- **Features**: User management, students, teachers, events, payments, music library

**empiv-web**: Modern separated frontend/backend architecture
- **Frontend**: React 19 + TypeScript + Tailwind CSS
- **Backend**: Django 5.1 + DRF
- **Features**: Same as templates version but with REST API

### Jam de Vientos (jam-de-vientos/)

Next.js music collaboration platform integrating with SheetMusic API for event and repertoire management.

- **Tech Stack**: Next.js 14 (App Router), TypeScript, Radix UI, Tailwind CSS v4
- **Features**: Public event carousel, admin dashboard, sheet music integration
- **Port**: 3001 (Docker), 3000 (local dev)
- **Integration**: External SheetMusic API via Docker network

### MusicLearn (music-learning-app/)

Gamified musical education platform similar to Duolingo for teaching music theory and practice.

- **Frontend**: React 18 + TypeScript + Material-UI + Vite
- **Backend**: Django 4.2 + DRF + PostgreSQL
- **Features**: Interactive exercises (note recognition, chords, rhythm), XP/badges, sheet music repository
- **Special Libraries**: VexFlow (notation), Howler.js (audio), music21 (music processing)

### SheetAPI (sheet-api/)

Sheet music management system for wind orchestras and bands with automatic transposition.

- **Frontend**: React 19 + TypeScript + Material-UI (dark theme)
- **Backend**: Django 4.2 + DRF
- **Features**: Theme/version management, instrument transposition, event/repertoire organization
- **Ports**: Frontend 3000, Backend 8000

## Orchestration and Multi-Service Management

For managing multiple applications together, see the detailed [ORCHESTRATION.md](./ORCHESTRATION.md) guide.

### Quick Start Commands

**Start all applications:**
```bash
./scripts/start-all.sh
```

**Start API stack only (Sheet-API + Jam de Vientos):**
```bash
./scripts/start-api-stack.sh
```

**Stop all applications:**
```bash
./scripts/stop-all.sh
```

**View logs:**
```bash
./scripts/logs.sh [service-name] -f
# Available services: sheet-api, jam-de-vientos, music-learning, empiv, all
```

### Service URLs (when all running)
- Sheet-API Frontend: http://localhost:3000
- Sheet-API Backend: http://localhost:8000
- Jam de Vientos: http://localhost:3001
- Music Learning (FE): http://localhost:3002
- Music Learning (BE): http://localhost:8001
- EMPIV Web (FE): http://localhost:3003
- EMPIV Web (BE): http://localhost:8002

## Common Development Commands

### React Projects (empiv-web, music-learning-app, sheet-api, jam-de-vientos)

```bash
# Navigate to project frontend directory
cd {project}/frontend

# Install dependencies
npm install

# Start development server
npm run dev    # or npm start (depending on project)

# Build for production
npm run build

# Linting and testing
npm run lint
npm test
```

### Next.js Projects (jam-de-vientos)

```bash
# Navigate to frontend
cd jam-de-vientos/frontend

# Development
npm run dev

# Production build
npm run build
npm start
```

### Django Backend Projects (All)

```bash
# Navigate to backend directory
cd {project}/backend

# Virtual environment (recommended)
python -m venv venv
source venv/bin/activate  # Linux/Mac
# venv\Scripts\activate   # Windows

# Install dependencies
pip install -r requirements.txt

# Database setup
python manage.py migrate
python manage.py createsuperuser

# Development server
python manage.py runserver

# Testing
python manage.py test              # Django test
pytest                             # pytest (if available)

# Migrations
python manage.py makemigrations
python manage.py migrate
```

### Docker Development

**IMPORTANT**: Always use `docker compose` (V2, with space) instead of `docker-compose` (V1, with hyphen).

```bash
# Clean rebuild (recommended after dependency changes or moving projects)
docker compose down -v && docker compose build --no-cache && docker compose up

# Standard operations
docker compose up --build          # Build and start
docker compose up -d               # Run in background
docker compose logs -f [service]   # View logs
docker compose down                # Stop services
docker compose down -v             # Stop and remove volumes (clears caches)

# Execute commands in containers
docker compose exec backend python manage.py migrate
docker compose exec backend python manage.py createsuperuser
docker compose exec backend python manage.py shell
```

**Docker Cache Issues**: If you encounter dependency errors after moving projects or updating packages, run:
```bash
docker compose down -v && docker compose build --no-cache && docker compose up
```
The `-v` flag removes volumes containing cached `node_modules` and dependencies.

## Technology Stack Summary

### Frontend Technologies

| Project | Framework | Language | UI Library | Styling | Build Tool |
|---------|-----------|----------|-----------|---------|------------|
| empiv-django-templates | Django Templates | Python | Bootstrap 5 | Bootstrap | Django |
| empiv-web | React 19 | TypeScript | Headless UI | Tailwind CSS | react-scripts |
| jam-de-vientos | Next.js 14 | TypeScript | Radix UI | Tailwind CSS v4 | Next.js |
| music-learning-app | React 18 | TypeScript | Material-UI | MUI | Vite |
| sheet-api | React 19 | TypeScript | Material-UI | MUI (dark) | react-scripts |

### Backend Technologies

| Project | Framework | Version | Database | API | Special Features |
|---------|-----------|---------|----------|-----|-----------------|
| empiv-django-templates | Django | 5.1 | SQLite/PostgreSQL | DRF | WhatsApp integration, S3 storage |
| empiv-web | Django | 5.1 | SQLite/PostgreSQL | DRF | Token auth, CORS, drf-spectacular |
| music-learning-app | Django | 4.2 | PostgreSQL | DRF | JWT, music21, librosa, Celery/Redis |
| sheet-api | Django | 4.2 | SQLite/PostgreSQL | DRF | JWT, auto-transposition, drf-yasg |

### State Management & HTTP Clients

- **empiv-web**: TanStack Query + Axios
- **jam-de-vientos**: React Context (AuthContext) + fetch API
- **music-learning-app**: Zustand + React Query
- **sheet-api**: React Context + Axios

## Development Workflow Patterns

### Frontend Structure (Typical)

```
src/
├── components/     # Reusable UI components
├── pages/          # Page-level components or views
├── services/       # API client integration
├── context/        # React contexts (auth, etc.)
├── hooks/          # Custom React hooks
├── types/          # TypeScript type definitions
└── utils/          # Utility functions
```

### Backend Structure (Django)

```
backend/
├── apps/                   # Django apps (music-learning-app)
│   ├── users/
│   ├── courses/
│   └── exercises/
├── {app_name}/            # Or flat structure (other projects)
│   ├── models.py
│   ├── views.py
│   ├── serializers.py
│   ├── urls.py
│   └── tests.py
├── core/                  # Project settings
├── manage.py
└── requirements.txt
```

### API Endpoints (Standard Pattern)

All projects use RESTful API endpoints under `/api/` or `/api/v1/`:

- Authentication: `/api/auth/login/`, `/api/auth/register/`
- Resources: `/api/{resource}/` (list, create)
- Detail: `/api/{resource}/{id}/` (retrieve, update, delete)
- Documentation: `/api/docs/` or `/swagger/` or `/redoc/`

## Common Development Tasks

### Database Management

```bash
# Reset database (development only)
rm db.sqlite3  # SQLite projects
python manage.py migrate

# Or with Django
python manage.py flush

# Create sample data (if script exists)
python manage.py create_sample_data
python create_sample_data.py
```

### Environment Variables

Each project requires `.env` files. Typical variables:

**Backend (.env)**:
```bash
SECRET_KEY=your-secret-key
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1
DATABASE_URL=sqlite:///db.sqlite3  # or PostgreSQL URL
CORS_ALLOWED_ORIGINS=http://localhost:3000
```

**Frontend (.env.local)**:
```bash
REACT_APP_API_URL=http://localhost:8000/api
# or for Next.js
NEXT_PUBLIC_API_URL=http://localhost:8000
```

### Static Files and Media

```bash
# Collect static files (production)
python manage.py collectstatic

# Media files are typically stored in backend/media/
```

## Testing Strategies

### Frontend Testing

- **React projects**: Jest + React Testing Library
- **Test commands**: `npm test` or `npm run test:coverage`

### Backend Testing

- **Django**: `python manage.py test`
- **pytest** (music-learning-app): `pytest` or `pytest --cov`

## Project-Specific Notes

### EMPIV Django Templates

- Uses server-rendered templates, not a REST API
- SSL development server: `python manage.py runsslserver`
- Multiple Django apps: users, students, teachers, staffs, events, academy, payments, music

### EMPIV Web (React + DRF)

- Completely separate frontend/backend with REST API
- Uses drf-spectacular for automatic API documentation
- Modern React with TanStack Query for server state

### Jam de Vientos

- **Active codebase**: `/frontend` directory only
- **Legacy code**: `/legacy` directory (not tracked in git, reference only)
- Connects to external SheetMusic API via Docker network
- Uses localStorage for dashboard-carousel communication
- Port 3001 in Docker to avoid conflicts

### MusicLearn

- Complex music processing with music21, librosa, mido
- Gamification system: XP, badges, streaks, leaderboards
- Multiple Django apps: users, exercises, courses, gamification, music_sheets
- Uses Celery for async tasks (check if Redis/Celery configured)

### SheetAPI

- Automatic transposition system via `music/utils.py:calculate_relative_tonality()`
- Smart file organization with theme-based naming
- Supports transposing instruments (Bb, Eb, F, C)
- Dark theme frontend with glassmorphism effects
- Single-page dashboard with tabbed interface

## Key Files Reference

### Configuration Files

- `package.json` - Node.js dependencies and scripts
- `requirements.txt` - Python dependencies
- `docker-compose.yml` - Multi-container orchestration
- `.env` / `.env.local` - Environment variables
- `tsconfig.json` - TypeScript configuration
- `tailwind.config.js` - Tailwind CSS configuration (where applicable)

### Django Critical Files

- `settings.py` - Django project configuration
- `urls.py` - URL routing
- `models.py` - Database models
- `views.py` - View logic and API endpoints
- `serializers.py` - DRF serializers
- `manage.py` - Django management commands

### React/Next.js Critical Files

- `App.tsx` / `layout.tsx` - Root component/layout
- `index.tsx` / `main.tsx` - Entry point
- `{service}/api.ts` - API client
- `{context}/auth-context.tsx` - Authentication

## Common Issues and Solutions

### Port Conflicts

Default ports used:
- **Frontend**: 3000 (3001 for jam-de-vientos Docker)
- **Backend**: 8000
- **PostgreSQL**: 5432
- **Redis**: 6379 (music-learning-app)

### CORS Issues

Ensure `CORS_ALLOWED_ORIGINS` includes frontend URL in backend `.env`:
```python
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000
```

### Docker Network Issues (Jam de Vientos)

Jam de Vientos requires external SheetMusic API network:
```bash
# Check if network exists
docker network ls | grep sheetmusic-network

# Create network if missing
docker network create sheetmusic_sheetmusic-network
```

### TypeScript Build Errors

Some projects have strict TypeScript settings:
- Fix all type errors before building
- Use proper TypeScript interfaces from `types/` directory

## Development Best Practices

- **Virtual environments**: Always use virtual environments for Python projects
- **Node modules**: Run `npm install` after pulling changes
- **Migrations**: Run migrations after pulling backend changes
- **Environment files**: Never commit `.env` files, use `.env.example` as template
- **Docker volumes**: Clear volumes with `-v` flag when dependencies change
- **API documentation**: Check `/api/docs/` or `/swagger/` for API endpoints

## Additional Resources

Each project has its own detailed `CLAUDE.md` file with specific architecture details, commands, and implementation notes. Refer to those files for project-specific guidance:

- `/empiv/empiv-django-templates/CLAUDE.md`
- `/empiv/empiv-web/CLAUDE.md`
- `/jam-de-vientos/CLAUDE.md`
- `/music-learning-app/CLAUDE.md`
- `/sheet-api/CLAUDE.md`
- Minimiza la creacion de codigo propio, maximiza el uso de librerias, componentes y modulos importables y el uso dle protocolo mcp siempre que se pueda.\
Para los desarrollos solicitados, hay que rear una rama en el repo correspondiente, desarrollar, documentar, mergear, pushear y eliminar la rama luego de terminar.\
Tambien hay que documentar la vision general de lo desarrollad e implementado en el repo 'root' que es el de nanoska/music-projects