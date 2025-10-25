# Sesión 2025-10-24: Análisis y Documentación Sheet-API + Ecosistema

**Fecha**: 2025-10-24
**Duración**: Sesión completa de análisis
**Participantes**: Nahue (Desarrollador) + Claude Code (Asistente AI)

---

## 📋 Objetivo de la Sesión

Analizar en profundidad la arquitectura del backend **sheet-api** y su integración con las 3 aplicaciones consumidoras (**jam-de-vientos**, **music-learning-app**, **empiv-web**), documentando:

1. Modelos Django y su consistencia
2. Contratos API y endpoints
3. Lógica de transposición musical
4. Estrategias de containerización con Docker
5. Gaps y mejoras identificadas

El objetivo final es tener una documentación completa que permita push al repositorio sheet-api y facilitar el desarrollo futuro.

---

## 🎯 Alcance y Contexto

### Arquitectura del Ecosistema

El proyecto consta de **4 aplicaciones independientes**:

```
sheet-api (Backend Central Django + Frontend React Admin)
    ↓ consume (REST API)
jam-de-vientos (Frontend Next.js)

music-learning-app (Full stack independiente)
empiv-web (Full stack independiente)
```

**sheet-api** actúa como **servicio central** que provee:
- Gestión de temas musicales y sus versiones
- Catálogo de instrumentos con transposiciones
- Partituras con cálculo automático de tonalidad relativa
- Gestión de eventos y repertorios
- API pública para jam-de-vientos

---

## 📂 Documentos Generados

Esta sesión produjo **5 documentos técnicos** detallados:

### 1. `architecture-analysis.md` (6,200 palabras)

**Contenido**:
- Visión general del ecosistema multi-app
- Análisis de solidez del backend sheet-api
- Evaluación de consistencia de modelos Django
- Análisis de integración con jam-de-vientos
- Identificación de gaps y áreas de mejora
- Evaluación de arquitectura REST API
- Estado de Docker ización
- Recomendaciones priorizadas

**Puntos clave**:
- ✅ Solidez general: **8/10**
- ✅ Arquitectura relacional bien diseñada
- ⚠️ Funcionalidad de descarga de PDFs incompleta
- ⚠️ Falta documentación Docker multi-app

---

### 2. `models-final.md` (5,800 palabras)

**Contenido**:
- Documentación exhaustiva de los 7 modelos Django
- Todos los campos con tipos, constraints y descripción
- Diagramas de relaciones
- Explicación del "Formato Standard"
- Sistema de transposición con ejemplos
- Flujo completo de datos con caso real
- Mejoras propuestas con código

**Modelos documentados**:

**App `music/`**:
- `Theme` - Pieza musical original
- `Instrument` - Catálogo de instrumentos con afinaciones
- `Version` - Arreglos/versiones de un tema
- `SheetMusic` - Partitura individual con auto-transposición

**App `events/`**:
- `Location` - Locaciones de eventos
- `Repertoire` - Colección de versiones para evento
- `RepertoireVersion` - Tabla intermedia con orden
- `Event` - Eventos musicales públicos/privados

**Aclaración conceptual importante**:
- `Version.type = 'STANDARD'` → Tipo de arreglo (full band)
- `SheetMusic.type` → Rol de la partitura (MELODIA_PRINCIPAL, ARMONIA, BAJO)

---

### 3. `api-contracts.md` (6,100 palabras)

**Contenido**:
- Especificación completa de 25+ endpoints
- Schemas de request/response con ejemplos JSON reales
- Query parameters y filtros
- Códigos de estado HTTP y manejo de errores
- Endpoints públicos vs autenticados
- Endpoints propuestos (no implementados) para jam-de-vientos
- Documentación de auto-cálculo de tonalidad_relativa

**Endpoints principales**:
- `/api/v1/themes/` - CRUD de temas
- `/api/v1/instruments/` - Catálogo de instrumentos
- `/api/v1/versions/` - Versiones con sheet music anidado
- `/api/v1/sheet-music/` - Partituras con auto-transposición
- `/api/v1/events/events/` - Gestión de eventos
- `/api/v1/events/jamdevientos/carousel/` - Próximos eventos públicos (sin auth)

**Endpoints propuestos**:
- `/jamdevientos/versions/{id}/sheet-music/` - Listar PDFs disponibles
- `/jamdevientos/sheet-music/{id}/download/` - Descarga directa de PDF

---

### 4. `docker-orchestration.md` (5,400 palabras)

**Contenido**:
- 5 escenarios de trabajo documentados con comandos exactos
- Manejo de redes Docker entre aplicaciones
- Configuración de variables de entorno
- Troubleshooting de problemas comunes
- Scripts de automatización propuestos
- Gestión de volúmenes y persistencia
- Logs y debugging
- Checklist pre-commit

**Escenarios documentados**:
1. **Trabajar en jam-de-vientos** → Levantar sheet-api backend + jam frontend
2. **Trabajar en sheet-api** → Full stack (backend + frontend + db)
3. **Trabajar en music-learning-app** → Independiente con Redis
4. **Trabajar en empiv-web** → Independiente
5. **Demo completo** → Todas las apps coordinadas

**Comandos clave**:
```bash
# Escenario 1: Jam de Vientos
cd sheet-api && docker compose up -d backend db
cd ../jam-de-vientos && docker compose up -d frontend

# Escenario 2: Sheet-API Full
cd sheet-api && docker compose up -d

# Rebuild limpio
docker compose down -v && docker compose build --no-cache && docker compose up -d
```

---

### 5. `README.md` (Este documento)

Resumen ejecutivo de la sesión con índice de documentos generados.

---

## 🔍 Hallazgos Principales

### ✅ Fortalezas Identificadas

1. **Arquitectura de Modelos Sólida**
   - Relaciones FK y M2M bien diseñadas
   - Constraints apropiados (unique_together)
   - Validaciones a nivel de modelo (Event.clean())
   - Timestamps automáticos en todos los modelos

2. **Sistema de Transposición Robusto**
   - Lógica matemática correcta en `music/utils.py`
   - Mapeo de 24 tonalidades a semitonos
   - Transposición automática en ViewSet
   - Preserva modo mayor/menor

3. **API RESTful Bien Diseñada**
   - Versionado (`/api/v1/`)
   - Filtros y búsqueda en todos los endpoints
   - Paginación (20 items/página)
   - Serializers optimizados (List vs Detail)

4. **Separación de Responsabilidades**
   - Apps Django claramente delimitadas (music/, events/)
   - JamDeVientosViewSet especializado para público
   - Permisos granulares (IsAuthenticated, IsAdminUser)

### ⚠️ Áreas de Mejora Detectadas

1. **Gap Crítico: Descarga de PDFs en jam-de-vientos**
   - **Problema**: Frontend tiene UI completa pero no conectada a backend
   - **Código**: `SongDetails.tsx` línea 61 tiene `TODO: Load files from SheetMusic API`
   - **Impacto**: Funcionalidad core faltante
   - **Solución**: Implementar endpoints propuestos en `api-contracts.md` sección 6

2. **Campo Calculado No Protegido**
   - **Problema**: `tonalidad_relativa` es auto-calculado pero editable por cliente
   - **Riesgo**: Cliente podría sobrescribir cálculo automático
   - **Solución**: Marcar como `read_only=True` en SheetMusicSerializer

3. **Falta Campo `default_clef` en Instrument**
   - **Problema**: La clave está en SheetMusic pero es característica del instrumento
   - **Riesgo**: Posible inconsistencia (tuba en clave de SOL por error humano)
   - **Solución**: Agregar campo y migración

4. **Falta Validación de Archivos**
   - **Problema**: No hay validators de tamaño, tipo MIME o checksum
   - **Riesgo**: Archivos corruptos o maliciosos
   - **Solución**: FileExtensionValidator + FileSizeValidator

5. **Documentación Docker Incompleta**
   - **Problema**: No está documentado cómo levantar apps con dependencias
   - **Impacto**: Errores crípticos, pérdida de tiempo
   - **Solución**: `docker-orchestration.md` (completado en esta sesión)

---

## 📊 Análisis del "Formato Standard"

### Concepto Aclarado

**Malentendido inicial**: "Formato Standard" es un formato de archivo.

**Realidad**: Es una **convención de arreglo musical**:

| Campo | Valor | Significado |
|-------|-------|-------------|
| `Version.type` | `'STANDARD'` | Arreglo completo para banda de vientos |
| `SheetMusic.type` | `'MELODIA_PRINCIPAL'` | Línea melódica principal |
| `SheetMusic.type` | `'MELODIA_SECUNDARIA'` | Segunda voz melódica |
| `SheetMusic.type` | `'ARMONIA'` | Acompañamiento armónico |
| `SheetMusic.type` | `'BAJO'` | Línea de bajo |

### Ejemplo Real: "One Step Beyond" (Madness)

```
Theme: One Step Beyond
├── tonalidad: Cm (concert pitch)
│
└── Version: type='STANDARD'
    ├── SheetMusic: Trompeta Bb + MELODIA_PRINCIPAL → tonalidad_relativa: Dm
    ├── SheetMusic: Saxo Alto Eb + MELODIA_PRINCIPAL → tonalidad_relativa: Am
    ├── SheetMusic: Trompeta Bb + ARMONIA → tonalidad_relativa: Dm
    └── SheetMusic: Tuba C + BAJO (clave FA) → tonalidad_relativa: Cm
```

**Matemática de Transposición**:
- Cm = 0 semitonos (menor)
- Bb = +2 semitonos → (0 + 2) % 12 = 2 → D → preserva menor → **Dm**
- Eb = +9 semitonos → (0 + 9) % 12 = 9 → A → preserva menor → **Am**
- C = 0 semitonos → sin transposición → **Cm**

---

## 🔗 Integración jam-de-vientos ↔ sheet-api

### Estado Actual

**Funcionando ✅**:
- Carousel de eventos próximos
- Detalle de evento con repertorio
- Audio y metadata de versiones

**Pendiente ⚠️**:
- Descarga de partituras por instrumento
- Filtrado por afinación (Bb, Eb, C, F)
- Filtrado por tipo (Melodía, Armonía, Bajo)

### Flujo Usuario Final (Completo)

```
1. Usuario entra a jam-de-vientos.com
   └─> GET /jamdevientos/carousel/

2. Ve carousel con temas del próximo evento
   └─> Click en "One Step Beyond"

3. Abre SongDetails con selectors:
   - Instrumento: [Bb] [Eb] [C] [F] [Clave de Fa]
   - Tipo: [Melodía] [Armonía] [Bajo]

4. Selecciona "Bb" + "Melodía"
   └─> Frontend busca en available_parts['Bb_MELODIA_PRINCIPAL']

5. Si existe → Botón "Descargar PDF" habilitado
   └─> GET /jamdevientos/sheet-music/1/download/
   └─> Descarga: One_Step_Beyond_Trompeta_Bb_Melodía_Principal.pdf
```

### Implementación Pendiente

Ver `api-contracts.md` sección 6 con código completo de backend y frontend.

---

## 🐳 Docker: Estrategias por Escenario

### Escenario Común: Trabajar en jam-de-vientos

```bash
# Terminal 1: Sheet-API backend (dependencia)
cd sheet-api
docker compose up -d backend db

# Terminal 2: Jam de Vientos frontend
cd ../jam-de-vientos
# Configurar .env.local con NEXT_PUBLIC_SHEETMUSIC_API_URL=http://backend:8000
docker compose up -d frontend

# Acceso:
# - Jam de Vientos: http://localhost:3001
# - Sheet-API Admin: http://localhost:8000/admin
```

### Problemas Comunes y Soluciones

| Error | Causa | Solución |
|-------|-------|----------|
| `ECONNREFUSED backend:8000` | sheet-api backend no corriendo | `cd sheet-api && docker compose up -d backend` |
| `Network not found` | Red Docker no existe | `docker network create sheetmusic_sheetmusic-network` |
| `Port 8000 already allocated` | Otro servicio usando puerto | `lsof -i :8000` y `kill -9 <PID>` |
| `ModuleNotFoundError` | Dependencias no instaladas | `docker compose build --no-cache backend` |

---

## 🚀 Recomendaciones Prioritarias

### Prioridad Alta (Implementar ya)

1. **Implementar descarga de PDFs en jam-de-vientos**
   - Tiempo estimado: 4 horas
   - Impacto: Alto (funcionalidad core faltante)
   - Documentación completa en `api-contracts.md` sección 6

2. **Documentar flujo Docker en README**
   - Tiempo estimado: 1 hora
   - Impacto: Alto (usabilidad)
   - Ya documentado en `docker-orchestration.md`, copiar a READMEs individuales

### Prioridad Media (Siguiente sesión)

3. **Agregar `default_clef` a Instrument**
   - Tiempo estimado: 1 hora (migración + tests)
   - Impacto: Medio (previene errores)

4. **Marcar `tonalidad_relativa` como read_only**
   - Tiempo estimado: 15 minutos
   - Impacto: Medio (prevención de bugs)

5. **Agregar `is_visible` a SheetMusic**
   - Tiempo estimado: 1 hora
   - Impacto: Medio (control granular)

### Prioridad Baja (Backlog)

6. **Validadores de archivos**
   - Tiempo estimado: 3 horas
   - Impacto: Bajo (seguridad)

7. **Rate limiting en API**
   - Tiempo estimado: 2 horas
   - Impacto: Bajo (solo producción)

---

## 📝 Decisiones Tomadas

### 1. Modelos: No Requieren Cambios Estructurales

**Conclusión**: La estructura actual de modelos es sólida y consistente.

**Acción**: Documentar completamente antes de modificar.

### 2. "Formato Standard": Aclaración Conceptual, No Técnica

**Decisión**: No es un formato de archivo, sino una convención de arreglo musical definida por:
- `Version.type = 'STANDARD'`
- `SheetMusic.type` en {'MELODIA_PRINCIPAL', 'MELODIA_SECUNDARIA', 'ARMONIA', 'BAJO'}

### 3. Docker: Documentar, No Centralizar

**Decisión**: No crear docker-compose maestro centralizado.

**Razón**: Mayor complejidad sin beneficio real para desarrollo.

**Acción**: Documentar escenarios en `docker-orchestration.md` y crear scripts de automatización.

### 4. Renombrado "sheetmusic" → "sheet-api": Solo Cosmético

**Decisión**: No renombrar modelos Django ni endpoints API.

**Acción**: Solo actualizar branding en documentación y README.

---

## 📦 Entregables Listos para Push

### Carpeta `sessions/2025-10-24/`

- ✅ `README.md` (este archivo)
- ✅ `architecture-analysis.md`
- ✅ `models-final.md`
- ✅ `api-contracts.md`
- ✅ `docker-orchestration.md`

**Total**: ~23,500 palabras de documentación técnica detallada.

### Próximo Paso: Actualizar README de sheet-api

Incorporar secciones clave de:
- `models-final.md` → Sección "Models"
- `api-contracts.md` → Sección "API Endpoints"
- `docker-orchestration.md` → Sección "Docker"

---

## 🔄 Próximos Pasos (Siguiente Sesión)

### Inmediatos

1. **Actualizar `sheet-api/README.md`**
   - Agregar diagrama completo de modelos
   - Documentar transposición con ejemplos
   - Agregar guía Docker

2. **Crear `docker/README.md` en root**
   - Copiar contenido de `docker-orchestration.md`
   - Agregar scripts de automatización

3. **Commit y Push a repo sheet-api**
   - Branch: `docs/complete-documentation`
   - Commit message: `docs: add comprehensive architecture and API documentation`

### Desarrollo

4. **Implementar endpoints de descarga de PDFs**
   - Backend: `JamDeVientosViewSet.sheet_music_list()` y `.download_sheet_music()`
   - Frontend: Conectar `SongDetails.tsx` con API
   - Tests de integración

5. **Refinar modelo Instrument**
   - Agregar campo `default_clef`
   - Crear migración
   - Actualizar `get_clef_for_instrument()` para usar DB

---

## 🎓 Aprendizajes Clave

### 1. Importancia de la Documentación Previa

Documentar antes de modificar código permite:
- Entender el diseño actual y sus razones
- Identificar gaps vs. features faltantes
- Planificar cambios sin breaking changes

### 2. Transposición Musical en Software

La lógica matemática de transposición es:
- Más simple de lo que parece (aritmética modular 12)
- Crítica para la experiencia del usuario (músicos)
- Requiere preservar modo mayor/menor

### 3. Docker Multi-Aplicación

Levantar apps con dependencias requiere:
- Documentación clara del orden
- Gestión explícita de redes Docker
- Scripts de automatización para evitar errores

---

## 📊 Métricas de la Sesión

- **Documentos generados**: 5
- **Palabras escritas**: ~23,500
- **Modelos analizados**: 7
- **Endpoints documentados**: 25+
- **Escenarios Docker**: 5
- **Gaps identificados**: 5
- **Mejoras propuestas**: 7
- **Tiempo estimado de implementación mejoras alta prioridad**: ~6 horas

---

## ✅ Checklist de Sesión Completada

- [x] Analizar modelos Django de sheet-api
- [x] Documentar relaciones y constraints
- [x] Explicar lógica de transposición
- [x] Aclarar concepto "Formato Standard"
- [x] Documentar endpoints API completos
- [x] Identificar gap de descarga de PDFs
- [x] Proponer solución con código
- [x] Documentar estrategias Docker por escenario
- [x] Crear README de sesión
- [x] Preparar contenido para push a repo

---

## 📌 Notas Adicionales

### Branding "sheet-api"

El proyecto fue renombrado de "sheetmusic" a "sheet-api" pero solo cosméticamente:
- ✅ Renombrado: Repo GitHub, documentación
- ❌ No renombrado: Modelos Django (SheetMusic), endpoints (`/sheet-music/`)

**Razón**: Evitar breaking changes en API y migración de datos.

### Convenciones de Nomenclatura

- **Theme**: Pieza musical original (canción, tema)
- **Version**: Arreglo específico de un theme (Standard, Ensamble, Dueto)
- **SheetMusic**: Partitura individual para un instrumento en una version
- **Repertoire**: Colección de versions para un evento

---

## 🤝 Contribuidores de la Sesión

**Nahue** (Desarrollador):
- Contexto del proyecto y arquitectura
- Aclaraciones sobre "Formato Standard"
- Decisiones sobre prioridades
- Conocimiento musical (transposiciones, claves)

**Claude Code** (Asistente AI):
- Análisis exhaustivo del código existente
- Documentación técnica detallada
- Identificación de gaps y propuestas de solución
- Estructuración de información

---

## 📚 Referencias Útiles

**Archivos clave para consultar**:
- `sheet-api/backend/music/models.py` - Modelos Django
- `sheet-api/backend/music/utils.py` - Lógica de transposición
- `sheet-api/backend/music/views.py` - ViewSets con auto-cálculo
- `jam-de-vientos/frontend/lib/sheetmusic-api.ts` - Cliente API
- `jam-de-vientos/frontend/components/song-details.tsx` - UI de descarga

**Documentos de esta sesión**:
- `architecture-analysis.md` - Análisis completo de arquitectura
- `models-final.md` - Especificación de modelos
- `api-contracts.md` - Contratos API con ejemplos
- `docker-orchestration.md` - Guías Docker

---

**Sesión finalizada**: 2025-10-24
**Estado**: ✅ Completada
**Próxima sesión**: Implementación de mejoras priorizadas

---

*Generado automáticamente por Claude Code el 2025-10-24*
