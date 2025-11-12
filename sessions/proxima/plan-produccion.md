# Plan de Producción: Jam de Vientos + Sheet API

**Fecha**: 2025-11-02
**Objetivo**: Poner en producción jam-de-vientos con integración completa a sheet-api
**Estrategia**: Docker Compose en VPS, comunicación vía API REST, base de datos compartida gestionada por sheet-api

---

## 1. Análisis del Ecosistema Actual

### 1.1 Estructura del Directorio music-projects

```
music-projects/
├── empiv/
│   ├── empiv-django-templates/    # Gestión escuela música (Django templates)
│   └── empiv-web/                 # Gestión escuela música (React + DRF)
├── jam-de-vientos/                # Plataforma pública de eventos musicales
├── music-learning-app/            # App educativa tipo Duolingo
└── sheet-api/                     # Sistema gestión partituras (CORE)
```

### 1.2 Aplicaciones Clave para Producción

#### **Sheet-API** (Backend principal)
- **Propósito**: Sistema centralizado de gestión de partituras y eventos
- **Stack**: Django 4.2 + DRF + PostgreSQL
- **Puerto**: 8000 (backend), 3000 (frontend React admin)
- **Base de datos**: PostgreSQL (sheetmusic)
- **Características**:
  - Gestión completa de temas musicales (Theme)
  - Versiones y arreglos (Version)
  - Instrumentos con transposición automática
  - Partituras por instrumento (SheetMusic)
  - Eventos y repertorios (Event, Repertoire)
  - Sistema de ubicaciones (Location)
  - API REST completa con JWT
  - Endpoints públicos para jam-de-vientos (`JamDeVientosViewSet`)

#### **Jam de Vientos** (Frontend público)
- **Propósito**: Sitio web público para mostrar eventos y repertorios
- **Stack**: Next.js 14 (App Router) + TypeScript + Tailwind CSS v4
- **Puerto**: 3001 (Docker), 3000 (local dev)
- **Características**:
  - Carousel de eventos próximos
  - Vista detallada de repertorios por evento
  - Reproducción de audio
  - Dashboard admin (a preservar para futuro)
  - Integración completa con Sheet-API vía REST

---

## 2. Arquitectura Actual

### 2.1 Sheet-API: Modelos de Datos

```
Theme (Tema musical)
  ├── title, artist, image, audio
  ├── tonalidad (C, Dm, F#, etc.)
  └── has many → Version

Version (Arreglo/versión de un tema)
  ├── theme (FK)
  ├── type (STANDARD, ENSAMBLE, DUETO, etc.)
  ├── image, audio_file, mus_file
  ├── is_visible (para jam-de-vientos)
  └── has many → SheetMusic

SheetMusic (Partitura por instrumento)
  ├── version (FK)
  ├── instrument (FK)
  ├── type (MELODIA_PRINCIPAL, ARMONIA, etc.)
  ├── clef (SOL, FA)
  ├── tonalidad_relativa (calculada automáticamente)
  └── file (PDF)

Instrument
  ├── name, family
  └── afinacion (Bb, Eb, F, C, etc.)

Location (Lugares de eventos)
  ├── name, address, city, country
  ├── capacity, contact info
  └── is_active

Repertoire (Repertorio de un evento)
  ├── name, description
  └── versions (many-to-many con orden)

Event (Evento musical)
  ├── title, description
  ├── event_type (CONCERT, REHEARSAL, etc.)
  ├── status (DRAFT, CONFIRMED, CANCELLED, COMPLETED)
  ├── start_datetime, end_datetime
  ├── location (FK)
  ├── repertoire (FK)
  └── is_public (visible en jam-de-vientos)
```

### 2.2 Sheet-API: Endpoints Relevantes

**API Base**: `/api/v1/`

#### Endpoints Públicos (JamDeVientosViewSet)
```
GET  /api/v1/events/jamdevientos/                    # Lista eventos públicos
GET  /api/v1/events/jamdevientos/carousel/           # Próximos 10 eventos
GET  /api/v1/events/jamdevientos/upcoming/           # Eventos futuros con repertorio
GET  /api/v1/events/jamdevientos/{id}/               # Detalle de evento
GET  /api/v1/events/jamdevientos/{id}/repertoire/    # Repertorio completo de evento
```

#### Endpoints Protegidos (Requieren JWT)
```
# Themes
GET/POST     /api/v1/themes/
GET/PUT/DEL  /api/v1/themes/{id}/
GET          /api/v1/themes/{id}/versions/

# Versions
GET/POST     /api/v1/versions/
GET/PUT/DEL  /api/v1/versions/{id}/
PATCH        /api/v1/versions/{id}/  (para is_visible)
GET          /api/v1/versions/{id}/sheet_music/

# Events (admin)
GET/POST     /api/v1/events/
GET/PUT/DEL  /api/v1/events/{id}/

# Authentication
POST  /api/token/        # Obtener JWT token
POST  /api/token/refresh/ # Refresh token
```

### 2.3 Jam de Vientos: Estructura Actual

```
jam-de-vientos/
├── frontend/                      # CÓDIGO ACTIVO
│   ├── app/
│   │   ├── page.tsx              # Página pública (carousel + detalles)
│   │   ├── admin/
│   │   │   ├── login/page.tsx    # Login admin (local, a reemplazar con JWT)
│   │   │   └── dashboard/page.tsx # Dashboard admin (PRESERVAR)
│   │   └── layout.tsx
│   ├── components/
│   │   ├── song-carousel.tsx     # Carousel de eventos
│   │   ├── song-details.tsx      # Detalles de repertorio
│   │   ├── admin/
│   │   │   ├── sheetmusic-file-upload.tsx
│   │   │   └── protected-route.tsx
│   │   └── ui/                   # shadcn/ui components
│   ├── contexts/
│   │   └── auth-context.tsx      # Auth context (local, migrar a JWT)
│   ├── lib/
│   │   ├── auth.ts               # Auth service (local, migrar a JWT)
│   │   ├── sheetmusic-api.ts     # Cliente API Sheet-API ⭐
│   │   └── utils.ts
│   ├── package.json
│   ├── next.config.mjs
│   └── tailwind.config.ts
├── legacy/                        # Código antiguo (no usar)
├── docker-compose.yml
└── Dockerfile
```

### 2.4 Integración Actual: Jam de Vientos → Sheet-API

**Cliente API**: `frontend/lib/sheetmusic-api.ts`

```typescript
class SheetMusicAPI {
  baseURL = NEXT_PUBLIC_SHEETMUSIC_API_URL  // http://localhost:8000

  // Métodos GET (públicos)
  - getEventsCarousel()       → /jamdevientos/carousel/
  - getUpcomingEvents()       → /jamdevientos/upcoming/
  - getEventDetail(id)        → /jamdevientos/{id}/
  - getEventRepertoire(id)    → /jamdevientos/{id}/repertoire/

  // Métodos WRITE (requieren auth - TODOs pendientes)
  - updateVersionVisibility(versionId, isVisible)  // PATCH /versions/{id}/
  - updateVersion(versionId, updates)              // PATCH /versions/{id}/
  - uploadVersionFile(versionId, file, type)       // POST /versions/{id}/files/
  - deleteVersionFile(versionId, fileId)           // DELETE /versions/{id}/files/{id}/
}
```

**Estado de Autenticación**:
- ❌ Actualmente usa localStorage (admin local hardcoded)
- ⚠️ TODOs en el código para agregar headers JWT:
  ```typescript
  // TODO: Add authentication headers when auth is implemented
  // 'Authorization': `Bearer ${getAuthToken()}`
  ```

**Comunicación Docker**:
- Red compartida: `sheetmusic_sheetmusic-network`
- Jam de Vientos se conecta al backend de Sheet-API vía red interna
- Variables de entorno: `NEXT_PUBLIC_SHEETMUSIC_API_URL`

---

## 3. Decisiones de Arquitectura para Producción

### 3.1 Decisiones Tomadas

| Aspecto | Decisión | Justificación |
|---------|----------|---------------|
| **Gestión de Datos** | Sheet-API es única fuente de verdad | Centralización, consistencia |
| **Comunicación** | Solo vía API REST | Desacoplamiento, escalabilidad |
| **Base de Datos** | PostgreSQL compartida, gestionada solo por Sheet-API | Migraciones centralizadas |
| **Autenticación** | JWT compartido (preparado para futuro) | Single sign-on, reutilización |
| **Funcionalidad Jam** | Solo lectura por ahora | Simplicidad, implementar CRUD después |
| **Despliegue** | Docker Compose en VPS | Control total, costo-efectivo |
| **Dashboard Admin** | Preservar código para implementación futura | No perder trabajo realizado |

### 3.2 Flujo de Datos en Producción

```
[Usuarios Públicos]
       ↓
[Jam de Vientos Frontend (Next.js)]
       ↓ HTTP/API REST
[Sheet-API Backend (Django)]
       ↓ ORM
[PostgreSQL Database]
       ↑ ORM
[Sheet-API Admin Frontend (React)]
       ↑
[Administradores]
```

**Responsabilidades**:
- **Sheet-API Admin**: Crear/editar eventos, repertorios, temas, partituras
- **Jam de Vientos**: Visualizar eventos públicos, reproducir audio, ver partituras
- **PostgreSQL**: Almacenamiento centralizado
- **Sheet-API Backend**: Lógica de negocio, autorización, transposición automática

---

## 4. Plan de Implementación por Fases

### FASE 1: Preparación y Documentación

**Rama Git**: `feature/production-setup-documentation`

#### Tareas:
1. ✅ Crear `sessions/proxima/plan-produccion.md` (este documento)
2. ⬜ Crear `sessions/proxima/analisis-arquitectura.md` (diagrama detallado)
3. ⬜ Crear `sessions/proxima/api-integration-map.md` (mapeo completo de endpoints)
4. ⬜ Documentar en `music-projects/README.md` visión general del proyecto

**Entregables**:
- Documentación completa de arquitectura
- Mapeo de endpoints API
- README actualizado en repo root

---

### FASE 2: Preservación del Dashboard Admin

**Rama Git**: `feature/preserve-admin-dashboard`

#### Objetivo:
Mover el código del dashboard admin de jam-de-vientos a un directorio separado para implementación futura.

#### Tareas:
1. ⬜ Crear directorio `jam-de-vientos/admin-dashboard-future/`
2. ⬜ Copiar:
   - `app/admin/dashboard/page.tsx`
   - `components/admin/sheetmusic-file-upload.tsx`
   - `components/admin/protected-route.tsx`
3. ⬜ Crear `admin-dashboard-future/README.md` con:
   - Descripción de funcionalidades
   - Pasos para reactivación
   - Requisitos de JWT
   - Endpoints API necesarios
4. ⬜ Actualizar `.gitignore` si es necesario
5. ⬜ Documentar en `jam-de-vientos/CLAUDE.md`

**Notas**:
- NO eliminar del código activo todavía
- Solo crear backup estructurado
- Mantener rutas funcionales

---

### FASE 3: Configuración de Producción - Sheet-API

**Rama Git**: `feature/sheet-api-production-config`

#### 3.1 Variables de Entorno

Crear `sheet-api/.env.production.example`:
```bash
# Django
SECRET_KEY=your-secret-key-here
DEBUG=False
ALLOWED_HOSTS=api.tudominio.com,localhost
DJANGO_SETTINGS_MODULE=sheetmusic_api.settings

# Database
SQL_ENGINE=django.db.backends.postgresql
SQL_DATABASE=sheetmusic
SQL_USER=sheetmusic
SQL_PASSWORD=strong-password-here
SQL_HOST=db
SQL_PORT=5432

# CORS
CORS_ALLOWED_ORIGINS=https://jamdevientos.com,https://admin.jamdevientos.com

# JWT
JWT_SECRET_KEY=another-secret-key-here
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_LIFETIME=60  # minutos
JWT_REFRESH_TOKEN_LIFETIME=1440  # minutos (24h)

# Media/Static
MEDIA_URL=/media/
STATIC_URL=/static/
```

#### 3.2 Settings de Producción

Modificar `sheet-api/backend/sheetmusic_api/settings.py`:
```python
# Usar variables de entorno
SECRET_KEY = os.environ.get('SECRET_KEY')
DEBUG = os.environ.get('DEBUG', 'False') == 'True'
ALLOWED_HOSTS = os.environ.get('ALLOWED_HOSTS', '').split(',')

# CORS para jam-de-vientos
CORS_ALLOWED_ORIGINS = os.environ.get('CORS_ALLOWED_ORIGINS', '').split(',')

# Database de .env
DATABASES = {
    'default': {
        'ENGINE': os.environ.get('SQL_ENGINE'),
        'NAME': os.environ.get('SQL_DATABASE'),
        'USER': os.environ.get('SQL_USER'),
        'PASSWORD': os.environ.get('SQL_PASSWORD'),
        'HOST': os.environ.get('SQL_HOST'),
        'PORT': os.environ.get('SQL_PORT'),
    }
}

# Static/Media files
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')
```

#### 3.3 Dockerfile para Producción

Crear `sheet-api/backend/Dockerfile.prod`:
```dockerfile
FROM python:3.11-slim as builder

WORKDIR /app

# Dependencias del sistema
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Instalar dependencias Python
COPY requirements.txt .
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /app/wheels -r requirements.txt

# Etapa final
FROM python:3.11-slim

WORKDIR /app

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copiar wheels e instalar
COPY --from=builder /app/wheels /wheels
COPY --from=builder /app/requirements.txt .
RUN pip install --no-cache /wheels/*

# Copiar código
COPY . .

# Crear usuario no-root
RUN addgroup --system django && adduser --system --group django
RUN chown -R django:django /app
USER django

# Collectstatic en build
RUN python manage.py collectstatic --noinput || true

EXPOSE 8000

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "3", "sheetmusic_api.wsgi:application"]
```

#### 3.4 Nginx para Sheet-API Backend

Crear `sheet-api/backend/nginx.prod.conf`:
```nginx
server {
    listen 80;
    server_name api.tudominio.com;

    client_max_body_size 100M;

    location /static/ {
        alias /app/staticfiles/;
    }

    location /media/ {
        alias /app/media/;
    }

    location / {
        proxy_pass http://sheet-api-backend:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

**Tareas**:
1. ⬜ Crear `.env.production.example`
2. ⬜ Modificar settings.py para usar variables de entorno
3. ⬜ Crear Dockerfile.prod optimizado (multi-stage)
4. ⬜ Crear nginx.prod.conf
5. ⬜ Actualizar requirements.txt si es necesario
6. ⬜ Documentar en `sheet-api/production-setup.md`

---

### FASE 4: Configuración de Producción - Jam de Vientos

**Rama Git**: `feature/jam-vientos-production-config`

#### 4.1 Variables de Entorno

Crear `jam-de-vientos/.env.production.example`:
```bash
# API
NEXT_PUBLIC_SHEETMUSIC_API_URL=https://api.tudominio.com

# Build
NODE_ENV=production

# Optional
NEXT_PUBLIC_SITE_URL=https://jamdevientos.com
```

#### 4.2 Next.js Config Producción

Verificar/actualizar `jam-de-vientos/frontend/next.config.mjs`:
```javascript
/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',  // Para Docker
  images: {
    unoptimized: false,  // Habilitar optimización en producción
    domains: ['api.tudominio.com'],  // Permitir imágenes del API
  },
  // Opcional: configurar redirects, headers, etc.
}

export default nextConfig
```

#### 4.3 Dockerfile para Producción

Crear `jam-de-vientos/Dockerfile.prod`:
```dockerfile
# Etapa 1: Dependencias
FROM node:18-alpine AS deps
WORKDIR /app
COPY frontend/package*.json ./
RUN npm ci --only=production

# Etapa 2: Build
FROM node:18-alpine AS builder
WORKDIR /app
COPY frontend/package*.json ./
RUN npm ci
COPY frontend/ ./
RUN npm run build

# Etapa 3: Runner
FROM node:18-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production

RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001

# Copiar archivos necesarios
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT 3000

CMD ["node", "server.js"]
```

#### 4.4 Nginx para Jam de Vientos

Crear `jam-de-vientos/nginx.prod.conf`:
```nginx
server {
    listen 80;
    server_name jamdevientos.com www.jamdevientos.com;

    location / {
        proxy_pass http://jam-vientos-frontend:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

**Tareas**:
1. ⬜ Crear `.env.production.example`
2. ⬜ Actualizar next.config.mjs para producción
3. ⬜ Crear Dockerfile.prod con multi-stage build
4. ⬜ Crear nginx.prod.conf
5. ⬜ Optimizar package.json (remover devDependencies innecesarias)
6. ⬜ Documentar en `jam-de-vientos/production-setup.md`

---

### FASE 5: Docker Compose para Producción

**Rama Git**: `feature/docker-compose-production`

#### 5.1 Estructura de Docker Compose

Crear `music-projects/docker-compose.production.yml`:

```yaml
version: '3.8'

services:
  # Base de datos compartida
  db:
    image: postgres:15-alpine
    container_name: music-db
    restart: unless-stopped
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: ${SQL_DATABASE}
      POSTGRES_USER: ${SQL_USER}
      POSTGRES_PASSWORD: ${SQL_PASSWORD}
    networks:
      - music-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${SQL_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Sheet-API Backend (Django)
  sheet-api-backend:
    build:
      context: ./sheet-api/backend
      dockerfile: Dockerfile.prod
    container_name: sheet-api-backend
    restart: unless-stopped
    volumes:
      - sheet_api_static:/app/staticfiles
      - sheet_api_media:/app/media
    env_file:
      - ./sheet-api/.env.production
    depends_on:
      db:
        condition: service_healthy
    networks:
      - music-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/api/v1/"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Sheet-API Frontend (React Admin)
  sheet-api-frontend:
    build:
      context: ./sheet-api/frontend
      dockerfile: Dockerfile.prod
    container_name: sheet-api-frontend
    restart: unless-stopped
    volumes:
      - ./sheet-api/frontend/nginx.prod.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - sheet-api-backend
    networks:
      - music-network

  # Jam de Vientos Frontend (Next.js)
  jam-vientos-frontend:
    build:
      context: ./jam-de-vientos
      dockerfile: Dockerfile.prod
    container_name: jam-vientos-frontend
    restart: unless-stopped
    env_file:
      - ./jam-de-vientos/.env.production
    depends_on:
      - sheet-api-backend
    networks:
      - music-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Nginx Reverse Proxy Principal
  nginx-proxy:
    image: nginx:alpine
    container_name: nginx-proxy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/conf.d:/etc/nginx/conf.d:ro
      - sheet_api_static:/var/www/sheet-api/static:ro
      - sheet_api_media:/var/www/sheet-api/media:ro
      - certbot_certs:/etc/letsencrypt:ro
      - certbot_www:/var/www/certbot:ro
    depends_on:
      - sheet-api-backend
      - sheet-api-frontend
      - jam-vientos-frontend
    networks:
      - music-network

  # Certbot para SSL (Let's Encrypt)
  certbot:
    image: certbot/certbot
    container_name: certbot
    volumes:
      - certbot_certs:/etc/letsencrypt
      - certbot_www:/var/www/certbot
    entrypoint: "/bin/sh -c 'trap exit TERM; while :; do certbot renew; sleep 12h & wait $${!}; done;'"

volumes:
  postgres_data:
    driver: local
  sheet_api_static:
    driver: local
  sheet_api_media:
    driver: local
  certbot_certs:
    driver: local
  certbot_www:
    driver: local

networks:
  music-network:
    driver: bridge
    name: music-network
```

#### 5.2 Nginx Proxy Principal

Crear `music-projects/nginx/nginx.conf`:
```nginx
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 100M;

    # Gzip
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml text/javascript application/json application/javascript application/xml+rss application/rss+xml font/truetype font/opentype application/vnd.ms-fontobject image/svg+xml;

    # Incluir configuraciones de sitios
    include /etc/nginx/conf.d/*.conf;
}
```

Crear `music-projects/nginx/conf.d/sheet-api.conf`:
```nginx
# Sheet-API Backend
server {
    listen 80;
    server_name api.tudominio.com;

    # Redirigir a HTTPS
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name api.tudominio.com;

    ssl_certificate /etc/letsencrypt/live/api.tudominio.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.tudominio.com/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    client_max_body_size 100M;

    # Static files
    location /static/ {
        alias /var/www/sheet-api/static/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    # Media files
    location /media/ {
        alias /var/www/sheet-api/media/;
        expires 7d;
        add_header Cache-Control "public";
    }

    # API
    location / {
        proxy_pass http://sheet-api-backend:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # CORS headers (si es necesario)
        add_header Access-Control-Allow-Origin "https://jamdevientos.com" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, PATCH, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Authorization, Content-Type" always;
    }
}

# Sheet-API Admin Frontend
server {
    listen 80;
    server_name admin.tudominio.com;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name admin.tudominio.com;

    ssl_certificate /etc/letsencrypt/live/admin.tudominio.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/admin.tudominio.com/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://sheet-api-frontend:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Crear `music-projects/nginx/conf.d/jam-vientos.conf`:
```nginx
# Jam de Vientos
server {
    listen 80;
    server_name jamdevientos.com www.jamdevientos.com;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen 443 ssl http2;
    server_name jamdevientos.com www.jamdevientos.com;

    ssl_certificate /etc/letsencrypt/live/jamdevientos.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/jamdevientos.com/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://jam-vientos-frontend:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

**Tareas**:
1. ⬜ Crear `docker-compose.production.yml` en music-projects root
2. ⬜ Crear configuraciones nginx en `nginx/`
3. ⬜ Crear `.env.production.example` para el compose
4. ⬜ Documentar arquitectura de red y servicios
5. ⬜ Crear script `deploy.sh` para facilitar deployment

---

### FASE 6: Scripts de Deployment

**Rama Git**: `feature/deployment-scripts`

#### 6.1 Script de Deploy

Crear `music-projects/deploy.sh`:
```bash
#!/bin/bash

set -e

echo "🚀 Deploying Music Projects Stack..."

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Verificar que estamos en el directorio correcto
if [ ! -f "docker-compose.production.yml" ]; then
    echo "❌ Error: docker-compose.production.yml not found"
    exit 1
fi

# Verificar .env files
echo -e "${YELLOW}Verificando archivos .env...${NC}"
if [ ! -f "sheet-api/.env.production" ]; then
    echo "⚠️  sheet-api/.env.production no encontrado. Copiando desde example..."
    cp sheet-api/.env.production.example sheet-api/.env.production
    echo "⚠️  Por favor edita sheet-api/.env.production antes de continuar"
    exit 1
fi

if [ ! -f "jam-de-vientos/.env.production" ]; then
    echo "⚠️  jam-de-vientos/.env.production no encontrado. Copiando desde example..."
    cp jam-de-vientos/.env.production.example jam-de-vientos/.env.production
    echo "⚠️  Por favor edita jam-de-vientos/.env.production antes de continuar"
    exit 1
fi

# Pull latest code
echo -e "${GREEN}Pulling latest code...${NC}"
git pull origin main

# Build images
echo -e "${GREEN}Building Docker images...${NC}"
docker compose -f docker-compose.production.yml build --no-cache

# Stop old containers
echo -e "${GREEN}Stopping old containers...${NC}"
docker compose -f docker-compose.production.yml down

# Start new containers
echo -e "${GREEN}Starting new containers...${NC}"
docker compose -f docker-compose.production.yml up -d

# Wait for DB
echo -e "${GREEN}Waiting for database...${NC}"
sleep 10

# Run migrations
echo -e "${GREEN}Running migrations...${NC}"
docker compose -f docker-compose.production.yml exec -T sheet-api-backend python manage.py migrate

# Collect static
echo -e "${GREEN}Collecting static files...${NC}"
docker compose -f docker-compose.production.yml exec -T sheet-api-backend python manage.py collectstatic --noinput

# Show status
echo -e "${GREEN}Deployment complete! Current status:${NC}"
docker compose -f docker-compose.production.yml ps

echo -e "${GREEN}✅ Deployment successful!${NC}"
echo "🌐 Access your applications:"
echo "   - Jam de Vientos: https://jamdevientos.com"
echo "   - Sheet-API Backend: https://api.tudominio.com"
echo "   - Sheet-API Admin: https://admin.tudominio.com"
```

#### 6.2 Script de Backup

Crear `music-projects/backup.sh`:
```bash
#!/bin/bash

set -e

BACKUP_DIR="./backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

echo "📦 Creating backup: $TIMESTAMP"

# Crear directorio de backups
mkdir -p $BACKUP_DIR

# Backup de la base de datos
echo "Backing up database..."
docker compose -f docker-compose.production.yml exec -T db pg_dump -U $SQL_USER $SQL_DATABASE > "$BACKUP_DIR/db_backup_$TIMESTAMP.sql"

# Backup de media files
echo "Backing up media files..."
docker run --rm \
    -v music-projects_sheet_api_media:/source \
    -v $(pwd)/$BACKUP_DIR:/backup \
    alpine tar czf /backup/media_backup_$TIMESTAMP.tar.gz -C /source .

echo "✅ Backup complete: $BACKUP_DIR/"
echo "   - db_backup_$TIMESTAMP.sql"
echo "   - media_backup_$TIMESTAMP.tar.gz"

# Limpiar backups antiguos (mantener últimos 7 días)
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "🧹 Old backups cleaned"
```

#### 6.3 Script de Restore

Crear `music-projects/restore.sh`:
```bash
#!/bin/bash

set -e

if [ -z "$1" ]; then
    echo "Usage: ./restore.sh <backup_timestamp>"
    echo "Example: ./restore.sh 20251102_143022"
    exit 1
fi

TIMESTAMP=$1
BACKUP_DIR="./backups"

echo "🔄 Restoring from backup: $TIMESTAMP"

# Verificar que existan los archivos
if [ ! -f "$BACKUP_DIR/db_backup_$TIMESTAMP.sql" ]; then
    echo "❌ Database backup not found: $BACKUP_DIR/db_backup_$TIMESTAMP.sql"
    exit 1
fi

# Confirmación
read -p "⚠️  This will OVERWRITE current data. Continue? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "Restore cancelled"
    exit 0
fi

# Restore database
echo "Restoring database..."
docker compose -f docker-compose.production.yml exec -T db psql -U $SQL_USER -d $SQL_DATABASE < "$BACKUP_DIR/db_backup_$TIMESTAMP.sql"

# Restore media (si existe)
if [ -f "$BACKUP_DIR/media_backup_$TIMESTAMP.tar.gz" ]; then
    echo "Restoring media files..."
    docker run --rm \
        -v music-projects_sheet_api_media:/target \
        -v $(pwd)/$BACKUP_DIR:/backup \
        alpine sh -c "cd /target && tar xzf /backup/media_backup_$TIMESTAMP.tar.gz"
fi

echo "✅ Restore complete!"
```

#### 6.4 Script de Logs

Crear `music-projects/logs.sh`:
```bash
#!/bin/bash

SERVICE=${1:-all}

if [ "$SERVICE" = "all" ]; then
    docker compose -f docker-compose.production.yml logs -f
else
    docker compose -f docker-compose.production.yml logs -f $SERVICE
fi
```

**Tareas**:
1. ⬜ Crear `deploy.sh` con permisos de ejecución
2. ⬜ Crear `backup.sh` con permisos de ejecución
3. ⬜ Crear `restore.sh` con permisos de ejecución
4. ⬜ Crear `logs.sh` con permisos de ejecución
5. ⬜ Documentar uso de scripts en deployment-guide.md

---

### FASE 7: Documentación de Deployment

**Rama Git**: `feature/deployment-documentation`

#### 7.1 Guía de Instalación en VPS

Crear `music-projects/docs/deployment-guide.md`

Contenido:
- Requisitos del servidor (mínimo 2GB RAM, 2 CPU, 20GB disco)
- Instalación de Docker y Docker Compose
- Configuración de firewall (UFW)
- Configuración de DNS (A records)
- Paso a paso del primer deployment
- Configuración de SSL con Let's Encrypt
- Configuración de backups automáticos con cron

#### 7.2 Guía de Mantenimiento

Crear `music-projects/docs/maintenance-guide.md`

Contenido:
- Comandos básicos de Docker Compose
- Cómo ver logs
- Cómo hacer backups manuales
- Cómo restaurar backups
- Cómo actualizar la aplicación
- Cómo reiniciar servicios
- Monitoreo de recursos

#### 7.3 Troubleshooting

Crear `music-projects/docs/troubleshooting.md`

Contenido:
- Problemas comunes y soluciones
- Errores de CORS
- Errores de base de datos
- Problemas de conexión entre servicios
- Problemas de certificados SSL
- Performance issues

#### 7.4 README Principal

Actualizar `music-projects/README.md` con:
- Visión general del proyecto
- Descripción de cada aplicación
- Arquitectura de producción
- Links a documentación
- Quick start para desarrollo
- Quick start para producción

**Tareas**:
1. ⬜ Crear `docs/deployment-guide.md`
2. ⬜ Crear `docs/maintenance-guide.md`
3. ⬜ Crear `docs/troubleshooting.md`
4. ⬜ Actualizar `README.md` principal
5. ⬜ Crear diagramas de arquitectura (mermaid)

---

### FASE 8: Testing y Validación

**Rama Git**: `feature/production-testing`

#### 8.1 Testing Local

**Tareas**:
1. ⬜ Levantar stack completo con docker-compose.production.yml
2. ⬜ Verificar conectividad entre servicios
3. ⬜ Probar todos los endpoints de Sheet-API
4. ⬜ Probar carousel de Jam de Vientos
5. ⬜ Probar upload de archivos
6. ⬜ Verificar permisos y CORS
7. ⬜ Probar backups y restore

#### 8.2 Checklist Pre-Production

```markdown
- [ ] Todas las variables de entorno configuradas
- [ ] SECRET_KEY generada (no usar default)
- [ ] DEBUG=False en producción
- [ ] ALLOWED_HOSTS configurado correctamente
- [ ] CORS_ALLOWED_ORIGINS configurado
- [ ] Base de datos PostgreSQL inicializada
- [ ] Migraciones aplicadas
- [ ] Superuser creado en Django
- [ ] Static files collected
- [ ] Media directory con permisos correctos
- [ ] Nginx configurado con dominios correctos
- [ ] DNS apuntando al servidor
- [ ] Firewall configurado (80, 443)
- [ ] SSL certificates obtenidos
- [ ] Backups automáticos configurados
- [ ] Logs rotando correctamente
```

#### 8.3 Testing de Producción

**Después del deploy**:
1. ⬜ Verificar acceso HTTPS a todos los dominios
2. ⬜ Probar creación de evento desde Sheet-API admin
3. ⬜ Verificar que evento aparece en Jam de Vientos
4. ⬜ Probar carga de imágenes y audio
5. ⬜ Verificar performance (tiempo de carga)
6. ⬜ Probar desde diferentes dispositivos
7. ⬜ Verificar logs de errores

**Tareas**:
1. ⬜ Crear checklist de testing
2. ⬜ Documentar casos de prueba
3. ⬜ Crear script de validación automática
4. ⬜ Validar con usuarios reales

---

### FASE 9: Jam de Vientos v2.0 - Multi-Evento y Portada

**Rama Git**: `feature/multi-event-architecture`
**Duración estimada**: 8-12 horas
**Prioridad**: Alta (post-producción v1.0)

#### Objetivo:
Transformar Jam de Vientos en una plataforma multi-evento con portada profesional, calendar io interactivo y URLs dinámicas basadas en slugs.

#### 9.1 Backend (Sheet-API)

**Tareas**:
1. ⬜ Agregar campo `slug` al modelo Event (SlugField, unique)
2. ⬜ Implementar generación automática de slugs en save()
3. ⬜ Crear migración de base de datos
4. ⬜ Crear endpoint `/api/v1/events/jamdevientos/by-slug/`
5. ⬜ Crear modelo EventPhoto con campos: event, image, caption, photographer, is_public
6. ⬜ Crear ViewSet y serializer para EventPhoto
7. ⬜ Testing de endpoints nuevos

**Cambios en modelos**:
```python
class Event(models.Model):
    # ... campos existentes ...
    slug = models.SlugField(max_length=100, unique=True, blank=True)

    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = self.generate_slug()
        super().save(*args, **kwargs)

class EventPhoto(models.Model):
    event = models.ForeignKey(Event, on_delete=models.CASCADE, related_name='photos')
    image = models.ImageField(upload_to='event_photos/')
    caption = models.CharField(max_length=200, blank=True)
    photographer = models.CharField(max_length=100, blank=True)
    is_public = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
```

#### 9.2 Frontend (Jam de Vientos)

**Estructura de Rutas**:
```
app/
├── page.tsx                      # Portada con hero + calendario
├── eventos/page.tsx              # Lista completa de eventos
├── sobre-nosotros/page.tsx       # Información institucional
├── galeria/page.tsx              # Galería de fotos
└── [eventSlug]/
    └── page.tsx                  # Página del evento (carousel)
```

**Tareas**:
1. ⬜ Crear nueva estructura de rutas en App Router
2. ⬜ Implementar página portada con HeroSection component
3. ⬜ Integrar FullCalendar o React Big Calendar
4. ⬜ Crear EventsCalendar component
5. ⬜ Crear página "Sobre Nosotros" con contenido institucional
6. ⬜ Crear galería de fotos con PhotoSwipe o React Image Gallery
7. ⬜ Implementar dynamic route `[eventSlug]`
8. ⬜ Migrar carousel existente a la ruta dinámica
9. ⬜ Implementar función generateSlug() en cliente
10. ⬜ Implementar generateMetadata() para SEO dinámico
11. ⬜ Testing responsive (móvil, tablet, desktop)

**Librerías a instalar**:
```bash
npm install @fullcalendar/react @fullcalendar/daygrid @fullcalendar/interaction
npm install photoswipe react-image-gallery
npm install framer-motion  # Para animaciones
```

#### 9.3 Contenido

**Tareas**:
1. ⬜ Recopilar fotos de eventos para galería
2. ⬜ Escribir textos para "Sobre Nosotros"
3. ⬜ Crear o conseguir imágenes hero de alta calidad
4. ⬜ Preparar metadata de eventos (descripciones, imágenes OG)

**Entregables**:
- Sitio multi-evento completamente funcional
- Portada profesional con hero section
- Calendario interactivo de eventos
- Sección institucional "Sobre Nosotros"
- Galería de fotos navegable
- SEO optimizado con metadata dinámica
- URLs amigables con slugs

---

### FASE 10: Lector de Partituras Avanzado para Móviles

**Rama Git**: `feature/advanced-sheet-music-reader`
**Duración estimada**: 12-16 horas
**Prioridad**: Alta (feature estrella para músicos)

#### Objetivo:
Crear un lector de partituras profesional optimizado para móviles con sincronización de audio, control de tempo, metrónomo integrado y modo performance.

#### 10.1 Setup Inicial

**Tareas**:
1. ⬜ Instalar PDF.js y react-pdf
2. ⬜ Configurar PDF.js worker
3. ⬜ Crear estructura de componentes en `components/sheet-music-reader/`
4. ⬜ Setup de Zustand para state management del lector

**Librerías a instalar**:
```bash
npm install react-pdf pdfjs-dist
npm install zustand  # State management
npm install tone  # Web Audio API wrapper (opcional)
```

**Nueva ruta**:
```
app/[eventSlug]/partituras/[versionId]/page.tsx
```

#### 10.2 Visualización de PDF

**Componentes**:
- `PDFViewer.tsx`: Renderizado del PDF con react-pdf
- `PageNavigator.tsx`: Navegación entre páginas
- `ZoomControls.tsx`: Controles de zoom

**Tareas**:
1. ⬜ Implementar PDFViewer component con react-pdf
2. ⬜ Implementar zoom (pinch gesture, botones +/-)
3. ⬜ Implementar navegación de páginas (swipe, botones)
4. ⬜ Crear thumbnail sidebar para vista rápida
5. ⬜ Implementar loading states y error handling
6. ⬜ Optimizar renderizado (solo página visible)

#### 10.3 Reproductor de Audio con Control de Tempo

**Componentes**:
- `AudioPlayer.tsx`: Reproductor principal
- `TempoControl.tsx`: Slider y presets de tempo

**Tareas**:
1. ⬜ Crear clase AudioPlayerWithTempo usando Web Audio API
2. ⬜ Implementar cambio de playback rate (0.5x - 2.0x)
3. ⬜ Preservar pitch al cambiar tempo
4. ⬜ Crear TempoControl component con slider y presets
5. ⬜ Implementar controles play/pause/stop
6. ⬜ Display de tiempo actual y duración
7. ⬜ Progress bar interactivo
8. ⬜ Testing de performance en móviles

#### 10.4 Metrónomo Integrado

**Componentes**:
- `Metronome.tsx`: Metrónomo audible y visual
- `MetronomeControl.tsx`: Controles de BPM

**Tareas**:
1. ⬜ Crear clase Metronome con Web Audio API
2. ⬜ Generar sonidos de click (normal y accent)
3. ⬜ Implementar beat visual (círculos pulsantes)
4. ⬜ Crear MetronomeControl con slider de BPM (40-240)
5. ⬜ Sincronizar metrónomo con tempo del audio
6. ⬜ Control de volumen del metrónomo
7. ⬜ Configuración de subdivisiones (opcional para v2.1)

#### 10.5 Scrolling Automático Sincronizado

**Backend (Sheet-API)**:
1. ⬜ Agregar campo `page_timestamps` (JSONField) al modelo Version
2. ⬜ Crear migración
3. ⬜ Actualizar serializer para incluir page_timestamps
4. ⬜ Crear UI en admin de Sheet-API para configurar timestamps

**Frontend**:
1. ⬜ Implementar hook `useAutoScroll()`
2. ⬜ Calcular página actual basándose en currentTime del audio
3. ⬜ Smooth transition entre páginas
4. ⬜ Indicador visual de próximo cambio de página
5. ⬜ Testing de sincronización con diferentes tempos

**Formato de page_timestamps**:
```json
[
  { "page": 1, "timestamp": 0 },
  { "page": 2, "timestamp": 45 },
  { "page": 3, "timestamp": 90 },
  { "page": 4, "timestamp": 135 }
]
```

#### 10.6 Modo Performance

**Componente**: `PerformanceMode.tsx`

**Tareas**:
1. ⬜ Implementar fullscreen automático (Fullscreen API)
2. ⬜ Implementar Wake Lock API (evitar que pantalla se apague)
3. ⬜ Lock de orientación (Screen Orientation API)
4. ⬜ Controles grandes y táctiles para móvil
5. ⬜ Modo oscuro optimizado para lectura
6. ⬜ Brightness control (opcional)
7. ⬜ Testing en iOS y Android

#### 10.7 Integración y UI/UX

**Componente Principal**: `SheetMusicReader.tsx`

**Tareas**:
1. ⬜ Integrar todos los subcomponentes en SheetMusicReader
2. ⬜ Implementar ControlPanel con todos los controles
3. ⬜ State management con Zustand (audio, PDF, settings)
4. ⬜ Diseño responsive (móvil primero)
5. ⬜ Gestos táctiles (pinch, swipe, double-tap)
6. ⬜ Feedback visual de interacciones
7. ⬜ Dark mode nativo
8. ⬜ Persistencia de preferencias (localStorage)

#### 10.8 Testing y Optimización

**Tareas**:
1. ⬜ Testing en iPhone (Safari iOS)
2. ⬜ Testing en Android (Chrome)
3. ⬜ Testing en tablets
4. ⬜ Testing de performance (FPS, memory)
5. ⬜ Optimización de carga de PDFs grandes
6. ⬜ Testing de batería (Wake Lock impact)
7. ⬜ Testing de sincronización audio-scroll
8. ⬜ Validación con músicos reales

**Entregables**:
- Lector de partituras totalmente funcional
- Visualización PDF de alta calidad
- Sincronización audio-partitura
- Control de tempo preservando pitch
- Metrónomo integrado con beat visual
- Modo performance (fullscreen, no-sleep)
- Optimizado para móviles (iOS y Android)
- Testing completo en dispositivos reales
- Documentación de uso para músicos

---

## 5. Workflow de Git

### 5.1 Estrategia de Branches

```
main (producción)
  ├── develop (integración)
  │   ├── feature/production-setup-documentation
  │   ├── feature/preserve-admin-dashboard
  │   ├── feature/sheet-api-production-config
  │   ├── feature/jam-vientos-production-config
  │   ├── feature/docker-compose-production
  │   ├── feature/deployment-scripts
  │   ├── feature/deployment-documentation
  │   └── feature/production-testing
```

### 5.2 Proceso por Feature

Para cada fase:

```bash
# 1. Crear rama desde develop
git checkout develop
git pull origin develop
git checkout -b feature/nombre-feature

# 2. Desarrollar y commitear
git add .
git commit -m "feat: descripción del cambio"

# 3. Push de la rama
git push -u origin feature/nombre-feature

# 4. Crear Pull Request en GitHub/GitLab
# Revisar código, aprobar

# 5. Merge a develop
git checkout develop
git merge feature/nombre-feature

# 6. Push develop
git push origin develop

# 7. Eliminar rama local y remota
git branch -d feature/nombre-feature
git push origin --delete feature/nombre-feature

# 8. Cuando todas las features estén listas en develop
git checkout main
git merge develop
git push origin main
git tag -a v1.0.0 -m "Production release v1.0.0"
git push origin v1.0.0
```

### 5.3 Commits Semánticos

Usar [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: nueva funcionalidad
fix: corrección de bug
docs: solo documentación
style: formateo, punto y coma faltante, etc.
refactor: refactorización de código
test: agregar tests
chore: tareas de mantenimiento
perf: mejoras de performance
ci: cambios en CI/CD
```

---

## 6. Reutilización de Componentes y Librerías

### 6.1 Librerías ya en Uso

**Sheet-API Backend**:
- ✅ Django REST Framework (API)
- ✅ django-cors-headers (CORS)
- ✅ django-filter (filtros)
- ✅ drf-yasg (Swagger docs)
- ✅ djangorestframework-simplejwt (JWT)
- ✅ gunicorn (WSGI server)
- ✅ psycopg2 (PostgreSQL)

**Jam de Vientos Frontend**:
- ✅ Next.js 14 (framework)
- ✅ Radix UI (componentes base)
- ✅ shadcn/ui (componentes UI)
- ✅ Tailwind CSS v4 (estilos)
- ✅ Embla Carousel (carousel)
- ✅ React Hook Form + Zod (forms)
- ✅ next-themes (dark mode)

### 6.2 Componentes a Reutilizar (NO crear desde cero)

**UI Components** (ya disponibles en shadcn/ui):
- Button, Card, Input, Select
- Dialog, Dropdown, Popover
- Badge, Avatar, Alert
- Carousel (usar Embla)
- Form components
- Theme toggle

**Utilidades**:
- `cn()` utility para classNames (lib/utils.ts)
- SheetMusicAPI client (ya implementado)
- Auth context pattern (migrar a JWT)

### 6.3 Nuevas Librerías para Producción v1.0

**Monitoreo y Logging**:
- `winston` o `pino` (logging estructurado Node.js)
- `sentry` (error tracking - opcional)

**Performance**:
- `next/image` (optimización de imágenes - ya incluido)
- `sharp` (procesamiento de imágenes backend)

**Seguridad**:
- `helmet` (headers de seguridad para Express/Node)
- Ya incluido en Django: CSRF, XSS protection

**DevOps**:
- `pm2` (process manager - alternativa a standalone si es necesario)
- `nginx` (reverse proxy - ya planificado)

### 6.4 Nuevas Librerías para v2.0

**Multi-Evento y Portada** (FASE 9):
```json
{
  "@fullcalendar/react": "^6.1.0",        // Calendario interactivo
  "@fullcalendar/daygrid": "^6.1.0",      // Vista día/semana/mes
  "@fullcalendar/interaction": "^6.1.0",   // Interacciones touch/click
  "photoswipe": "^5.4.0",                  // Lightbox para galería
  "react-image-gallery": "^1.3.0",         // Alternativa galería
  "framer-motion": "^10.16.0"              // Animaciones fluidas
}
```

**Lector de Partituras Avanzado** (FASE 10):
```json
{
  "react-pdf": "^7.7.0",                   // Wrapper React para PDF.js
  "pdfjs-dist": "^3.11.0",                 // PDF.js core
  "zustand": "^4.5.0",                     // State management ligero
  "tone": "^14.7.77"                       // Web Audio API wrapper (opcional)
}
```

**APIs Web (no requieren instalación)**:
- **Web Audio API**: Control de audio y tempo (nativo)
- **Wake Lock API**: Evitar sleep en modo performance (nativo)
- **Fullscreen API**: Modo fullscreen (nativo)
- **Screen Orientation API**: Lock de orientación (nativo)
- **Page Visibility API**: Pausar al cambiar tab (nativo)

**Alternativas evaluadas**:
- ❌ **VexFlow**: Demasiado complejo para PDFs simples
- ❌ **ABCjs**: Específico para notación ABC, no PDFs
- ✅ **PDF.js**: Standard industry, bien mantenido, performance probado

---

## 7. Cronograma Estimado

### Producción v1.0 (Lectura Básica)

| Fase | Duración | Responsable | Estado |
|------|----------|-------------|--------|
| 1. Documentación | 2-3 horas | Dev | ✅ Completado |
| 2. Preservar Dashboard | 1 hora | Dev | ⏳ Pendiente |
| 3. Config Sheet-API | 2-3 horas | Dev | ⏳ Pendiente |
| 4. Config Jam Vientos | 2-3 horas | Dev | ⏳ Pendiente |
| 5. Docker Compose | 3-4 horas | Dev/DevOps | ⏳ Pendiente |
| 6. Scripts Deploy | 2 horas | DevOps | ⏳ Pendiente |
| 7. Docs Deploy | 2-3 horas | Dev | ⏳ Pendiente |
| 8. Testing | 3-4 horas | QA/Dev | ⏳ Pendiente |
| **TOTAL v1.0** | **17-23 horas** | | |

**Hitos v1.0**:
- ✅ Día 1-2: Documentación completa y configuración local
- ⏳ Día 3-4: Dockerización y scripts de deploy
- ⏳ Día 5: Testing local completo
- ⏳ Día 6: Deploy a VPS y testing producción
- ⏳ Día 7: Ajustes finales y go-live

### Extensión v2.0 (Multi-Evento + Lector Avanzado)

| Fase | Duración | Responsable | Estado |
|------|----------|-------------|--------|
| 9. Multi-Evento + Portada | 8-12 horas | Dev | ⏳ Post-v1.0 |
| 10. Lector de Partituras | 12-16 horas | Dev | ⏳ Post-v1.0 |
| **TOTAL v2.0** | **20-28 horas** | | |

**Hitos v2.0** (Post-producción v1.0):
- ⏳ Semana 1-2: Multi-evento, portada, calendario
- ⏳ Semana 3-4: Lector de partituras avanzado
- ⏳ Semana 5: Testing en móviles reales
- ⏳ Semana 6: Deploy v2.0 y validación con músicos

### Total del Proyecto Completo

| Versión | Horas | Timeline |
|---------|-------|----------|
| v1.0 (Producción básica) | 17-23h | 1 semana |
| v2.0 (Features avanzadas) | 20-28h | 4-6 semanas |
| **TOTAL** | **37-51h** | **5-7 semanas** |

---

## 8. Consideraciones de Seguridad

### 8.1 Backend (Django)

- ✅ SECRET_KEY desde variable de entorno
- ✅ DEBUG=False en producción
- ✅ ALLOWED_HOSTS restrictivo
- ✅ CSRF protection habilitado
- ✅ SQL injection protection (ORM)
- ✅ XSS protection
- ⬜ Rate limiting (implementar con django-ratelimit)
- ⬜ Security headers (implementar con django-security)

### 8.2 Frontend (Next.js)

- ✅ HTTPS only
- ✅ CSP headers
- ✅ No exponer API keys
- ✅ Sanitizar inputs
- ⬜ Implementar SRI (Subresource Integrity)

### 8.3 Infraestructura

- ⬜ Firewall configurado (solo 80, 443, 22)
- ⬜ SSH con key-based auth (deshabilitar password)
- ⬜ SSL/TLS certificates válidos
- ⬜ Backups automáticos encriptados
- ⬜ Logs de acceso y errores
- ⬜ Monitoreo de recursos

---

## 9. Próximos Pasos (Post-Producción)

### 9.1 Implementación Futura: Autenticación JWT

**Objetivo**: Permitir que usuarios de Sheet-API puedan editar eventos desde Jam de Vientos

**Tareas**:
1. Reactivar código del dashboard admin
2. Implementar JWT auth en Jam de Vientos
3. Conectar con endpoints de Sheet-API
4. Implementar refresh token
5. Agregar protected routes
6. Testing de flujo completo

### 9.2 Implementación Futura: Edición de Eventos

**Objetivo**: Permitir CRUD completo desde Jam de Vientos

**Tareas**:
1. Crear/actualizar endpoints en JamDeVientosViewSet
2. Implementar permisos granulares
3. Reactivar componentes de edición
4. Implementar validación de formularios
5. Testing de integridad de datos

### 9.3 Mejoras Adicionales

- Implementar PWA (Progressive Web App)
- Agregar analytics (Google Analytics, Plausible)
- Implementar sistema de notificaciones
- Agregar compartir en redes sociales
- Implementar SEO avanzado
- Agregar multilenguaje (i18n)

---

## 10. Recursos y Referencias

### 10.1 Documentación Oficial

- [Next.js Deployment](https://nextjs.org/docs/deployment)
- [Django Deployment Checklist](https://docs.djangoproject.com/en/4.2/howto/deployment/checklist/)
- [Docker Compose Production](https://docs.docker.com/compose/production/)
- [Let's Encrypt](https://letsencrypt.org/docs/)
- [Nginx Configuration](https://nginx.org/en/docs/)

### 10.2 Guías Relacionadas

- PostgreSQL Backup Best Practices
- JWT Best Practices
- CORS Configuration Guide
- Docker Security Best Practices
- CI/CD with GitHub Actions

---

## Resumen Ejecutivo

Este plan proporciona una hoja de ruta completa para llevar jam-de-vientos a producción integrándose con sheet-api. La estrategia se basa en:

1. **Simplicidad inicial**: Jam de Vientos como sitio público de solo lectura
2. **Centralización**: Sheet-API como única fuente de verdad
3. **Escalabilidad**: Arquitectura preparada para crecimiento futuro
4. **Mantenibilidad**: Documentación completa y scripts automatizados
5. **Seguridad**: Mejores prácticas desde el inicio

**Resultado esperado**: Stack completo funcionando en producción con:
- Jam de Vientos mostrando eventos públicos
- Sheet-API gestionando todos los datos
- Base de datos PostgreSQL compartida
- Backups automáticos
- SSL/TLS configurado
- Monitoreo básico
- Documentación completa

**Tiempo total estimado**: 17-23 horas de desarrollo

---

**Última actualización**: 2025-11-02
**Versión**: 1.0
**Estado**: 🔄 En progreso
