# Jam de Vientos - API Connection Fix

**Fecha:** 2025-11-18
**Duración:** ~1 hora
**Estado:** ✅ Completado

## Problema Detectado

Al levantar jam-de-vientos con Docker, la aplicación quedaba en loading infinito mostrando "Cargando temas musicales...". La consola del navegador mostraba errores `net::ERR_NAME_NOT_RESOLVED` al intentar conectarse a `http://backend:8000`.

### Causa Raíz

**Problema 1: URL de API incorrecta para el navegador**
- La variable `NEXT_PUBLIC_SHEETMUSIC_API_URL` estaba configurada como `http://backend:8000`
- Los nombres de servicio Docker (`backend`) solo funcionan **dentro de la red Docker** (server-to-server)
- Las variables `NEXT_PUBLIC_*` de Next.js se **compilan en el código del cliente** (browser-side)
- El navegador no puede resolver nombres de servicios Docker, necesita `localhost`

**Problema 2: Repertorio sin versiones**
- Los eventos devueltos por la API no tenían versiones asociadas en sus repertorios
- El código de jam-de-vientos espera `event.repertoire.versions.length > 0`
- Al recibir arrays vacíos, el código nunca salía del estado de loading

## Solución Implementada

### 1. Configuración de URL de API

**Archivo:** `jam-de-vientos/docker-compose.yml`
```yaml
environment:
  # Antes:
  - NEXT_PUBLIC_SHEETMUSIC_API_URL=http://backend:8000

  # Después:
  - NEXT_PUBLIC_SHEETMUSIC_API_URL=http://localhost:8000
```

**Archivo:** `jam-de-vientos/frontend/.env.local`
```bash
# Actualizado comentario explicativo
NEXT_PUBLIC_SHEETMUSIC_API_URL=http://localhost:8000
```

**Razón:** El navegador hace las llamadas fetch desde el host (no desde el contenedor), por lo tanto necesita `localhost:8000` que es el puerto expuesto del backend de sheet-api.

### 2. Población de Datos en Backend

**Comando ejecutado en sheet-api-backend:**
```python
from events.models import Repertoire, RepertoireVersion
from music.models import Version

repertorio_jdv = Repertoire.objects.get(id=3)  # "Jam de Vientos - Repertorio Estándar"
repertorio_jdv.is_active = True
repertorio_jdv.save()

versiones = Version.objects.filter(
    theme__title__in=['Cuarteto de Bronces', 'Coco']
)[:6]

orden = 0
for version in versiones:
    RepertoireVersion.objects.get_or_create(
        repertoire=repertorio_jdv,
        version=version,
        defaults={'order': orden}
    )
    orden += 1
```

**Resultado:**
- Se agregaron 6 versiones al repertorio "Jam de Vientos - Repertorio Estándar"
- El evento "Jam de Vientos - Edición Especial" (ID: 2) ahora devuelve datos completos

### Versiones agregadas al repertorio:
1. Coco
2. Test Version con archivos - Clarinete
3. Cuarteto de Bronces - Flauta
4. Cuarteto de Bronces - Fliscorno
5. Cuarteto de Bronces - Corno Francés
6. Cuarteto de Bronces - Tuba

## Verificación

### Antes:
```bash
curl http://localhost:8000/api/v1/jdv/events/upcoming/
# Respuesta:
{
  "repertoire": {
    "versions": [],  # Array vacío ❌
    "version_count": 0
  }
}
```

### Después:
```bash
curl http://localhost:8000/api/v1/jdv/events/upcoming/
# Respuesta:
{
  "repertoire": {
    "versions": [
      {"id": 17, "version": {"id": 62, "title": "Coco", ...}},
      {"id": 18, "version": {"id": 49, "title": "Test Version...", ...}},
      ...
    ],
    "version_count": 6  # ✅
  }
}
```

### Frontend:
- ✅ La consola del navegador muestra `[SheetMusic API] Fetching: http://localhost:8000/api/v1/jdv/events/upcoming/`
- ✅ Los datos llegan correctamente al frontend
- ✅ El carousel se renderiza con las 6 versiones
- ✅ La página sale del estado de loading

## Arquitectura - Comunicación Frontend-Backend

```
┌──────────────────────────────────────┐
│  Navegador (Browser)                 │
│  http://localhost:3001               │
│                                      │
│  fetch("http://localhost:8000/...")  │ ← Llamada desde cliente
└──────────────┬───────────────────────┘
               │
               │ (puerto 8000 expuesto)
               ▼
┌──────────────────────────────────────┐
│  Docker Host                         │
│  ┌────────────────────────────────┐  │
│  │ sheet-api-backend-1            │  │
│  │ 0.0.0.0:8000 -> 8000/tcp       │  │
│  │                                │  │
│  │ Django REST API                │  │
│  │ /api/v1/jdv/events/upcoming/   │  │
│  └────────────────────────────────┘  │
│                                      │
│  ┌────────────────────────────────┐  │
│  │ jam-de-vientos-frontend-1      │  │
│  │ 0.0.0.0:3001 -> 3000/tcp       │  │
│  │                                │  │
│  │ Next.js Dev Server             │  │
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
```

**Punto clave:** Las variables `NEXT_PUBLIC_*` se incluyen en el bundle del cliente, por lo tanto deben usar URLs accesibles desde el navegador (localhost, no service names).

## Cambios Commiteados

**Repositorio:** `nanoska/jam-de-vientos`
**Branch:** `main`
**Commit:** `1592e28b`

```
fix: configure API URL for browser-side requests

- Changed NEXT_PUBLIC_SHEETMUSIC_API_URL from backend:8000 to localhost:8000
- Browser cannot resolve docker service names, needs localhost
- Added external docker network configuration for sheet-api integration
- Updated package-lock.json dependencies
```

## Lecciones Aprendidas

1. **Variables de entorno en Next.js:**
   - `NEXT_PUBLIC_*` se compilan en el código del cliente (browser)
   - Deben usar URLs accesibles desde el navegador, no desde el contenedor
   - Para SSR/API routes de Next.js, se pueden usar service names Docker

2. **Precedencia de variables de entorno:**
   - Variables en `docker-compose.yml` > `.env.local` > `.env`
   - Siempre verificar ambos archivos al configurar

3. **Debugging de APIs:**
   - Verificar la estructura de datos devuelta por la API
   - Comprobar que los datos existen en la base de datos
   - Revisar relaciones M2M (RepertoireVersion) además de los modelos principales

4. **Logs de Docker:**
   - Usar `./scripts/logs.sh [service] -f` para ver logs en tiempo real
   - Los errores del navegador (`ERR_NAME_NOT_RESOLVED`) indican problemas de DNS/networking

## Próximos Pasos

- [ ] Agregar más versiones reales al repertorio de Jam de Vientos
- [ ] Configurar imágenes y audios para las versiones
- [ ] Verificar que los PDFs de partituras estén asociados correctamente
- [ ] Testear en producción la configuración de variables de entorno
- [ ] Documentar en CLAUDE.md la diferencia entre service names y localhost para NEXT_PUBLIC vars

## Referencias

- [Next.js Environment Variables](https://nextjs.org/docs/app/building-your-application/configuring/environment-variables)
- [Docker Networking](https://docs.docker.com/network/)
- Sheet-API JDV Endpoints: `backend/jdv/views.py`
- Frontend API Client: `frontend/lib/sheetmusic-api.ts`
