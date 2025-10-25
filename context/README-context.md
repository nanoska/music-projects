# Contexto operativo para Claude Code

Este documento define **cómo queremos que Claude Code trabaje en estos repositorios separados de proyectos musicales** y especifica reglas de interacción, arquitectura de API, criterios de diseño y lineamientos de contenedores.

---

## 0) Disposición multi‑repo (fundamental)

* **No es monorepo.** Cada app vive en su **propio repositorio** (EMPIV templates, EMPIV web, Jam de Vientos, Music Learning App, Sheet API).
* **Regla:** Claude debe **preguntar siempre** en qué repo y rama trabajar antes de proponer cambios.
* **Especificar rutas** con el **prefijo de repo** (p. ej., `sheet-api/backend/...`, `empiv-web/frontend/...`).
* **Estrategia de integraciones:** contratos entre repos se hacen vía **API/SDK versionados** (ver §4 y §11). Nada de imports directos entre repos.
* **Sin operaciones cross‑repo automáticas** (submódulos, subtree, etc.) sin autorización explícita.

---

## 1) Protocolo de interacción (muy importante)

**Antes de ejecutar o proponer cambios, Claude debe:**

1. **Pedir confirmación para cualquier comando Docker.**
2. **Baja creación de código por defecto**, consultar antes de scaffolds/refactors grandes.
3. **Cambios atómicos y trazables** (modulares, por archivo, con explicación breve y diffs/patches cuando sea posible).
4. **Plan → Confirmación → Ejecución**.
5. **Cautela con operaciones destructivas**.
6. **Estilo de respuesta**: breve y accionable; si se pide “solo código”, devolver solo código.

---

## 2) Principios de código y organización

* **Modularización estricta**: dividir en módulos/paquetes; evitar archivos de +300 líneas.
* **Imports claros**: rutas relativas cortas; centralizar tipos/constantes en `@/types`, `@/config`.
* **Componentizado** (frontend): componentes puros, estado solo donde corresponde; hooks para lógica reusable.
* **Separation of Concerns**: UI / servicios / dominio / infraestructura.
* **Convenciones**:

  * TypeScript estricto (`strict: true`).
  * Linters y formatters (ESLint + Prettier / Ruff+Black en Python) con reglas del repo.
  * Commits semánticos (convencional): `feat:`, `fix:`, `docs:`, `chore:`, etc.

---

## 3) Estructura de contenedores (criterios)

> **Claude debe *proponer* y esperar confirmación antes de crear/modificar contenedores.**

**Patrón base por repo**

* `frontend`: Node 20/22, expone 3000 (o 3001 para colisiones), monta `/app`.
* `backend`: Python 3.11/3.12, expone 8000; `gunicorn` en prod, `runserver` en dev.
* `db`: PostgreSQL 15/16 (o SQLite en dev sin contenedor).
* `cache/queue` (si aplica): Redis para Celery.
* `reverse-proxy` (si aplica): Nginx por repo o gateway común (aprobación previa).

**Integración entre repos (Docker)**

* Redes dedicadas por repo y **gateway opcional** (reverse‑proxy / API gateway) sujeto a aprobación.
* Para desarrollo local, consumir `SHEET_API_BASE_URL` por `.env` en los otros repos.

**Buenas prácticas**

* Variables en `.env` y `.env.local`; **no** commitear secretos.
* Volúmenes nombrados para `postgres` y `node_modules` si es necesario.
* Healthchecks y `depends_on` con `condition: service_healthy`.
* Una red por dominio lógico y otra compartida **solo si** se aprueba.

---

## 4) Arquitectura de la API (Sheet API como *backbone*)

La **Sheet API** es un **repo independiente** y el **servicio central** que alimenta a:

* **EMPIV** (gestión escuela: talleres/eventos/materiales),
* **Jam de Vientos** (eventos públicos y repertorios),
* **Music Learning App** (ejercicios, partituras por instrumento).

### 4.1 Contratos compartidos entre repos

* Publicar **OpenAPI (`openapi.yaml`)** en el repo de Sheet API y **taggear releases** (`v1.x`).
* Generar **SDKs** (TS/Python) opcionales y versionados para consumo en los otros repos.
* Mantener **compatibilidad retro**: rutas y esquemas no se rompen sin `deprecations` y changelog.

### 4.2 Dominio y relaciones

[contenido original de dominio y endpoints se mantiene]

*(Se preservan 4.2 → 4.6 del documento original)*

---

## 5) Criterios de calidad y DX

* **Testing**:

  * Backend: `pytest`/`unittest` con cobertura a servicios de transposición, serializadores y permisos.
  * Frontend: React Testing Library para componentes críticos.
* **Observabilidad**: logging estructurado (JSON), request-id, métricas básicas (tiempos, conteos, errores).
* **Validación de archivos**: tamaño, tipo, checksum; colas para procesamientos pesados.
* **i18n** básico en frontend (en-US/es-AR) para títulos de piezas y metadatos.
* **Accesibilidad**: roles ARIA, teclado, contraste.

---

## 6) Flujo de trabajo sugerido para Claude

1. **Entender el objetivo** (2-3 bullets con criterios de aceptación).
2. **Proponer plan de archivos** (creaciones/ediciones).
3. **Esperar confirmación** del usuario.
4. **Entregar cambios** en bloques pequeños, con diffs.
5. **Sugerir tests** mínimos y comandos **(sin ejecutarlos)**.
6. **Checklist de finalización** (build, lint, test, docs actualizadas).

**Ejemplo de respuesta corta esperada:**

> Plan: (1) Crear `sheet-api/backend/apps/scores/models.py` con modelos `Song/Version/Part` (2) Migraciones (3) Serializers y ViewSets (4) Rutas en `urls.py`. ¿Avanzo?

---

## 7) Matrices de compatibilidad y versiones (por repo)

* **Sheet API**: Python 3.11/3.12 · Django 4.2 · Postgres 15+
* **EMPIV templates**: Django 5.1
* **EMPIV web**: Front React 19 / Back Django 5.1
* **Jam de Vientos**: Next.js 14
* **Music Learning App**: React 18 + Django 4.2 (+ Redis/Celery)

> Claude debe **confirmar la matriz vigente del repo activo** antes de actualizar dependencias.

---

## 8) Rúbrica de PR/changes para Claude

* ¿El cambio cumple el objetivo en **<=5 archivos**? Si no, dividir.
* ¿Hay **tests** asociados o sugeridos?
* ¿Se actualizaron **tipos** (TS/Pydantic) y **docs**?
* ¿Se incluyó **migración** y es reversible?
* ¿Se mantuvo **retrocompatibilidad** de la API?

---

## 9) Backlog inicial (Sheet API)

* [ ] Modelos: `Instrument`, `Song`, `Version`, `Part` (+ señales de checksum)
* [ ] Modelos: `Event`, `Band`, `Musician`, `Repertoire`, `RepertoireItem`
* [ ] Serializers + ViewSets + permisos por rol
* [ ] Endpoint `POST /transpose` (stub) + cola de tareas
* [ ] Búsqueda `/search` por metadatos
* [ ] Documentación `/api/docs` con drf-spectacular
* [ ] Script de carga inicial de instrumentos (Bb/Eb/F/C)

---

## 10) Notas finales

* Claude debe **centralizar utilidades musicales** (transposición, tonos relativos, rango de instrumentos) **solo dentro del repo correspondiente**, y publicar funciones compartidas a través de la **Sheet API** o SDK/versionado, **no** como imports entre repos.
* Cualquier decisión de arquitectura que afecte a **EMPIV/Jam/MusicLearn** debe ser **consultada** antes de implementarse.

---

## 11) Estrategia multi‑repo adicional

* **Releases coordinadas**: cuando la Sheet API sube `v1.x`, los consumidores fijan `SHEET_API_BASE_URL` y, si usan SDK, actualizan a `^1.x`.
* **Changelog y deprecations**: mantener `CHANGELOG.md` por repo y sección de `Deprecated` con plazos.
* **Versionamiento de datos**: si cambian enums/catálogos (p. ej., instrumentos), proveer endpoint `/metadata` con `version` para sincronización.
* **Pruebas de contrato**: tests en consumidores que validen respuestas mínimas del OpenAPI.

---

## 12) Flujo de ramas y documentación por sesión (obligatorio)

* **Aislamiento por rama**: cada desarrollo/issue/feature **debe realizarse en su propia rama** (`feat/...`, `fix/...`, `chore/...`).
* **Convención sugerida**: `feat/<repo-corto>/<slug-corto>` (p. ej., `feat/sheetapi/transpose-endpoint`).
* **Cierre de sesión**:

  1. Documentar **lo trabajado** en `docs/sessions/YYYY-MM-DD/README.md` dentro del **repo correspondiente** (contexto, decisiones, archivos tocados, pendientes, próximos pasos).
  2. Ejecutar linters/tests.
  3. Abrir PR → revisión → **merge a rama base** (p. ej., `main`/`develop`) y **push** si está todo OK.
* **Registros mínimos en cada sesión**:

  * Objetivo, alcance y criterios de aceptación.
  * Lista de cambios por archivo (breve) y razones.
  * Comandos ejecutados (si hubo), **sin credenciales**.
  * Decisiones y deprecations.

---

## 13) Guía unificada de estilos UI/UX

**Referencia base**: estilos de **Jam de Vientos** (Next.js + Tailwind v4, Radix UI). El resto de repos deben **alinear** sus diseños a esta guía, adaptando librerías equivalentes cuando aplique.

**Principios**

* **Moderno y minimalista**: jerarquía tipográfica clara, espacios amplios, foco en legibilidad.
* **Sombras y relieves**: usar **elevación sutil** para jerarquía visual (cards, modals, botones importantes). Evitar exceso.
* **Animaciones discretas**: transiciones cortas (150–250ms) para hover/focus/entrada de vistas; micro‑interacciones en acciones clave (envío, guardar, drag‑drop). Evitar animaciones ruidosas.
* **Estados explícitos**: loading skeletons, vacíos (empty states) con call‑to‑action, errores con feedback accionable.
* **Accesibilidad**: contraste AA, foco visible, navegación por teclado.

**Librerías y patrones**

* **Jam de Vientos**: Radix UI + Tailwind v4 → **tokens** (spacing, radii, sombras) como **fuente de verdad**.
* **React/MUI repos**: mapear tokens a theme MUI (palette, elevation, motion) para convergencia visual.
* **Componentes comunes**: Card, Button, Input, Select, Modal/Sheet, Tabs, Table con densidad cómoda.

**Tokens de diseño (sugeridos)**

* **Radii**: `md: .5rem`, `lg: .75rem`, `xl: 1rem`, `2xl: 1.25rem`.
* **Sombras**: `sm`, `md`, `lg` con spread corto y blur moderado; evitar `drop-shadow` agresivo.
* **Motion**: cubic‑bezier suave; duración 150–250ms.

**Entrega visual**

* Claude debe proponer **previews** (capturas/storybook) o snapshots CSS cuando haga cambios de estilo.

---

## 14) Apéndice: Plantilla de README de sesión

```md
# Sesión YYYY-MM-DD

## Objetivo
- ...

## Cambios realizados
- Archivo A: ...
- Archivo B: ...

## Decisiones
- ...

## Comandos (si aplica)
```

---
