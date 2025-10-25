# music-projects

Repositorio de documentación y orquestación Docker para el ecosistema de proyectos musicales.

## 📋 Contenido

Este repositorio contiene:

- **📚 Documentación técnica completa** de arquitectura y modelos
- **🐳 Guías de orquestación Docker** para desarrollo multi-aplicación
- **📝 Sesiones de trabajo** con análisis detallados
- **⚙️ Configuración centralizada** y mejores prácticas

## 🎯 Proyectos del Ecosistema

Los siguientes proyectos tienen sus propios repositorios:

| Proyecto | Descripción | Repositorio |
|----------|-------------|-------------|
| **sheet-api** | Backend central Django + Frontend React para gestión de partituras | [nanoska/sheet-api](https://github.com/nanoska/sheet-api) |
| **jam-de-vientos** | Aplicación Next.js para eventos públicos y partituras | [nanoska/jam-de-vientos](https://github.com/nanoska/jam-de-vientos) |
| **music-learning-app** | Plataforma de aprendizaje musical gamificado | [TBD] |
| **empiv-web** | Sistema de gestión de escuela de música | [TBD] |

## 📖 Documentación Disponible

### Sesión 2025-10-24: Análisis Completo

- **[README.md](sessions/2025-10-24/README.md)** - Resumen ejecutivo de la sesión
- **[architecture-analysis.md](sessions/2025-10-24/architecture-analysis.md)** - Análisis de arquitectura y solidez (8/10)
- **[models-final.md](sessions/2025-10-24/models-final.md)** - Especificación de 7 modelos Django
- **[api-contracts.md](sessions/2025-10-24/api-contracts.md)** - Contratos API con 25+ endpoints
- **[docker-orchestration.md](sessions/2025-10-24/docker-orchestration.md)** - Guías Docker para 5 escenarios

### Guías de Desarrollo

- **[docker/README.md](docker/README.md)** - Orquestación Docker práctica
- **[CLAUDE.md](CLAUDE.md)** - Instrucciones para Claude Code
- **[context/README-context.md](context/README-context.md)** - Contexto operativo

## 🚀 Quick Start

### Clonar Proyecto Individual

Cada proyecto tiene su propio repositorio:

```bash
# Sheet-API (backend central)
git clone https://github.com/nanoska/sheet-api.git

# Jam de Vientos (frontend Next.js)
git clone https://github.com/nanoska/jam-de-vientos.git
```

### Levantar con Docker

Ver [docker/README.md](docker/README.md) para guías detalladas por escenario.

**Ejemplo: Trabajar en jam-de-vientos**
```bash
# Terminal 1: Sheet-API backend
cd sheet-api && docker compose up -d backend db

# Terminal 2: Jam de Vientos frontend
cd jam-de-vientos && docker compose up -d frontend
```

## 🏗️ Arquitectura

```
sheet-api (Backend Central Django + React Admin)
    ↓ REST API (/api/v1/)
jam-de-vientos (Next.js - Eventos Públicos)

music-learning-app (Independiente)
empiv-web (Independiente)
```

## 📊 Métricas de Documentación

- **Total de documentos**: 7 archivos markdown
- **Líneas de documentación**: 5,691
- **Tamaño total**: 148 KB
- **Modelos documentados**: 7 (Django)
- **Endpoints API**: 25+
- **Escenarios Docker**: 5

## 🛠️ Stack Tecnológico

### Frontend
- React 19 + TypeScript
- Next.js 14
- Tailwind CSS v4
- Material-UI (dark theme)

### Backend
- Django 4.2/5.1
- Django REST Framework
- PostgreSQL 15
- JWT Authentication

### DevOps
- Docker + Docker Compose
- Nginx (reverse proxy)
- Redis (Celery - music-learning-app)

## 📚 Características Principales

### sheet-api
- 🎵 Gestión de temas musicales y versiones
- 🎺 Transposición automática de instrumentos (Bb, Eb, F, C)
- 📄 Partituras con cálculo de tonalidad relativa
- 📅 Gestión de eventos y repertorios
- 🔓 API pública para jam-de-vientos

### Sistema de Transposición
```
Tema: "One Step Beyond" (Cm - concert pitch)
├─ Trompeta Bb → Lee en Dm (Cm + 2 semitonos)
├─ Saxo Alto Eb → Lee en Am (Cm + 9 semitonos)
└─ Tuba C → Lee en Cm (sin transposición)
```

## 🤝 Contribuir

1. Clonar el proyecto específico
2. Crear branch: `git checkout -b feat/nueva-funcionalidad`
3. Commit: `git commit -m "feat: descripción"`
4. Push: `git push origin feat/nueva-funcionalidad`
5. Abrir Pull Request

## 📄 Licencia

[Especificar licencia]

## 👥 Autor

**Nahue** - Desarrollo principal

---

*Para documentación técnica detallada, ver [sessions/2025-10-24/](sessions/2025-10-24/)*
