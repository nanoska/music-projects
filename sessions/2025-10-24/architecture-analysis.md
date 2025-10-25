# Análisis de Arquitectura: Sheet-API + Aplicaciones Consumidoras

**Fecha**: 2025-10-24
**Analista**: Claude Code
**Objetivo**: Evaluar la consistencia y solidez del backend sheet-api y su integración con las aplicaciones consumidoras

---

## 1. Visión General del Ecosistema

### 1.1 Arquitectura Multi-Aplicación

El ecosistema consta de **4 aplicaciones independientes** con sheet-api como servicio central:

```
┌─────────────────────────────────────────────────────────────┐
│                      SHEET-API (Backend Central)            │
│  Django 4.2 + DRF + PostgreSQL/SQLite                      │
│  - Gestión de partituras, temas, versiones                 │
│  - Sistema de transposición automática                     │
│  - Gestión de eventos y repertorios                        │
└────────────────────┬───────────────────────────────────────┘
                     │
        ┌────────────┼────────────┬──────────────┐
        │            │            │              │
        ▼            ▼            ▼              ▼
┌──────────────┐ ┌─────────┐ ┌──────────┐ ┌──────────────┐
│ sheet-api    │ │ jam-de- │ │ music-   │ │ empiv-web    │
│ /frontend    │ │ vientos │ │ learning │ │ (React)      │
│ (Admin)      │ │ (Next.js│ │ -app     │ │              │
│              │ │  14)    │ │ (React)  │ │              │
└──────────────┘ └─────────┘ └──────────┘ └──────────────┘
```

### 1.2 Relación de Dependencias

| Aplicación | Depende de sheet-api | Uso Principal |
|------------|---------------------|---------------|
| **sheet-api/frontend** | ✅ Sí (mismo repo) | Admin dashboard para gestión completa |
| **jam-de-vientos** | ✅ Sí (externo) | Eventos públicos, descarga de partituras |
| **music-learning-app** | ❌ No (independiente) | Ejercicios musicales, aprendizaje gamificado |
| **empiv-web** | ❌ No (independiente) | Gestión escuela de música |

---

## 2. Análisis del Backend sheet-api

### 2.1 Stack Tecnológico

- **Framework**: Django 4.2
- **API**: Django REST Framework (DRF)
- **Base de Datos**: PostgreSQL (producción) / SQLite (desarrollo)
- **Autenticación**: JWT (SimpleJWT)
- **Documentación**: drf-yasg (Swagger/ReDoc)
- **Almacenamiento**: Sistema de archivos local (media/)

### 2.2 Arquitectura de Aplicaciones Django

El backend se divide en **2 apps Django principales**:

#### **App `music/`** (Core)
Gestiona el dominio musical principal: temas, versiones, instrumentos y partituras.

**Responsabilidades**:
- CRUD de temas musicales
- Gestión de versiones/arreglos
- Catálogo de instrumentos con afinaciones
- Archivos de partituras con transposición automática
- Lógica de cálculo tonal (utils.py)

#### **App `events/`**
Gestiona eventos, locaciones y repertorios para presentaciones públicas.

**Responsabilidades**:
- CRUD de eventos con fechas y locaciones
- Gestión de repertorios (colecciones de versiones)
- Relación Many-to-Many con ordenamiento (RepertoireVersion)
- Validaciones temporales (fechas coherentes)
- Endpoints especializados para jam-de-vientos (JamDeVientosViewSet)

### 2.3 Evaluación de Consistencia

#### ✅ Puntos Fuertes

1. **Separación clara de responsabilidades**: Apps music/ y events/ tienen fronteras bien definidas
2. **Modelo relacional sólido**: Las FK y M2M están bien estructuradas
3. **Sistema de transposición robusto**: La lógica en `music/utils.py` es matemáticamente correcta
4. **Constraints apropiados**: unique_together evita duplicados (version + instrument + type)
5. **Validaciones a nivel de modelo**: Event.clean() valida fechas coherentes
6. **Timestamps automáticos**: created_at/updated_at en todos los modelos
7. **Soft deletes**: Repertoire usa is_active para borrado lógico

#### ⚠️ Áreas de Mejora Detectadas

1. **Clef no está en Instrument**:
   - **Problema**: La clave (SOL/FA) se elige por partitura, pero es una característica del instrumento
   - **Impacto**: Posible inconsistencia si se sube tuba en clave de SOL por error
   - **Solución propuesta**: Agregar campo `default_clef` al modelo Instrument

2. **Falta validación de archivos subidos**:
   - **Problema**: No hay validación de tamaño, tipo MIME o checksum
   - **Riesgo**: Posibles archivos corruptos o maliciosos
   - **Solución propuesta**: Validators en FileField y signals post_save

3. **tonalidad_relativa no es read-only en API**:
   - **Problema**: Es un campo calculado pero el serializer lo permite escribir
   - **Riesgo**: Cliente podría sobrescribir el cálculo automático
   - **Solución propuesta**: Marcar como `read_only=True` en SheetMusicSerializer

4. **Falta campo is_visible en SheetMusic**:
   - **Problema**: Version tiene is_visible (según jam-de-vientos), pero SheetMusic no
   - **Impacto**: No se puede ocultar partituras específicas sin eliminarlas
   - **Solución propuesta**: Agregar campo `is_visible = BooleanField(default=True)`

5. **unique_together permite duplicados de instrumentos**:
   - **Problema**: Un instrumento puede tener múltiples partituras del mismo type si son de diferentes versiones
   - **Análisis**: Esto es correcto por diseño (una trompeta tiene melodía en cada versión)
   - **Conclusión**: ✅ No requiere cambio

---

## 3. Modelo de Datos Definitivo

### 3.1 Diagrama de Relaciones

```
Theme (Tema musical)
│ id, title, artist, tonalidad, image, audio, description
│
├─1:N─> Version (Arreglo/Versión)
│       │ id, theme_id, title, type, image, audio_file, mus_file, notes
│       │ type: STANDARD | ENSAMBLE | DUETO | GRUPO_REDUCIDO
│       │
│       ├─1:N─> SheetMusic (Partitura individual)
│       │       │ id, version_id, instrument_id, type, clef, tonalidad_relativa, file
│       │       │ type: MELODIA_PRINCIPAL | MELODIA_SECUNDARIA | ARMONIA | BAJO
│       │       │ clef: SOL | FA
│       │       │
│       │       └─N:1─> Instrument
│       │               id, name, family, afinacion
│       │               family: VIENTO_MADERA | VIENTO_METAL | PERCUSION
│       │               afinacion: Bb | Eb | F | C | G | D | A | E | NONE
│       │
│       └─M:N─> Repertoire (through RepertoireVersion)
│               │ id, name, description, is_active
│               │
│               └─1:N─> Event
│                       │ id, title, event_type, status, description,
│                       │ start_datetime, end_datetime, is_public, price
│                       │
│                       └─N:1─> Location
│                               id, name, address, city, capacity
```

### 3.2 Formato "Standard" - Aclaración Conceptual

**Concepto erróneo identificado**: "Formato Standard" NO es un formato de archivo.

**Realidad**:
- **Version.type = 'STANDARD'**: Define que es un arreglo completo para banda (vs. DUETO, ENSAMBLE)
- **SheetMusic.type**: Define el rol de la partitura dentro de ese arreglo
  - `MELODIA_PRINCIPAL`: Línea melódica principal (trompetas, saxos)
  - `MELODIA_SECUNDARIA`: Segunda voz melódica
  - `ARMONIA`: Acompañamiento armónico (acordes, fills)
  - `BAJO`: Línea de bajo (tuba, saxo barítono, trombón)

**Ejemplo práctico**: "One Step Beyond" Version STANDARD
```
Theme: One Step Beyond (Cm)
└─ Version: Standard Full Band
    ├─ Trompeta Bb: MELODIA_PRINCIPAL (tonalidad_relativa: Dm)
    ├─ Saxo Alto Eb: MELODIA_PRINCIPAL (tonalidad_relativa: Am)
    ├─ Trombón C: BAJO (tonalidad_relativa: Cm, clave: FA)
    └─ Tuba C: BAJO (tonalidad_relativa: Cm, clave: FA)
```

### 3.3 Sistema de Transposición

#### Lógica Matemática (music/utils.py)

```python
def calculate_relative_tonality(theme_tonality, instrument_tuning):
    """
    Calcula la tonalidad escrita para un instrumento transpositor.

    Ejemplo: Theme en Cm + Trompeta Bb
    1. Cm = 0 semitonos (minor)
    2. Bb = +2 semitonos de transposición
    3. (0 + 2) % 12 = 2 → D (preserva minor) = Dm
    """
    TONALITY_MAP = {
        'C': 0, 'Cm': 0, 'C#': 1, 'C#m': 1,
        'D': 2, 'Dm': 2, 'D#': 3, 'D#m': 3,
        'E': 4, 'Em': 4, 'F': 5, 'Fm': 5,
        'F#': 6, 'F#m': 6, 'G': 7, 'Gm': 7,
        'G#': 8, 'G#m': 8, 'A': 9, 'Am': 9,
        'A#': 10, 'A#m': 10, 'B': 11, 'Bm': 11
    }

    TRANSPOSITION_MAP = {
        'C': 0,  'Bb': 2,  'Eb': 9,  'F': 7,
        'G': 5,  'D': 10,  'A': 3,   'E': 8,
        'NONE': 0
    }
```

#### Ejemplos de Transposición

| Tema (Concert) | Instrumento | Transposición | Resultado Escrito |
|----------------|-------------|---------------|-------------------|
| C major | Trompeta Bb | +2 semitonos | D major |
| C major | Saxo Alto Eb | +9 semitonos | A major |
| C major | Trompa F | +7 semitonos | G major |
| Cm minor | Trompeta Bb | +2 semitonos | Dm minor |
| Cm minor | Saxo Alto Eb | +9 semitonos | Am minor |

#### Asignación Automática de Clave

```python
def get_clef_for_instrument(instrument_name, instrument_family):
    """Sugiere clave según instrumento"""
    bass_clef_instruments = [
        'tuba', 'fagot', 'trombón', 'bombardino',
        'contrabajo', 'trombone', 'bassoon', 'euphonium', 'bass'
    ]
    # Si está en la lista → FA, sino → SOL
```

**Casos especiales detectados**:
- **Saxo Barítono**: Lee línea de BAJO pero en clave de SOL (transposición Eb)
- **Tuba**: Lee línea de BAJO en clave de FA (concert pitch C)
- **Trombón**: Puede leer BAJO (FA) o ARMONIA (SOL) según el arreglo

---

## 4. Integración jam-de-vientos ↔ sheet-api

### 4.1 Estado Actual de la Integración

#### Endpoints Consumidos (Funcionando)

```typescript
// lib/sheetmusic-api.ts

// ✅ Carousel de eventos (próximos 10 eventos públicos)
GET /api/v1/events/jamdevientos/carousel/
Response: { events: SheetMusicEvent[], total: number }

// ✅ Detalle de evento con repertorio completo
GET /api/v1/events/jamdevientos/{eventId}/
Response: SheetMusicEvent (con repertoire.versions[])

// ✅ Todos los eventos próximos
GET /api/v1/events/jamdevientos/upcoming/
Response: SheetMusicEvent[]
```

#### Datos Recibidos y Utilizados

```typescript
SheetMusicVersion {
  id: number
  title: string              // Nombre de la versión
  theme_title: string        // Nombre del tema (lo que muestra el carousel)
  artist: string            // Artista/compositor
  tonalidad: string         // Tonalidad concert pitch (ej: "Cm")
  order: number             // Orden en el repertorio
  sheet_music_count: number // Cantidad de PDFs disponibles
  audio?: string            // URL del audio
  image?: string            // URL de la imagen
  is_visible?: boolean      // Control de visibilidad
}
```

### 4.2 Gap Crítico Identificado: Descarga de Partituras

#### Problema

El frontend de jam-de-vientos tiene la **UI completa** para descargar partituras:

```typescript
// components/song-details.tsx (líneas 166-250)

// UI implementada:
- Selector de instrumento (5 botones: Bb, Eb, C, F, Clave de Fa)
- Selector de tipo de partitura (3 botones: Melodía, Armonía, Bajo)
- Botón de descarga con estado enabled/disabled

// Pero el código tiene:
const [uploadedFiles, setUploadedFiles] = useState<UploadedFile[]>([])
setUploadedFiles([]) // ← SIEMPRE VACÍO

// TODO en línea 61:
// TODO: Load files from SheetMusic API when available
```

**Estado**: 🚧 UI lista, backend listo, conexión faltante

#### Solución Propuesta

**Backend**: Agregar endpoints especializados en `JamDeVientosViewSet`:

```python
# events/views.py

class JamDeVientosViewSet(viewsets.ReadOnlyModelViewSet):
    # ...endpoints existentes...

    @action(detail=True, methods=['get'], url_path='sheet-music')
    def sheet_music_list(self, request, pk=None):
        """
        GET /api/v1/events/jamdevientos/{event_id}/sheet-music/

        Lista todas las partituras disponibles para todas las versiones
        de este evento con metadata de filtrado.
        """
        event = self.get_object()
        versions = event.repertoire.versions.all()

        # Obtener todas las partituras de todas las versiones
        sheet_music = SheetMusic.objects.filter(
            version__in=versions
        ).select_related('instrument', 'version')

        # Agrupar por version_id → instrument.afinacion → type
        grouped_data = {}
        for sm in sheet_music:
            vid = sm.version.id
            if vid not in grouped_data:
                grouped_data[vid] = {
                    'version_id': vid,
                    'version_title': sm.version.theme.title,
                    'available_parts': {}
                }

            key = f"{sm.instrument.afinacion}_{sm.type}"
            grouped_data[vid]['available_parts'][key] = {
                'id': sm.id,
                'instrument': sm.instrument.name,
                'afinacion': sm.instrument.afinacion,
                'type': sm.type,
                'clef': sm.clef,
                'tonalidad_relativa': sm.tonalidad_relativa,
                'file_url': sm.file.url
            }

        return Response(list(grouped_data.values()))

    @action(detail=False, methods=['get'], url_path='sheet-music/(?P<sm_id>[^/.]+)/download')
    def download_sheet_music(self, request, sm_id=None):
        """
        GET /api/v1/events/jamdevientos/sheet-music/{sm_id}/download/

        Descarga directa del archivo PDF.
        """
        try:
            sheet_music = SheetMusic.objects.get(
                id=sm_id,
                version__repertoires__events__is_public=True  # Solo eventos públicos
            )
            file_path = sheet_music.file.path

            return FileResponse(
                open(file_path, 'rb'),
                content_type='application/pdf',
                as_attachment=True,
                filename=f"{sheet_music.version.theme.title}_{sheet_music.instrument.name}_{sheet_music.get_type_display()}.pdf"
            )
        except SheetMusic.DoesNotExist:
            return Response({'error': 'Partitura no encontrada'}, status=404)
```

**Frontend**: Conectar en `sheetmusic-api.ts`:

```typescript
// lib/sheetmusic-api.ts

async getVersionSheetMusic(versionId: number): Promise<AvailableParts> {
  const response = await fetch(
    `${this.baseUrl}/api/v1/events/jamdevientos/versions/${versionId}/sheet-music/`
  )
  return response.json()
}

async downloadSheetMusic(sheetMusicId: number): Promise<Blob> {
  const response = await fetch(
    `${this.baseUrl}/api/v1/events/jamdevientos/sheet-music/${sheetMusicId}/download/`
  )
  return response.blob()
}
```

**Frontend**: Implementar en `song-details.tsx`:

```typescript
// Reemplazar línea 61
const [uploadedFiles, setUploadedFiles] = useState<UploadedFile[]>([])

// Por:
useEffect(() => {
  async function loadSheetMusic() {
    if (song?.id) {
      const data = await sheetMusicAPI.getVersionSheetMusic(song.id)
      setUploadedFiles(data.available_parts)
    }
  }
  loadSheetMusic()
}, [song])

// En handleDownload (línea 200)
const handleDownload = async () => {
  const key = `${selectedInstrument}_${selectedPart}`
  const part = uploadedFiles.find(f => f.key === key)

  if (part) {
    const blob = await sheetMusicAPI.downloadSheetMusic(part.id)
    const url = window.URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `${song.title}_${selectedInstrument}_${selectedPart}.pdf`
    a.click()
  }
}
```

### 4.3 Flujo Completo Usuario Final

```
1. Usuario entra a jam-de-vientos.com
   └─> Carga automática del featured event desde localStorage
       └─> GET /jamdevientos/{event_id}/

2. Usuario ve carousel con versiones del repertorio
   └─> Cada card muestra: theme_title, artist, tonalidad, audio, image

3. Usuario selecciona un tema del carousel
   └─> SongDetails se abre con los detalles

4. Usuario selecciona instrumento (ej: Trompeta Bb)
   └─> Frontend filtra uploadedFiles por afinacion='Bb'

5. Usuario selecciona tipo de partitura (ej: Melodía Principal)
   └─> Frontend busca uploadedFiles[key='Bb_MELODIA_PRINCIPAL']

6. Si existe, botón "Descargar PDF" se habilita
   └─> Click: GET /jamdevientos/sheet-music/{id}/download/
       └─> Descarga automática del PDF con nombre descriptivo
```

---

## 5. Análisis de music-learning-app

### 5.1 Dependencia de sheet-api

**Conclusión**: ❌ **NO depende de sheet-api**

**Arquitectura propia**:
- Backend Django 4.2 con apps: `exercises`, `courses`, `music_sheets`, `gamification`
- Base de datos independiente con modelos propios
- Procesamiento musical con `music21`, `librosa`, `mido`
- Sistema de ejercicios interactivos (notas, acordes, ritmo)

**Posible integración futura**:
- Importar partituras desde sheet-api para ejercicios
- Compartir catálogo de instrumentos
- Sincronizar tonalidades y transposiciones

### 5.2 Recomendaciones

Si en el futuro se desea integrar:
1. Crear SDK Python de sheet-api con cliente HTTP
2. Endpoint `/api/v1/themes/export/{id}/` que devuelva MusicXML o MIDI
3. music-learning-app consume y procesa con music21

---

## 6. Análisis de empiv-web

### 6.1 Dependencia de sheet-api

**Conclusión**: ❌ **NO depende de sheet-api**

**Enfoque**: Gestión administrativa de escuela de música
- Estudiantes, profesores, talleres, pagos
- Posible overlap: biblioteca de materiales musicales
- Actualmente: gestión independiente

### 6.2 Posible Integración Futura

- Compartir modelo de Events con sheet-api (talleres como eventos)
- Importar partituras para asignación a estudiantes
- Reportes de repertorio estudiado por alumno

---

## 7. Evaluación de Arquitectura REST API

### 7.1 Diseño de Endpoints

#### ✅ Buenas Prácticas Aplicadas

1. **Versionado**: `/api/v1/` permite evolución sin breaking changes
2. **Recursos anidados**: `/themes/{id}/versions/` es semánticamente correcto
3. **Filtros query params**: `?event_type=CONCERT&is_public=true`
4. **Paginación**: PageNumberPagination con 20 items por página
5. **Serializers especializados**: Detail vs List (optimización)
6. **CORS configurado**: Permite localhost:3000 y localhost:3001

#### ⚠️ Áreas de Mejora

1. **Falta throttling**: No hay rate limiting configurado
2. **No hay versioning en responses**: No se indica API version en headers
3. **Errores 500 exponen stack traces**: En DEBUG=True (solo dev)
4. **Falta HATEOAS**: No hay links `_links` en responses

### 7.2 Autenticación y Permisos

**Implementación Actual**:
- JWT con SimpleJWT
- `POST /api/v1/auth/login/` → devuelve access + refresh tokens
- `POST /api/v1/auth/token/refresh/` → renueva access token

**Permisos**:
- `JamDeVientosViewSet`: **AllowAny** (público)
- Resto de endpoints: **IsAuthenticated**
- LocationViewSet: **IsAdminUser** para write operations

**Recomendaciones**:
- Implementar roles más granulares (Manager, Musician, Public)
- Agregar OAuth2 para futuras integraciones

---

## 8. Evaluación de Dockerización

### 8.1 Estado Actual por Aplicación

| Aplicación | Docker Compose | Backend Port | Frontend Port | DB |
|------------|---------------|--------------|---------------|-----|
| sheet-api | ✅ Sí | 8000 | 3000 | PostgreSQL:5432 |
| jam-de-vientos | ✅ Sí | N/A | 3001 | N/A (consume sheet-api) |
| music-learning-app | ✅ Sí | 8000 | 3000 | PostgreSQL:5432 + Redis:6379 |
| empiv-web | ✅ Sí | 8000 | 3000 | PostgreSQL:5432 |

### 8.2 Problema de Redes Docker

**Desafío identificado**: jam-de-vientos necesita conectarse al backend de sheet-api

**Solución actual** (jam-de-vientos docker-compose.yml):
```yaml
networks:
  sheetmusic-network:
    external: true
    name: sheetmusic_sheetmusic-network
```

**Proceso manual**:
1. Usuario debe levantar sheet-api primero
2. sheet-api crea red `sheetmusic_sheetmusic-network`
3. Usuario levanta jam-de-vientos que se conecta a esa red
4. Frontend jam-de-vientos apunta a `NEXT_PUBLIC_SHEETMUSIC_API_URL=http://backend:8000`

**Problemas**:
- No documentado claramente
- Fácil olvidar el orden
- Errores crípticos si la red no existe

---

## 9. Recomendaciones Finales

### 9.1 Prioridad Alta

1. **Implementar descarga de PDFs en jam-de-vientos**
   - Tiempo estimado: 4 horas
   - Impacto: Alto (funcionalidad core faltante)

2. **Documentar flujo Docker multi-aplicación**
   - Tiempo estimado: 2 horas
   - Impacto: Alto (usabilidad para desarrollo)

3. **Agregar default_clef a modelo Instrument**
   - Tiempo estimado: 1 hora (migración + actualización)
   - Impacto: Medio (previene errores de usuario)

### 9.2 Prioridad Media

4. **Agregar is_visible a modelo SheetMusic**
   - Tiempo estimado: 1 hora
   - Impacto: Medio (control granular)

5. **Validadores de archivos**
   - Tiempo estimado: 3 horas
   - Impacto: Medio (seguridad)

6. **Marcar tonalidad_relativa como read_only**
   - Tiempo estimado: 15 minutos
   - Impacto: Bajo (prevención de bugs)

### 9.3 Prioridad Baja

7. **Sistema de roles más complejo**
   - Tiempo estimado: 8 horas
   - Impacto: Bajo (actualmente no requerido)

8. **Rate limiting**
   - Tiempo estimado: 2 horas
   - Impacto: Bajo (solo producción)

---

## 10. Conclusiones

### ✅ Solidez General: **8/10**

**Fortalezas**:
- Arquitectura relacional bien diseñada
- Separación clara de responsabilidades entre apps
- Sistema de transposición matemáticamente correcto
- API RESTful con buenas prácticas
- Dockerización funcional

**Debilidades**:
- Funcionalidad de descarga de PDFs incompleta en jam-de-vientos
- Falta documentación operativa para Docker multi-app
- Algunos campos calculados no están protegidos adecuadamente
- Validaciones de archivos ausentes

### 🎯 Siguiente Sesión

**Objetivos inmediatos**:
1. Implementar endpoints de descarga de PDFs
2. Conectar frontend jam-de-vientos con backend
3. Crear guías Docker detalladas
4. Actualizar README.md de sheet-api

**Objetivos a mediano plazo**:
1. Refinar modelo Instrument con default_clef
2. Agregar validaciones de archivos
3. Mejorar seguridad API (throttling, permisos)
4. Considerar SDK Python/TS para consumidores

---

**Documento generado**: 2025-10-24
**Última actualización**: 2025-10-24
