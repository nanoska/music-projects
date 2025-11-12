# Sesión de Trabajo: Producción Jam de Vientos + Sheet API

**Fecha**: 2025-11-02
**Objetivo**: Planificación completa para poner en producción jam-de-vientos con integración a sheet-api
**Estado**: 📝 Planificación completada

---

## Resumen Ejecutivo

Esta sesión documenta la planificación completa para llevar a producción el ecosistema de aplicaciones musicales, específicamente:

- **Jam de Vientos**: Sitio web público para visualizar eventos y repertorios musicales
- **Sheet-API**: Sistema backend de gestión de partituras y eventos (fuente única de verdad)

### Decisiones Clave

| Aspecto | Decisión |
|---------|----------|
| **Funcionalidad Jam** | Solo lectura por ahora (CRUD desde Sheet-API) |
| **Autenticación** | JWT compartido (preparado para implementación futura) |
| **Base de Datos** | PostgreSQL compartida, gestionada por Sheet-API |
| **Comunicación** | Solo vía API REST |
| **Despliegue** | Docker Compose en VPS |
| **Dashboard Admin** | Preservar código para implementación futura |

---

## Documentos de la Sesión

### 📋 [Plan de Producción Completo](./plan-produccion.md)

**Contenido**: Plan detallado para producción v1.0 y extensión v2.0
- Análisis del ecosistema actual (todas las apps)
- Arquitectura detallada de Sheet-API y Jam de Vientos
- Plan de implementación en **10 fases** (8 para v1.0, 2 para v2.0)
- Configuraciones Docker y Nginx
- Scripts de deployment
- Workflow de Git con branches
- Cronograma estimado (v1.0: 17-23h, v2.0: 20-28h)
- Consideraciones de seguridad
- Roadmap post-producción

**Secciones principales**:
1. Análisis del Ecosistema Actual
2. Arquitectura Actual (modelos, endpoints, integración)
3. Decisiones de Arquitectura para Producción
4. Plan de Implementación por Fases (10 fases)
5. Workflow de Git
6. Reutilización de Componentes y Librerías
7. Cronograma Estimado (v1.0 + v2.0)
8. Consideraciones de Seguridad
9. Próximos Pasos (Post-Producción)
10. Recursos y Referencias

### 🚀 [Roadmap Jam de Vientos v2.0](./roadmap-jam-vientos-v2.md)

**Contenido**: Especificaciones técnicas completas para v2.0
- Visión general de la plataforma multi-evento
- Arquitectura de URLs dinámicas con slugs
- Diseño detallado de página portada
- Especificación completa del lector de partituras avanzado
- Stack tecnológico adicional (PDF.js, FullCalendar, Web Audio API)
- Endpoints API necesarios
- Plan de implementación detallado por fase
- Consideraciones técnicas y de performance
- Ejemplos de código para cada feature

**Secciones principales**:
1. Visión General (transformación a plataforma completa)
2. Arquitectura de URLs Dinámicas
3. Página Portada (hero, calendario, galería, sobre nosotros)
4. Lector de Partituras Avanzado (6 sub-features)
5. Stack Tecnológico Adicional
6. Endpoints API Necesarios
7. Plan de Implementación (FASE 9 y 10)
8. Consideraciones Técnicas
9. Cronograma y Recursos (~55h adicionales)

---

## Fases del Plan de Implementación

### ✅ FASE 1: Preparación y Documentación
- Crear análisis completo del ecosistema
- Documentar arquitectura actual
- Crear plan detallado de producción
- Documentar integración API

**Estado**: ✅ Completada
**Rama Git**: `feature/production-setup-documentation`

---

### ⏳ FASE 2: Preservación del Dashboard Admin
- Mover código del dashboard admin a `/admin-dashboard-future/`
- Crear documentación de reactivación futura
- Preservar funcionalidades de edición

**Estado**: ⏳ Pendiente
**Rama Git**: `feature/preserve-admin-dashboard`
**Duración estimada**: 1 hora

---

### ⏳ FASE 3: Configuración de Producción - Sheet-API
- Variables de entorno para producción
- Settings.py optimizado
- Dockerfile.prod multi-stage
- Nginx configuration

**Estado**: ⏳ Pendiente
**Rama Git**: `feature/sheet-api-production-config`
**Duración estimada**: 2-3 horas

---

### ⏳ FASE 4: Configuración de Producción - Jam de Vientos
- Variables de entorno
- Next.js config para producción
- Dockerfile.prod optimizado
- Nginx configuration

**Estado**: ⏳ Pendiente
**Rama Git**: `feature/jam-vientos-production-config`
**Duración estimada**: 2-3 horas

---

### ⏳ FASE 5: Docker Compose para Producción
- `docker-compose.production.yml` completo
- Configuración de servicios (db, backends, frontends, nginx-proxy)
- Networking y volúmenes
- Certbot para SSL

**Estado**: ⏳ Pendiente
**Rama Git**: `feature/docker-compose-production`
**Duración estimada**: 3-4 horas

---

### ⏳ FASE 6: Scripts de Deployment
- `deploy.sh` (deployment automatizado)
- `backup.sh` (backups de DB y media)
- `restore.sh` (restauración)
- `logs.sh` (visualización de logs)

**Estado**: ⏳ Pendiente
**Rama Git**: `feature/deployment-scripts`
**Duración estimada**: 2 horas

---

### ⏳ FASE 7: Documentación de Deployment
- Guía de instalación en VPS
- Guía de mantenimiento
- Troubleshooting
- README principal actualizado

**Estado**: ⏳ Pendiente
**Rama Git**: `feature/deployment-documentation`
**Duración estimada**: 2-3 horas

---

### ⏳ FASE 8: Testing y Validación
- Testing local completo
- Checklist pre-producción
- Testing de producción
- Validación con usuarios

**Estado**: ⏳ Pendiente
**Rama Git**: `feature/production-testing`
**Duración estimada**: 3-4 horas

---

## Fases v2.0 (Post-Producción)

### ⏳ FASE 9: Multi-Evento y Portada
- Implementar generación de slugs en backend
- Crear portada profesional con hero section
- Integrar FullCalendar para calendario interactivo
- Crear sección "Sobre Nosotros"
- Implementar galería de fotos (PhotoSwipe)
- Dynamic routes: `jamdevientos.com/{evento-slug}`
- Metadata dinámica para SEO

**Estado**: ⏳ Post-v1.0
**Rama Git**: `feature/multi-event-architecture`
**Duración estimada**: 8-12 horas

**Entregable**: Sitio multi-evento con portada institucional

---

### ⏳ FASE 10: Lector de Partituras Avanzado
- Visor PDF con react-pdf + PDF.js
- Control de tempo (0.5x - 2.0x) preservando pitch
- Metrónomo integrado con beat visual
- Scrolling automático sincronizado con audio
- Modo performance (fullscreen, wake lock)
- Optimización para iOS y Android

**Estado**: ⏳ Post-v1.0
**Rama Git**: `feature/advanced-sheet-music-reader`
**Duración estimada**: 12-16 horas

**Entregable**: Herramienta profesional de lectura de partituras para músicos

---

## Arquitectura de Servicios

```
┌─────────────────────────────────────────────────────────────┐
│                         Internet                            │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
         ┌──────────────┐
         │ Nginx Proxy  │  (SSL/TLS, reverse proxy)
         │   (Port 80)  │
         │  (Port 443)  │
         └──────┬───────┘
                │
       ┌────────┼────────────────┐
       │        │                │
       ▼        ▼                ▼
  ┌─────────┐ ┌──────────┐ ┌──────────────┐
  │ Jam de  │ │ Sheet-API│ │  Sheet-API   │
  │ Vientos │ │  Admin   │ │   Backend    │
  │(Next.js)│ │ (React)  │ │   (Django)   │
  └────┬────┘ └────┬─────┘ └──────┬───────┘
       │           │               │
       │           │               │
       └───────────┴───────────────┤
                                   │
                                   ▼
                            ┌──────────────┐
                            │  PostgreSQL  │
                            │  (Database)  │
                            └──────────────┘
```

---

## Stack Tecnológico

### Backend (Sheet-API)
- **Framework**: Django 4.2
- **API**: Django REST Framework
- **Database**: PostgreSQL 15
- **Auth**: JWT (djangorestframework-simplejwt)
- **Server**: Gunicorn
- **Features**: Transposición automática, gestión de eventos

### Frontend Público (Jam de Vientos)
- **Framework**: Next.js 14 (App Router)
- **Language**: TypeScript
- **UI**: Radix UI + shadcn/ui
- **Styling**: Tailwind CSS v4
- **Carousel**: Embla Carousel

### Frontend Admin (Sheet-API)
- **Framework**: React 19
- **Language**: TypeScript
- **UI**: Material-UI (dark theme)
- **State**: Context API + Axios

### DevOps
- **Containerization**: Docker + Docker Compose
- **Reverse Proxy**: Nginx
- **SSL**: Let's Encrypt (Certbot)
- **Deployment**: VPS con Docker Compose

---

## Flujo de Datos

### Visualización Pública (Jam de Vientos)
```
Usuario → Jam de Vientos Frontend → Sheet-API Backend → PostgreSQL
                                     (GET /jamdevientos/*)
```

### Gestión Administrativa
```
Admin → Sheet-API Admin → Sheet-API Backend → PostgreSQL
                          (JWT Auth)
                          (CRUD completo)
```

---

## Endpoints API Clave

### Públicos (sin autenticación)
```
GET  /api/v1/events/jamdevientos/carousel/      # Próximos 10 eventos
GET  /api/v1/events/jamdevientos/upcoming/      # Eventos futuros
GET  /api/v1/events/jamdevientos/{id}/          # Detalle de evento
GET  /api/v1/events/jamdevientos/{id}/repertoire/ # Repertorio completo
```

### Protegidos (requieren JWT)
```
POST   /api/token/                              # Login
POST   /api/token/refresh/                      # Refresh token
PATCH  /api/v1/versions/{id}/                   # Editar versión
GET    /api/v1/events/                          # Listar todos los eventos
POST   /api/v1/events/                          # Crear evento
```

---

## Próximos Pasos

### v1.0: Producción Básica (1 semana)
1. ✅ Completar documentación (FASE 1) - **Completado**
2. ⏳ Preservar dashboard admin (FASE 2) - 1h
3. ⏳ Configurar Sheet-API para producción (FASE 3) - 2-3h
4. ⏳ Configurar Jam de Vientos para producción (FASE 4) - 2-3h
5. ⏳ Crear Docker Compose producción (FASE 5) - 3-4h
6. ⏳ Crear scripts de deployment (FASE 6) - 2h
7. ⏳ Completar documentación deployment (FASE 7) - 2-3h
8. ⏳ Testing completo (FASE 8) - 3-4h

**Total**: 17-23 horas
**Entregable**: Jam de Vientos v1.0 en producción (solo lectura, evento único)

### v2.0: Plataforma Multi-Evento (4-6 semanas)

#### FASE 9: Multi-Evento y Portada (8-12h)
- ⏳ Implementar slugs y EventPhoto model en backend
- ⏳ Crear portada con hero section y próximo evento destacado
- ⏳ Integrar FullCalendar para calendario interactivo
- ⏳ Crear sección "Sobre Nosotros" institucional
- ⏳ Implementar galería de fotos con PhotoSwipe
- ⏳ URLs dinámicas SEO-friendly: `jamdevientos.com/{slug-evento}`

**Entregable**: Sitio multi-evento con portada profesional

#### FASE 10: Lector de Partituras Avanzado (12-16h)
- ⏳ Visor PDF de alta calidad (react-pdf + PDF.js)
- ⏳ Control de tempo (0.5x - 2.0x) con Web Audio API
- ⏳ Metrónomo integrado con click audible y beat visual
- ⏳ Scrolling automático sincronizado con audio
- ⏳ Modo performance (fullscreen, wake lock, no-sleep)
- ⏳ Optimización para móviles (iOS Safari, Android Chrome)

**Entregable**: Herramienta profesional para músicos

**Total v2.0**: 20-28 horas

### v2.1+: Visión Futura
- Implementar autenticación JWT en Jam de Vientos
- Reactivar dashboard admin con edición desde jam-de-vientos
- Anotaciones en partituras (dibujar, notas de texto)
- Loop de secciones para práctica
- Compartir partituras por WhatsApp/email
- Analytics y monitoreo (Google Analytics o Plausible)
- PWA (installable app)
- SEO avanzado con sitemap y structured data
- Multilenguaje (i18n)

---

## Recursos

### Documentación Técnica
- [Plan de Producción Completo v1.0 + v2.0](./plan-produccion.md) - **Leer primero** (10 fases)
- [Roadmap Jam de Vientos v2.0](./roadmap-jam-vientos-v2.md) - **Especificaciones técnicas detalladas**
- [Sheet-API CLAUDE.md](../sheet-api/CLAUDE.md)
- [Jam de Vientos CLAUDE.md](../jam-de-vientos/CLAUDE.md)
- [Music-Projects CLAUDE.md](../CLAUDE.md)

### Referencias Externas
- [Next.js Deployment](https://nextjs.org/docs/deployment)
- [Django Deployment Checklist](https://docs.djangoproject.com/en/4.2/howto/deployment/checklist/)
- [Docker Compose Production](https://docs.docker.com/compose/production/)
- [Let's Encrypt Docs](https://letsencrypt.org/docs/)

---

## Contacto y Soporte

Para dudas o problemas durante la implementación:
1. Revisar el [Plan de Producción](./plan-produccion.md)
2. Consultar sección de Troubleshooting (cuando esté disponible)
3. Revisar logs con `./logs.sh [servicio]`

---

**Última actualización**: 2025-11-02
**Versión**: 1.0
**Autor**: Claude Code
**Estado del proyecto**: 📝 Planificación completada - Listo para implementación
