# Guía de Orquestación Docker: Music Projects

Esta guía documenta cómo levantar y orquestar contenedores Docker para las 4 aplicaciones del ecosistema de proyectos musicales, optimizando el flujo de trabajo según el escenario.

---

## 📋 Tabla de Contenidos

- [Visión General](#-visión-general)
- [Escenarios de Trabajo](#-escenarios-de-trabajo)
- [Comandos por Escenario](#-comandos-por-escenario)
- [Troubleshooting](#-troubleshooting)
- [Scripts de Automatización](#-scripts-de-automatización)
- [Referencia Rápida](#-referencia-rápida)

---

## 🎯 Visión General

### Aplicaciones y Puertos

| Aplicación | Frontend | Backend | DB | Otros |
|------------|----------|---------|-----|-------|
| **sheet-api** | :3000 | :8000 | :5432 | - |
| **jam-de-vientos** | :3001 | → sheet-api:8000 | → sheet-api | - |
| **music-learning-app** | :3000 | :8000 | :5432 | :6379 (Redis) |
| **empiv-web** | :3000 | :8000 | :5432 | - |

### Dependencias entre Apps

```
sheet-api (independiente)
    ↓ API REST
jam-de-vientos (depende de sheet-api backend)

music-learning-app (independiente)

empiv-web (independiente)
```

---

## 🔄 Escenarios de Trabajo

### 1️⃣ Trabajar en jam-de-vientos

**Servicios necesarios**:
- sheet-api backend + db
- jam-de-vientos frontend

**Comandos**:
```bash
# Terminal 1: Levantar sheet-api backend
cd sheet-api/
docker compose up -d backend db

# Esperar 10 segundos para que backend esté listo
sleep 10

# Terminal 2: Levantar jam-de-vientos frontend
cd ../jam-de-vientos/
docker compose up -d frontend
```

**Acceso**:
- Frontend: http://localhost:3001
- Backend API: http://localhost:8000/api/v1/
- Admin: http://localhost:8000/admin

**Detener**:
```bash
# Desde jam-de-vientos/
docker compose down

# Desde sheet-api/
cd ../sheet-api && docker compose down
```

---

### 2️⃣ Trabajar en sheet-api

**Servicios necesarios**:
- sheet-api backend + frontend + db

#### Opción A: Todo en Docker

```bash
cd sheet-api/
docker compose up -d

# Ver logs
docker compose logs -f
```

#### Opción B: Backend en Docker, Frontend Local (Recomendado para desarrollo activo)

```bash
# Terminal 1: Backend en Docker
cd sheet-api/
docker compose up -d backend db

# Terminal 2: Frontend local (hot reload más rápido)
cd frontend/
npm install
npm start  # http://localhost:3000
```

**Tareas comunes**:
```bash
# Crear superusuario
docker compose exec backend python manage.py createsuperuser

# Migraciones
docker compose exec backend python manage.py makemigrations
docker compose exec backend python manage.py migrate

# Django shell
docker compose exec backend python manage.py shell
```

---

### 3️⃣ Trabajar en music-learning-app

**Servicios necesarios**:
- music-learning-app backend + frontend + db + redis

```bash
cd music-learning-app/
docker compose up -d

# Ver logs (especialmente útil para Celery)
docker compose logs -f backend redis
```

**Redis CLI**:
```bash
docker compose exec redis redis-cli
127.0.0.1:6379> KEYS *
127.0.0.1:6379> INFO
```

---

### 4️⃣ Trabajar en empiv-web

**Servicios necesarios**:
- empiv-web backend + frontend + db

```bash
cd empiv-web/
docker compose up -d

# Ver logs
docker compose logs -f
```

**Nota**: Usar el directorio `/empiv-web-react/` (nueva versión con React), ignorar `/empiv-django-templates/` (versión vieja).

---

### 5️⃣ Demo Completo del Ecosistema

**Levantar todas las aplicaciones** (requiere modificar puertos para evitar colisiones):

```bash
# 1. Sheet-API (base del ecosistema)
cd sheet-api/
docker compose up -d
sleep 10

# 2. Jam de Vientos (depende de sheet-api)
cd ../jam-de-vientos/
docker compose up -d

# 3. Music Learning App (independiente)
cd ../music-learning-app/
# Modificar docker-compose.yml: puertos 3002, 8001, 5433
docker compose up -d

# 4. EMPIV Web (independiente)
cd ../empiv-web/
# Modificar docker-compose.yml: puertos 3003, 8002, 5434
docker compose up -d

# Verificar todos
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

**Acceso**:
- Sheet-API: http://localhost:3000
- Jam de Vientos: http://localhost:3001
- Music Learning: http://localhost:3002
- EMPIV Web: http://localhost:3003

---

## 🐛 Troubleshooting

### Error: "Port already allocated"

**Problema**: Puerto 8000 ya está en uso.

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

---

### Error: "ECONNREFUSED backend:8000"

**Problema**: jam-de-vientos no puede conectarse a sheet-api backend.

**Verificación**:
```bash
# Verificar que backend esté corriendo
cd sheet-api && docker compose ps

# Verificar red Docker
docker network ls | grep sheet

# Verificar .env.local de jam-de-vientos
cat jam-de-vientos/frontend/.env.local
# Debe tener: NEXT_PUBLIC_SHEETMUSIC_API_URL=http://backend:8000
```

---

### Error: "Network not found"

**Problema**: jam-de-vientos requiere red de sheet-api que no existe.

**Solución**:
```bash
# Opción 1: Levantar sheet-api primero (crea la red automáticamente)
cd sheet-api && docker compose up -d

# Opción 2: Crear red manualmente
docker network create sheetmusic_sheetmusic-network

# Opción 3: Modificar docker-compose.yml de jam-de-vientos
networks:
  default:
    external: true
    name: sheet-api_default  # Usar red default de sheet-api
```

---

### Error: "ModuleNotFoundError" en Backend

**Problema**: Dependencias Python no instaladas en contenedor.

**Solución**:
```bash
# Rebuild backend sin caché
docker compose build --no-cache backend
docker compose up -d backend
```

---

### Error: "No space left on device"

**Problema**: Docker images/volumes llenan el disco.

**Solución**:
```bash
# Limpiar imágenes sin usar
docker image prune -a

# Limpiar volúmenes huérfanos
docker volume prune

# Limpiar todo (⚠️ cuidado: elimina contenedores detenidos, redes, etc.)
docker system prune -a --volumes
```

---

### Rebuild Completo Limpio

**Cuándo usar**:
- Cambios en requirements.txt (Python)
- Cambios en package.json (Node.js)
- Errores extraños de dependencias
- Después de mover proyecto entre directorios

**Comando**:
```bash
docker compose down -v  # -v elimina volúmenes (limpia node_modules, caches)
docker compose build --no-cache
docker compose up -d
```

---

## 🚀 Scripts de Automatización

### start-jamdevientos.sh

```bash
#!/bin/bash
# Levantar sheet-api backend y jam-de-vientos frontend

echo "🚀 Levantando sheet-api backend..."
cd sheet-api && docker compose up -d backend db

echo "⏳ Esperando a que backend esté listo..."
sleep 10

echo "🚀 Levantando jam-de-vientos frontend..."
cd ../jam-de-vientos && docker compose up -d frontend

echo ""
echo "✅ Servicios listos:"
echo "   🌐 Jam de Vientos: http://localhost:3001"
echo "   🔌 Sheet-API Backend: http://localhost:8000"
echo "   📖 API Docs: http://localhost:8000/swagger/"
```

**Uso**:
```bash
chmod +x start-jamdevientos.sh
./start-jamdevientos.sh
```

---

### start-sheetapi.sh

```bash
#!/bin/bash
# Levantar sheet-api completo

echo "🚀 Levantando sheet-api (full stack)..."
cd sheet-api && docker compose up -d

echo ""
echo "✅ Sheet-API listo:"
echo "   👤 Admin Dashboard: http://localhost:3000"
echo "   🔌 Backend API: http://localhost:8000"
echo "   📖 Swagger: http://localhost:8000/swagger/"
echo "   📄 ReDoc: http://localhost:8000/redoc/"
```

---

### stop-all.sh

```bash
#!/bin/bash
# Detener todos los servicios

echo "🛑 Deteniendo todos los servicios..."

for dir in sheet-api jam-de-vientos music-learning-app empiv-web; do
  if [ -d "$dir" ]; then
    echo "   Deteniendo $dir..."
    cd $dir && docker compose down && cd ..
  fi
done

echo ""
echo "✅ Todos los servicios detenidos"
```

---

### logs-all.sh

```bash
#!/bin/bash
# Ver logs de todos los servicios en tabs separados

# Requires: tmux

tmux new-session -d -s logs "cd sheet-api && docker compose logs -f"
tmux split-window -h "cd jam-de-vientos && docker compose logs -f"
tmux split-window -v "cd music-learning-app && docker compose logs -f"
tmux select-pane -t 0
tmux split-window -v "cd empiv-web && docker compose logs -f"
tmux attach-session -t logs
```

---

## 🔧 Gestión de Volúmenes y Persistencia

### Backup Base de Datos

```bash
# Backup
docker compose exec db pg_dump -U sheetapi -d sheetapi_db > backup_$(date +%Y%m%d).sql

# Restore
docker compose exec -T db psql -U sheetapi -d sheetapi_db < backup_20251024.sql
```

### Backup Media Files

```bash
# Backup
cd sheet-api/backend/
tar -czf media_backup_$(date +%Y%m%d).tar.gz media/

# Restore
tar -xzf media_backup_20251024.tar.gz
```

### Limpiar Volúmenes (⚠️ Elimina TODOS los datos)

```bash
# Detener servicios y eliminar volúmenes
docker compose down -v

# Eliminar volúmenes huérfanos
docker volume prune
```

---

## 📊 Monitoring y Logs

### Ver Logs

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

### Ver Uso de Recursos

```bash
docker stats

# Salida:
# CONTAINER          CPU %   MEM USAGE / LIMIT     MEM %
# sheet-api-backend  2.5%    256MB / 2GB          12.8%
# sheet-api-db       0.5%    50MB / 512MB         9.76%
```

### Entrar a un Contenedor

```bash
# Shell interactiva
docker compose exec backend bash

# Ejecutar comando único
docker compose exec backend ls -la /app/media

# PostgreSQL shell
docker compose exec db psql -U sheetapi -d sheetapi_db
```

---

## ⚙️ Variables de Entorno

### sheet-api Backend (.env)

```bash
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
```

### sheet-api Frontend (.env.local)

```bash
# Desarrollo local (frontend fuera de Docker)
REACT_APP_API_URL=http://localhost:8000/api/v1

# Desarrollo Docker
REACT_APP_API_URL=http://backend:8000/api/v1
```

### jam-de-vientos Frontend (.env.local)

```bash
# Desarrollo local
NEXT_PUBLIC_SHEETMUSIC_API_URL=http://localhost:8000

# Desarrollo Docker
NEXT_PUBLIC_SHEETMUSIC_API_URL=http://backend:8000
```

---

## 🎯 Checklist Pre-Commit

Antes de hacer commit después de trabajar con Docker:

- [ ] Detener servicios: `docker compose down`
- [ ] Verificar que no quedan contenedores corriendo: `docker ps`
- [ ] No commitear archivos `.env` con secretos
- [ ] No commitear carpeta `media/` con archivos grandes
- [ ] Documentar cambios en docker-compose.yml en commit message
- [ ] Si cambió requirements.txt, documentar que necesita `docker compose build`

---

## 📚 Referencia Rápida

### Comandos Esenciales

```bash
# Levantar servicios
docker compose up -d

# Ver logs
docker compose logs -f

# Detener servicios
docker compose down

# Rebuild limpio
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

### Redes Docker

```bash
# Listar redes
docker network ls

# Inspeccionar red
docker network inspect sheet-api_default

# Crear red compartida (si es necesario)
docker network create music-projects-network
```

### Debugging

```bash
# Ver variables de entorno de un contenedor
docker compose exec backend env

# Ver configuración Docker Compose procesada
docker compose config

# Rebuild solo un servicio
docker compose build backend
docker compose up -d backend
```

---

## 📖 Documentación Adicional

- **Análisis de Arquitectura**: `../sessions/2025-10-24/architecture-analysis.md`
- **Modelos Django**: `../sessions/2025-10-24/models-final.md`
- **Contratos API**: `../sessions/2025-10-24/api-contracts.md`
- **Guía Completa Docker**: `../sessions/2025-10-24/docker-orchestration.md`

---

## 🆘 Soporte

Si encuentras problemas:

1. Revisar esta guía de troubleshooting
2. Ver logs: `docker compose logs -f`
3. Consultar documentación completa en `sessions/2025-10-24/`
4. Abrir issue en el repositorio correspondiente

---

*Última actualización: 2025-10-24*
