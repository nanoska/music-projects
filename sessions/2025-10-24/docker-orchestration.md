# Estrategias de Orquestación Docker: Music Projects

**Fecha**: 2025-10-24
**Objetivo**: Documentar cómo levantar y orquestar contenedores para las 4 aplicaciones según el escenario de trabajo.

---

## 1. Visión General

### 1.1 Aplicaciones y sus Dependencias

```
sheet-api/
├── backend (Django 4.2, puerto 8000)
├── frontend (React 19, puerto 3000)
└── db (PostgreSQL 15, puerto 5432)

jam-de-vientos/
├── frontend (Next.js 14, puerto 3001)
└── [DEPENDE] → sheet-api backend (puerto 8000)

music-learning-app/
├── backend (Django 4.2, puerto 8000)
├── frontend (React 18, puerto 3000)
├── db (PostgreSQL 15, puerto 5432)
└── redis (Redis 7, puerto 6379)

empiv-web/
├── backend (Django 5.1, puerto 8000)
├── frontend (React 19, puerto 3000)
└── db (PostgreSQL 15, puerto 5432)
```

### 1.2 Escenarios de Trabajo

| Escenario | Apps a Levantar | Razón |
|-----------|----------------|-------|
| **Trabajar en jam-de-vientos** | jam-de-vientos frontend + sheet-api backend + sheet-api db | Jam consume API de sheet-api |
| **Trabajar en sheet-api** | sheet-api backend + sheet-api frontend + sheet-api db | Full stack para admin |
| **Trabajar en music-learning-app** | music-learning-app full stack | Independiente |
| **Trabajar en empiv-web** | empiv-web full stack | Independiente |
| **Demo completo** | sheet-api + jam-de-vientos + music-learning + empiv | Mostrar ecosistema |

---

## 2. Escenario 1: Trabajar en Jam de Vientos

### 2.1 Servicios Necesarios

```
┌─────────────────────────────────────┐
│  jam-de-vientos                     │
│  ├── frontend (Next.js, :3001)      │
│  └── [consume] → sheet-api backend  │
└─────────────────────────────────────┘
             ↓
┌─────────────────────────────────────┐
│  sheet-api (solo backend)           │
│  ├── backend (Django, :8000)        │
│  └── db (PostgreSQL, :5432)         │
└─────────────────────────────────────┘
```

### 2.2 Comandos

#### Paso 1: Levantar sheet-api backend

```bash
# Navegar al directorio sheet-api
cd sheet-api/

# Levantar solo backend y db (sin frontend)
docker compose up -d backend db

# Verificar que estén corriendo
docker compose ps

# Salida esperada:
# NAME              STATUS    PORTS
# sheet-api-backend  running   0.0.0.0:8000->8000/tcp
# sheet-api-db       running   5432/tcp
```

#### Paso 2: Verificar red Docker

```bash
# Listar redes Docker
docker network ls | grep sheet

# Debería mostrar:
# sheetmusic_sheetmusic-network (o sheet-api_default)
```

**⚠️ Importante**: jam-de-vientos necesita conectarse a la red de sheet-api.

#### Paso 3: Configurar jam-de-vientos

```bash
cd ../jam-de-vientos/frontend/

# Crear .env.local si no existe
cat > .env.local <<EOF
NEXT_PUBLIC_SHEETMUSIC_API_URL=http://backend:8000
EOF
```

**Nota**: `http://backend:8000` funciona porque ambos contenedores están en la misma red Docker y "backend" es el nombre del servicio en sheet-api.

#### Paso 4: Levantar jam-de-vientos frontend

```bash
cd ../  # Volver a jam-de-vientos/

# Levantar frontend
docker compose up -d frontend

# Ver logs en tiempo real
docker compose logs -f frontend
```

### 2.3 Acceso

- **Frontend jam-de-vientos**: http://localhost:3001
- **Backend sheet-api**: http://localhost:8000/admin (para gestión)
- **API sheet-api**: http://localhost:8000/api/v1/

### 2.4 Detener Servicios

```bash
# Desde jam-de-vientos/
docker compose down

# Desde sheet-api/
docker compose down

# O detener todo a la vez
docker compose down && cd ../sheet-api && docker compose down
```

### 2.5 Troubleshooting

**Error: "ECONNREFUSED backend:8000"**
- Verificar que backend de sheet-api esté corriendo
- Verificar que ambos contenedores estén en la misma red
- Revisar .env.local de jam-de-vientos

**Error: "Network sheetmusic_sheetmusic-network not found"**
```bash
# Crear red manualmente
docker network create sheetmusic_sheetmusic-network

# O renombrar en docker-compose.yml de jam-de-vientos
networks:
  default:
    external: true
    name: sheet-api_default  # Usar la red default de sheet-api
```

---

## 3. Escenario 2: Trabajar en Sheet-API

### 3.1 Servicios Necesarios

```
┌──────────────────────────────────────┐
│  sheet-api (full stack)              │
│  ├── frontend (React, :3000)         │
│  ├── backend (Django, :8000)         │
│  └── db (PostgreSQL, :5432)          │
└──────────────────────────────────────┘
```

### 3.2 Comandos

#### Opción A: Levantar Todo con Docker

```bash
cd sheet-api/

# Levantar todos los servicios
docker compose up -d

# Ver estado
docker compose ps

# Ver logs
docker compose logs -f
```

#### Opción B: Backend en Docker, Frontend Local (Desarrollo Activo)

```bash
# Terminal 1: Backend en Docker
cd sheet-api/
docker compose up -d backend db

# Terminal 2: Frontend local
cd frontend/
npm install
npm start  # Corre en http://localhost:3000
```

**Ventajas de Opción B**:
- Hot reload más rápido en frontend
- Debugging más fácil con DevTools
- No necesitas rebuilds de Docker por cambios JS

### 3.3 Configuración de Variables

**Backend (.env)**:
```bash
# sheet-api/backend/.env
DEBUG=True
SECRET_KEY=tu-secret-key
DATABASE_URL=postgresql://sheetapi:sheetapi@db:5432/sheetapi_db
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:3001
ALLOWED_HOSTS=localhost,127.0.0.1,backend
```

**Frontend (.env.local)**:
```bash
# sheet-api/frontend/.env.local
REACT_APP_API_URL=http://localhost:8000/api/v1
```

### 3.4 Tareas Comunes

**Crear migraciones**:
```bash
docker compose exec backend python manage.py makemigrations
docker compose exec backend python manage.py migrate
```

**Crear superuser**:
```bash
docker compose exec backend python manage.py createsuperuser
```

**Acceder a la shell Django**:
```bash
docker compose exec backend python manage.py shell
```

**Cargar datos de prueba**:
```bash
docker compose exec backend python manage.py loaddata instruments.json
```

### 3.5 Rebuild Después de Cambios

**Cuándo hacer rebuild**:
- Cambios en requirements.txt (backend)
- Cambios en package.json (frontend)
- Cambios en Dockerfile

**Comando**:
```bash
# Rebuild completo limpio
docker compose down -v  # -v elimina volúmenes (limpia node_modules, etc.)
docker compose build --no-cache
docker compose up -d
```

---

## 4. Escenario 3: Trabajar en Music Learning App

### 4.1 Servicios Necesarios

```
┌─────────────────────────────────────────┐
│  music-learning-app (independiente)     │
│  ├── frontend (React, :3000)            │
│  ├── backend (Django, :8000)            │
│  ├── db (PostgreSQL, :5432)             │
│  └── redis (Redis, :6379) ← Celery     │
└─────────────────────────────────────────┘
```

### 4.2 Comandos

```bash
cd music-learning-app/

# Levantar todos los servicios
docker compose up -d

# Ver logs (especialmente útil para Celery)
docker compose logs -f backend redis
```

### 4.3 Particularidades

**Celery Workers**:
Music learning app usa Celery para tareas asíncronas (procesamiento de audio con librosa).

```bash
# Ver logs de tareas Celery
docker compose logs -f backend | grep celery

# Ejecutar tareas manualmente desde shell
docker compose exec backend python manage.py shell
>>> from exercises.tasks import process_audio
>>> result = process_audio.delay(audio_file_id)
```

**Redis CLI**:
```bash
docker compose exec redis redis-cli

# Ver keys
127.0.0.1:6379> KEYS *

# Ver info
127.0.0.1:6379> INFO
```

---

## 5. Escenario 4: Trabajar en EMPIV Web

### 5.1 Servicios Necesarios

```
┌──────────────────────────────────────┐
│  empiv-web (independiente)           │
│  ├── frontend (React, :3000)         │
│  ├── backend (Django, :8000)         │
│  └── db (PostgreSQL, :5432)          │
└──────────────────────────────────────┘
```

### 5.2 Comandos

```bash
cd empiv-web/

# Levantar servicios
docker compose up -d

# Ver logs
docker compose logs -f
```

### 5.3 Notas

**Versión Django**: EMPIV web usa Django 5.1 (más reciente que sheet-api y music-learning).

**Directorios**:
- `/empiv-web-react/`: Nueva versión con React (usar esta)
- `/empiv-django-templates/`: Versión vieja con templates Django (ignorar)

---

## 6. Escenario 5: Demo Completo del Ecosistema

### 6.1 Orden de Levantamiento

```bash
# 1. Sheet-API (base del ecosistema)
cd sheet-api/
docker compose up -d
sleep 10  # Esperar a que backend esté listo

# 2. Jam de Vientos (depende de sheet-api)
cd ../jam-de-vientos/
docker compose up -d

# 3. Music Learning App (independiente)
cd ../music-learning-app/
docker compose up -d

# 4. EMPIV Web (independiente)
cd ../empiv-web/
docker compose up -d

# Verificar todos
cd ..
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

### 6.2 Puertos Usados

| Aplicación | Frontend | Backend | DB | Otros |
|------------|----------|---------|-----|-------|
| sheet-api | 3000 | 8000 | 5432 | - |
| jam-de-vientos | 3001 | ➔ 8000 (sheet-api) | ➔ (sheet-api) | - |
| music-learning-app | 3002* | 8001* | 5433* | 6379 (redis) |
| empiv-web | 3003* | 8002* | 5434* | - |

**Nota**: Los puertos con `*` necesitan ser modificados en docker-compose.yml para evitar colisiones.

### 6.3 Modificar Puertos en docker-compose.yml

**music-learning-app/docker-compose.yml**:
```yaml
services:
  frontend:
    ports:
      - "3002:3000"  # ← Cambiar de 3000 a 3002
  backend:
    ports:
      - "8001:8000"  # ← Cambiar de 8000 a 8001
  db:
    ports:
      - "5433:5432"  # ← Cambiar de 5432 a 5433
```

**empiv-web/docker-compose.yml**:
```yaml
services:
  frontend:
    ports:
      - "3003:3000"
  backend:
    ports:
      - "8002:8000"
  db:
    ports:
      - "5434:5432"
```

### 6.4 Acceso a Todas las Apps

- **Sheet-API Admin**: http://localhost:3000
- **Sheet-API Backend**: http://localhost:8000
- **Jam de Vientos**: http://localhost:3001
- **Music Learning App**: http://localhost:3002
- **EMPIV Web**: http://localhost:3003

### 6.5 Detener Todo

```bash
# Desde root del proyecto
for dir in sheet-api jam-de-vientos music-learning-app empiv-web; do
  cd $dir && docker compose down && cd ..
done
```

---

## 7. Redes Docker

### 7.1 Modelo Actual (Redes Separadas)

```
sheet-api_default ────┐
                      │
jam-de-vientos_default ┼─ Conecta a: sheetmusic_sheetmusic-network
                      │  (externa, creada por sheet-api)
                      │
music-learning-app_default ─ (aislada)
                      │
empiv-web_default ────┘ (aislada)
```

### 7.2 Alternativa: Red Compartida (No Implementado)

**Ventajas**:
- Todas las apps pueden comunicarse entre sí
- Útil para futuras integraciones

**Desventajas**:
- Mayor complejidad
- Posibles colisiones de nombres de servicios

**Implementación (si se requiere en el futuro)**:
```bash
# Crear red compartida
docker network create music-projects-network

# En cada docker-compose.yml:
networks:
  default:
    external: true
    name: music-projects-network
```

---

## 8. Volúmenes y Persistencia

### 8.1 Datos Persistentes

**PostgreSQL**:
```yaml
volumes:
  postgres_data:  # Persiste datos de DB entre rebuilds
```

**Media Files (sheet-api)**:
```yaml
volumes:
  - ./backend/media:/app/media  # Archivos subidos (PDFs, audio, images)
```

### 8.2 Limpiar Volúmenes

**⚠️ CUIDADO**: Esto elimina TODOS los datos (DB, archivos subidos).

```bash
# Detener servicios y eliminar volúmenes
docker compose down -v

# Eliminar volúmenes huérfanos
docker volume prune
```

### 8.3 Backup de Base de Datos

```bash
# Backup
docker compose exec db pg_dump -U sheetapi -d sheetapi_db > backup.sql

# Restore
docker compose exec -T db psql -U sheetapi -d sheetapi_db < backup.sql
```

### 8.4 Backup de Media Files

```bash
# Backup
cd sheet-api/backend/
tar -czf media_backup_$(date +%Y%m%d).tar.gz media/

# Restore
tar -xzf media_backup_20251024.tar.gz
```

---

## 9. Variables de Entorno

### 9.1 Plantilla .env para sheet-api Backend

```bash
# sheet-api/backend/.env

# Django
DEBUG=True
SECRET_KEY=tu-secret-key-super-segura
ALLOWED_HOSTS=localhost,127.0.0.1,backend

# Database
DATABASE_URL=postgresql://sheetapi:sheetapi@db:5432/sheetapi_db

# CORS
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:3001

# JWT
SIMPLE_JWT_ACCESS_TOKEN_LIFETIME=60  # minutos
SIMPLE_JWT_REFRESH_TOKEN_LIFETIME=1440  # minutos (1 día)

# Media/Static
MEDIA_URL=/media/
STATIC_URL=/static/
```

### 9.2 Plantilla .env.local para Frontends

**sheet-api/frontend/.env.local**:
```bash
REACT_APP_API_URL=http://localhost:8000/api/v1
```

**jam-de-vientos/frontend/.env.local**:
```bash
# Desarrollo local (frontend fuera de Docker)
NEXT_PUBLIC_SHEETMUSIC_API_URL=http://localhost:8000

# Desarrollo Docker
NEXT_PUBLIC_SHEETMUSIC_API_URL=http://backend:8000
```

**music-learning-app/frontend/.env.local**:
```bash
REACT_APP_API_URL=http://localhost:8001/api/v1
```

**empiv-web/frontend/.env.local**:
```bash
REACT_APP_API_URL=http://localhost:8002/api/v1
```

---

## 10. Logs y Debugging

### 10.1 Ver Logs

```bash
# Logs en tiempo real de todos los servicios
docker compose logs -f

# Logs de un servicio específico
docker compose logs -f backend

# Últimas 100 líneas
docker compose logs --tail=100 backend

# Logs con timestamps
docker compose logs -f --timestamps
```

### 10.2 Entrar a un Contenedor

```bash
# Shell interactiva
docker compose exec backend bash

# Ejecutar comando único
docker compose exec backend ls -la /app/media
```

### 10.3 Debugging Backend Django

**Agregar breakpoints con pdb**:
```python
# En cualquier view o función
import pdb; pdb.set_trace()
```

**Conectar a pdb desde Docker**:
```bash
# Detener servicio normal
docker compose stop backend

# Correr backend en modo interactivo
docker compose run --rm --service-ports backend

# Ahora cuando llegue a pdb.set_trace(), tendrás shell interactiva
```

### 10.4 Debugging Frontend

**React DevTools**: Funciona normalmente en http://localhost:3000

**Network Tab**: Ver requests HTTP a backend

**Console Logs**: Ver en navegador, también aparecen en `docker compose logs frontend`

---

## 11. Performance y Optimización

### 11.1 Desarrollo con Hot Reload

**Backend Django**:
- Ya incluido por defecto con `runserver`
- Auto-reloads al cambiar archivos .py

**Frontend React**:
- Hot reload funciona en Docker con configuración correcta de webpack
- Para mejor performance, correr frontend localmente (no en Docker)

### 11.2 Build Times

**Reducir build times**:
```dockerfile
# Multi-stage builds (ya implementado)
FROM node:20-alpine as builder
...
FROM nginx:alpine
```

**Cache de layers**:
```dockerfile
# Copiar solo package.json primero (layer caching)
COPY package.json package-lock.json ./
RUN npm ci
# Luego copiar código fuente
COPY . .
```

### 11.3 Recursos Docker

**Ver uso de recursos**:
```bash
docker stats

# Salida:
# CONTAINER          CPU %   MEM USAGE / LIMIT     MEM %
# sheet-api-backend  2.5%    256MB / 2GB          12.8%
# sheet-api-db       0.5%    50MB / 512MB         9.76%
```

**Limitar recursos en docker-compose.yml**:
```yaml
services:
  backend:
    deploy:
      resources:
        limits:
          memory: 2G
          cpus: '1.0'
```

---

## 12. Troubleshooting General

### 12.1 "Port already allocated"

**Error**:
```
Error: bind: address already in use (port 8000)
```

**Solución**:
```bash
# Ver qué está usando el puerto
lsof -i :8000

# Matar proceso
kill -9 <PID>

# O cambiar puerto en docker-compose.yml
ports:
  - "8001:8000"  # Host:Container
```

### 12.2 "No space left on device"

**Causa**: Docker images/volumes llenan disco.

**Solución**:
```bash
# Limpiar imágenes sin usar
docker image prune -a

# Limpiar volúmenes huérfanos
docker volume prune

# Limpiar todo (⚠️ elimina contenedores detenidos, redes, etc.)
docker system prune -a --volumes
```

### 12.3 "Cannot connect to Docker daemon"

**Causa**: Docker no está corriendo.

**Solución**:
```bash
# Linux
sudo systemctl start docker

# macOS
open -a Docker

# Verificar
docker ps
```

### 12.4 "ModuleNotFoundError" en Backend

**Causa**: Dependencias no instaladas en contenedor.

**Solución**:
```bash
# Rebuild backend
docker compose build --no-cache backend
docker compose up -d backend
```

### 12.5 "ECONNREFUSED" en Frontend

**Causa**: Backend no está corriendo o URL incorrecta.

**Verificación**:
```bash
# Verificar backend
curl http://localhost:8000/api/v1/themes/

# Verificar desde contenedor frontend
docker compose exec frontend curl http://backend:8000/api/v1/themes/
```

---

## 13. Checklist Pre-Commit

Antes de hacer commit después de trabajar con Docker:

- [ ] Detener servicios: `docker compose down`
- [ ] Verificar que no quedan contenedores corriendo: `docker ps`
- [ ] No commitear archivos `.env` con secretos
- [ ] No commitear carpeta `media/` con archivos grandes
- [ ] Documentar cambios en docker-compose.yml en commit message
- [ ] Si cambió requirements.txt, documentar `docker compose build` necesario

---

## 14. Scripts de Automatización (Propuestos)

### 14.1 start-jamdevientos.sh

```bash
#!/bin/bash
# Levantar sheet-api backend y jam-de-vientos frontend

echo "Levantando sheet-api backend..."
cd sheet-api && docker compose up -d backend db

echo "Esperando a que backend esté listo..."
sleep 10

echo "Levantando jam-de-vientos frontend..."
cd ../jam-de-vientos && docker compose up -d frontend

echo "✅ Servicios listos:"
echo "   - Sheet-API Backend: http://localhost:8000"
echo "   - Jam de Vientos: http://localhost:3001"
```

### 14.2 start-sheetapi.sh

```bash
#!/bin/bash
# Levantar sheet-api completo

cd sheet-api && docker compose up -d

echo "✅ Sheet-API listo:"
echo "   - Frontend (Admin): http://localhost:3000"
echo "   - Backend (API): http://localhost:8000"
echo "   - Swagger: http://localhost:8000/swagger/"
```

### 14.3 stop-all.sh

```bash
#!/bin/bash
# Detener todos los servicios

for dir in sheet-api jam-de-vientos music-learning-app empiv-web; do
  if [ -d "$dir" ]; then
    echo "Deteniendo $dir..."
    cd $dir && docker compose down && cd ..
  fi
done

echo "✅ Todos los servicios detenidos"
```

---

## 15. Resumen de Comandos Rápidos

```bash
# Levantar servicios
docker compose up -d

# Ver logs
docker compose logs -f

# Detener servicios
docker compose down

# Rebuild completo
docker compose down -v && docker compose build --no-cache && docker compose up -d

# Ver estado
docker compose ps

# Ejecutar comando en contenedor
docker compose exec backend python manage.py migrate

# Ver uso de recursos
docker stats

# Limpiar todo
docker system prune -a --volumes
```

---

**Documento generado**: 2025-10-24
**Última actualización**: 2025-10-24
**Próximo paso**: Crear README.md de sesión
