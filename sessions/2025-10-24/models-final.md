# Modelos Django Definitivos: Sheet-API

**Fecha**: 2025-10-24
**Estado**: Validado y Documentado
**Versión API**: v1

---

## 1. Resumen Ejecutivo

Este documento define la estructura completa de modelos Django del backend sheet-api, incluyendo todos los campos, relaciones, validaciones y comportamientos especiales.

**Aplicaciones Django**:
- `music/`: Dominio musical core (temas, versiones, instrumentos, partituras)
- `events/`: Gestión de eventos y repertorios

**Total de modelos**: 7
- Music app: 4 modelos (Theme, Instrument, Version, SheetMusic)
- Events app: 4 modelos (Location, Repertoire, RepertoireVersion, Event)

---

## 2. App: music/

### 2.1 Modelo: Theme

**Propósito**: Representa una pieza musical original (canción, tema, composición).

**Tabla**: `music_theme`

#### Campos

| Campo | Tipo | Constraints | Descripción |
|-------|------|-------------|-------------|
| `id` | AutoField | PK | ID autogenerado |
| `title` | CharField(200) | NOT NULL | Título de la pieza |
| `artist` | CharField(200) | blank=True | Artista o compositor |
| `tonalidad` | CharField(10) | choices, blank | Tonalidad concert pitch (24 opciones) |
| `description` | TextField | blank=True | Descripción o notas sobre la pieza |
| `image` | ImageField | blank, null | Carátula o imagen del tema |
| `audio` | FileField | blank, null | Grabación de referencia del tema |
| `created_at` | DateTimeField | auto_now_add | Fecha de creación |
| `updated_at` | DateTimeField | auto_now | Fecha de última actualización |

#### Choices: `tonalidad`

```python
TONALITY_CHOICES = [
    # Mayores
    ('C', 'Do Mayor'),
    ('C#', 'Do# Mayor'),
    ('D', 'Re Mayor'),
    ('D#', 'Re# Mayor'),
    ('E', 'Mi Mayor'),
    ('F', 'Fa Mayor'),
    ('F#', 'Fa# Mayor'),
    ('G', 'Sol Mayor'),
    ('G#', 'Sol# Mayor'),
    ('A', 'La Mayor'),
    ('A#', 'La# Mayor'),
    ('B', 'Si Mayor'),
    # Menores
    ('Cm', 'Do menor'),
    ('C#m', 'Do# menor'),
    ('Dm', 'Re menor'),
    ('D#m', 'Re# menor'),
    ('Em', 'Mi menor'),
    ('Fm', 'Fa menor'),
    ('F#m', 'Fa# menor'),
    ('Gm', 'Sol menor'),
    ('G#m', 'Sol# menor'),
    ('Am', 'La menor'),
    ('A#m', 'La# menor'),
    ('Bm', 'Si menor'),
]
```

#### Relaciones

- **Salientes**: `versions` (1:N) → Version

#### Métodos

```python
def __str__(self):
    if self.artist:
        return f"{self.title} - {self.artist}"
    return self.title
```

#### Meta

```python
class Meta:
    ordering = ['title']
```

#### Rutas de Upload

- **image**: `media/{theme_title}/theme_image.{ext}`
- **audio**: `media/{theme_title}/theme_audio.{ext}`

---

### 2.2 Modelo: Instrument

**Propósito**: Catálogo de instrumentos musicales con sus características de transposición.

**Tabla**: `music_instrument`

#### Campos

| Campo | Tipo | Constraints | Descripción |
|-------|------|-------------|-------------|
| `id` | AutoField | PK | ID autogenerado |
| `name` | CharField(100) | NOT NULL | Nombre del instrumento (ej: "Trompeta en Bb") |
| `family` | CharField(20) | choices, blank | Familia instrumental |
| `afinacion` | CharField(10) | choices, blank | Transposición del instrumento |
| `created_at` | DateTimeField | auto_now_add | Fecha de creación |

#### Choices: `family`

```python
FAMILY_CHOICES = [
    ('VIENTO_MADERA', 'Vientos-Madera'),
    ('VIENTO_METAL', 'Vientos-Metales'),
    ('PERCUSION', 'Percusión'),
]
```

#### Choices: `afinacion`

```python
TUNING_CHOICES = [
    ('Bb', 'Si bemol'),      # Clarinete, Trompeta, Saxo Tenor
    ('Eb', 'Mi bemol'),      # Saxo Alto, Saxo Barítono, Trompa
    ('F', 'Fa'),             # Trompa
    ('C', 'Do'),             # Flauta, Trombón, Tuba (concert pitch)
    ('G', 'Sol'),            # Raro
    ('D', 'Re'),             # Raro
    ('A', 'La'),             # Raro
    ('E', 'Mi'),             # Raro
    ('NONE', 'Sin afinación específica'),  # Percusión
]
```

#### Ejemplos de Instrumentos Reales

| Instrumento | Name | Family | Afinacion |
|-------------|------|--------|-----------|
| Flauta | "Flauta" | VIENTO_MADERA | C |
| Clarinete | "Clarinete en Bb" | VIENTO_MADERA | Bb |
| Saxo Alto | "Saxo Alto en Eb" | VIENTO_MADERA | Eb |
| Saxo Barítono | "Saxo Barítono en Eb" | VIENTO_MADERA | Eb |
| Trompeta | "Trompeta en Bb" | VIENTO_METAL | Bb |
| Trompa | "Trompa en F" | VIENTO_METAL | F |
| Trombón | "Trombón" | VIENTO_METAL | C |
| Tuba | "Tuba" | VIENTO_METAL | C |

#### Relaciones

- **Salientes**: `sheet_music` (1:N) → SheetMusic

#### Métodos

```python
def __str__(self):
    return self.name
```

#### Meta

```python
class Meta:
    ordering = ['name']
```

#### Nota sobre Clave

⚠️ **Campo faltante detectado**: Actualmente la clave (SOL/FA) está en SheetMusic, pero debería estar también en Instrument como `default_clef` para validación automática.

**Propuesta**:
```python
default_clef = models.CharField(
    max_length=10,
    choices=[('SOL', 'Clave de Sol'), ('FA', 'Clave de Fa')],
    default='SOL',
    help_text='Clave predeterminada para este instrumento'
)
```

---

### 2.3 Modelo: Version

**Propósito**: Representa un arreglo o versión específica de un tema musical.

**Tabla**: `music_version`

#### Campos

| Campo | Tipo | Constraints | Descripción |
|-------|------|-------------|-------------|
| `id` | AutoField | PK | ID autogenerado |
| `theme` | ForeignKey | NOT NULL, CASCADE | Tema padre |
| `title` | CharField(300) | blank=True | Título específico de la versión (opcional) |
| `type` | CharField(20) | choices, default='STANDARD' | Tipo de arreglo |
| `image` | ImageField | blank, null | Carátula específica de esta versión |
| `audio_file` | FileField | blank, null | Grabación de esta versión |
| `mus_file` | FileField | blank, null | Archivo MuseScore (.mscz, .mscx) |
| `notes` | TextField | blank=True | Notas sobre el arreglo |
| `created_at` | DateTimeField | auto_now_add | Fecha de creación |
| `updated_at` | DateTimeField | auto_now | Fecha de última actualización |

#### Choices: `type`

```python
TYPE_CHOICES = [
    ('STANDARD', 'Standard'),                # Arreglo completo para banda
    ('ENSAMBLE', 'Ensamble'),               # Versión para ensamble reducido
    ('DUETO', 'Dueto'),                     # Versión a dos voces
    ('GRUPO_REDUCIDO', 'Grupo Reducido'),   # Versión para grupo pequeño
]
```

#### Interpretación de "STANDARD"

**Version.type = 'STANDARD'** significa:
- Arreglo completo para banda de vientos
- Incluye todas las secciones: melodía principal, secundaria, armonía, bajo
- Partituras disponibles para múltiples instrumentos
- Es el formato "estándar" de la Jam de Vientos

#### Relaciones

- **Entrantes**: `theme` (N:1) → Theme
- **Salientes**: `sheet_music` (1:N) → SheetMusic
- **M:N**: `repertoires` (M:N through RepertoireVersion) → Repertoire

#### Métodos

```python
def __str__(self):
    return f"{self.theme.title} - Version {self.id}"
```

#### Meta

```python
class Meta:
    ordering = ['-created_at']
```

#### Rutas de Upload

- **image**: `media/{theme_title}/{version_type}_cover.{ext}`
- **audio_file**: `media/{theme_title}/{version_type}_audio.{ext}`
- **mus_file**: `media/{theme_title}/{version_type}_score.{mscz|mscx}`

---

### 2.4 Modelo: SheetMusic

**Propósito**: Representa un archivo de partitura individual para un instrumento específico en una versión.

**Tabla**: `music_sheetmusic`

#### Campos

| Campo | Tipo | Constraints | Descripción |
|-------|------|-------------|-------------|
| `id` | AutoField | PK | ID autogenerado |
| `version` | ForeignKey | NOT NULL, CASCADE | Versión a la que pertenece |
| `instrument` | ForeignKey | NOT NULL, CASCADE | Instrumento para el que está escrita |
| `type` | CharField(20) | choices, default='MELODIA_PRINCIPAL' | Tipo de parte musical |
| `clef` | CharField(10) | choices, default='SOL' | Clave musical |
| `tonalidad_relativa` | CharField(10) | blank | Tonalidad escrita (auto-calculada) |
| `file` | FileField | NOT NULL | Archivo PDF o imagen de la partitura |
| `created_at` | DateTimeField | auto_now_add | Fecha de creación |
| `updated_at` | DateTimeField | auto_now | Fecha de última actualización |

#### Choices: `type`

```python
TYPE_CHOICES = [
    ('MELODIA_PRINCIPAL', 'Melodía Principal'),      # Línea melódica principal
    ('MELODIA_SECUNDARIA', 'Melodía Secundaria'),    # Segunda voz melódica
    ('ARMONIA', 'Armonía'),                          # Acompañamiento armónico
    ('BAJO', 'Bajo'),                                # Línea de bajo
]
```

#### Interpretación de `type`

| Type | Instrumentos Típicos | Clave Típica | Descripción |
|------|---------------------|--------------|-------------|
| `MELODIA_PRINCIPAL` | Trompeta, Saxo Alto, Flauta | SOL | Melodía líder, tema principal |
| `MELODIA_SECUNDARIA` | Trombón, Saxo Tenor | SOL | Segunda voz, contramelodía |
| `ARMONIA` | Trompetas (sección), Saxos | SOL | Acordes, fills, acompañamiento |
| `BAJO` | Tuba, Trombón, Saxo Barítono | FA (Tuba/Trombón), SOL (Saxo) | Línea de bajo |

#### Choices: `clef`

```python
CLEF_CHOICES = [
    ('SOL', 'Clave de Sol'),   # Mayoría de instrumentos
    ('FA', 'Clave de Fa'),     # Tuba, Trombón, Fagot
]
```

#### Campo Especial: `tonalidad_relativa`

**Comportamiento**:
- ✅ **Auto-calculado** en `SheetMusicViewSet.perform_create()` y `perform_update()`
- ⚠️ **Debería ser read_only** en serializer (actualmente no lo es)
- Usa `calculate_relative_tonality(theme.tonalidad, instrument.afinacion)`

**Ejemplo de cálculo**:
```
Theme: One Step Beyond (Cm)
Instrument: Trompeta en Bb (afinacion='Bb')
Resultado: tonalidad_relativa = 'Dm'

Explicación:
- Cm = 0 semitonos (menor)
- Bb transpone +2 semitonos
- (0 + 2) % 12 = 2 → D
- Preserva modo menor → Dm
```

#### Relaciones

- **Entrantes**:
  - `version` (N:1) → Version
  - `instrument` (N:1) → Instrument

#### Constraints

```python
class Meta:
    unique_together = ['version', 'instrument', 'type']
```

**Significado**: Un instrumento solo puede tener **una** partitura de cada tipo por versión.

**Ejemplo válido**:
- Trompeta Bb → MELODIA_PRINCIPAL (✅)
- Trompeta Bb → ARMONIA (✅)
- Trompeta Bb → BAJO (✅)

**Ejemplo inválido**:
- Trompeta Bb → MELODIA_PRINCIPAL (1) ❌
- Trompeta Bb → MELODIA_PRINCIPAL (2) ❌ VIOLACIÓN unique_together

#### Métodos

```python
def __str__(self):
    return f"{self.version.theme.title} - {self.instrument.name} ({self.get_type_display()})"
```

#### Meta

```python
class Meta:
    ordering = ['-created_at']
    unique_together = ['version', 'instrument', 'type']
```

#### Rutas de Upload

**Formato**: `media/{theme_title}_{version_type}_{instrument_name}_{type}_{YYYYMMDD}.{ext}`

**Ejemplo**:
```
media/One_Step_Beyond_Standard_Trompeta_Bb_Melodia_Principal_20251024.pdf
```

#### Comportamiento en ViewSet

```python
# music/views.py - SheetMusicViewSet

def perform_create(self, serializer):
    version = serializer.validated_data['version']
    instrument = serializer.validated_data['instrument']

    # Auto-calcular tonalidad relativa
    tonalidad_relativa = calculate_relative_tonality(
        version.theme.tonalidad,
        instrument.afinacion
    )

    # Auto-sugerir clave si no se proporciona
    if 'clef' not in serializer.validated_data:
        clef = get_clef_for_instrument(
            instrument.name.lower(),
            instrument.family
        )
        serializer.save(
            tonalidad_relativa=tonalidad_relativa,
            clef=clef
        )
    else:
        serializer.save(tonalidad_relativa=tonalidad_relativa)

def perform_update(self, serializer):
    # Recalcular tonalidad relativa en cada update
    instance = serializer.instance
    tonalidad_relativa = calculate_relative_tonality(
        instance.version.theme.tonalidad,
        instance.instrument.afinacion
    )
    serializer.save(tonalidad_relativa=tonalidad_relativa)
```

---

## 3. App: events/

### 3.1 Modelo: Location

**Propósito**: Representa lugares físicos donde se realizan eventos.

**Tabla**: `events_location`

#### Campos

| Campo | Tipo | Constraints | Descripción |
|-------|------|-------------|-------------|
| `id` | AutoField | PK | ID autogenerado |
| `name` | CharField(200) | NOT NULL | Nombre del lugar |
| `address` | TextField | NOT NULL | Dirección completa |
| `city` | CharField(100) | NOT NULL | Ciudad |
| `postal_code` | CharField(10) | NOT NULL | Código postal |
| `country` | CharField(100) | default='Argentina' | País |
| `capacity` | PositiveIntegerField | NOT NULL, >=1 | Capacidad máxima |
| `contact_email` | EmailField | blank, null | Email de contacto |
| `contact_phone` | CharField(20) | blank, null | Teléfono |
| `website` | URLField | blank, null | Sitio web del lugar |
| `notes` | TextField | blank=True | Notas adicionales |
| `is_active` | BooleanField | default=True | Lugar activo |
| `created_at` | DateTimeField | auto_now_add | Fecha de creación |
| `updated_at` | DateTimeField | auto_now | Fecha de actualización |

#### Relaciones

- **Salientes**: `events` (1:N) → Event

#### Validaciones

```python
from django.core.validators import MinValueValidator

capacity = models.PositiveIntegerField(
    validators=[MinValueValidator(1)]
)
```

#### Métodos

```python
def __str__(self):
    return f"{self.name}, {self.city}"
```

#### Meta

```python
class Meta:
    verbose_name = 'Ubicación'
    verbose_name_plural = 'Ubicaciones'
    ordering = ['name']
```

---

### 3.2 Modelo: Repertoire

**Propósito**: Colección ordenada de versiones (arreglos) para un evento.

**Tabla**: `events_repertoire`

#### Campos

| Campo | Tipo | Constraints | Descripción |
|-------|------|-------------|-------------|
| `id` | AutoField | PK | ID autogenerado |
| `name` | CharField(200) | NOT NULL | Nombre del repertorio |
| `description` | TextField | blank=True | Descripción |
| `versions` | ManyToManyField | through='RepertoireVersion' | Versiones incluidas |
| `is_active` | BooleanField | default=True | Repertorio activo (soft delete) |
| `created_at` | DateTimeField | auto_now_add | Fecha de creación |
| `updated_at` | DateTimeField | auto_now | Fecha de actualización |

#### Relaciones

- **M:N**: `versions` (through RepertoireVersion) → Version
- **Salientes**: `events` (1:N) → Event

#### Comportamiento Especial: Soft Delete

```python
# events/views.py - RepertoireViewSet

def perform_destroy(self, instance):
    # No elimina, solo marca como inactivo
    instance.is_active = False
    instance.save()
```

#### Métodos

```python
def __str__(self):
    return self.name
```

#### Meta

```python
class Meta:
    verbose_name = 'Repertorio'
    verbose_name_plural = 'Repertorios'
    ordering = ['-created_at']
```

---

### 3.3 Modelo: RepertoireVersion (Through Table)

**Propósito**: Tabla intermedia para la relación M:N entre Repertoire y Version, con ordenamiento.

**Tabla**: `events_repertoireversion`

#### Campos

| Campo | Tipo | Constraints | Descripción |
|-------|------|-------------|-------------|
| `id` | AutoField | PK | ID autogenerado |
| `repertoire` | ForeignKey | NOT NULL, CASCADE | Repertorio padre |
| `version` | ForeignKey | NOT NULL, CASCADE | Versión incluida |
| `order` | PositiveIntegerField | default=0 | Orden en el repertorio |
| `notes` | TextField | blank=True | Notas específicas para esta inclusión |
| `created_at` | DateTimeField | auto_now_add | Fecha de adición |

#### Relaciones

- **Entrantes**:
  - `repertoire` (N:1) → Repertoire
  - `version` (N:1) → Version

#### Constraints

```python
class Meta:
    unique_together = ('repertoire', 'version')
```

**Significado**: Una versión solo puede aparecer **una vez** en un repertorio.

#### Métodos

```python
def __str__(self):
    return f"{self.repertoire.name} - {self.version.theme.title} (Orden: {self.order})"
```

#### Meta

```python
class Meta:
    ordering = ['order', 'created_at']
    unique_together = ('repertoire', 'version')
    verbose_name = 'Versión en repertorio'
    verbose_name_plural = 'Versiones en repertorios'
```

#### Uso en API

```python
# Obtener versiones ordenadas de un repertorio
repertoire.versions.all()  # Devuelve versiones ordenadas por 'order'

# Acceder al order desde una version
repertoire_version = RepertoireVersion.objects.get(repertoire=rep, version=ver)
order = repertoire_version.order
```

---

### 3.4 Modelo: Event

**Propósito**: Representa un evento musical (concierto, ensayo, grabación, taller).

**Tabla**: `events_event`

#### Campos

| Campo | Tipo | Constraints | Descripción |
|-------|------|-------------|-------------|
| `id` | AutoField | PK | ID autogenerado |
| `title` | CharField(200) | NOT NULL | Título del evento |
| `event_type` | CharField(20) | choices, default='CONCERT' | Tipo de evento |
| `status` | CharField(20) | choices, default='DRAFT' | Estado del evento |
| `description` | TextField | blank=True | Descripción del evento |
| `start_datetime` | DateTimeField | NOT NULL | Fecha/hora de inicio |
| `end_datetime` | DateTimeField | NOT NULL | Fecha/hora de fin |
| `location` | ForeignKey | SET_NULL, blank, null | Locación del evento |
| `repertoire` | ForeignKey | SET_NULL, blank, null | Repertorio a tocar |
| `is_public` | BooleanField | default=False | Evento visible públicamente |
| `max_attendees` | PositiveIntegerField | blank, null | Máximo de asistentes |
| `price` | DecimalField | default=0 | Precio de entrada (0 = gratis) |
| `created_at` | DateTimeField | auto_now_add | Fecha de creación |
| `updated_at` | DateTimeField | auto_now | Fecha de actualización |

#### Choices: `event_type`

```python
EVENT_TYPE_CHOICES = [
    ('CONCERT', 'Concierto'),
    ('REHEARSAL', 'Ensayo'),
    ('RECORDING', 'Grabación'),
    ('WORKSHOP', 'Taller'),
    ('OTHER', 'Otro'),
]
```

#### Choices: `status`

```python
STATUS_CHOICES = [
    ('DRAFT', 'Borrador'),
    ('CONFIRMED', 'Confirmado'),
    ('CANCELLED', 'Cancelado'),
    ('COMPLETED', 'Completado'),
]
```

#### Campo Especial: `is_public`

**Uso en jam-de-vientos**:
- `is_public=True` → Evento visible en carousel público
- `is_public=False` → Evento solo visible en admin

**JamDeVientosViewSet** filtra automáticamente:
```python
def get_queryset(self):
    return Event.objects.filter(is_public=True)
```

#### Relaciones

- **Entrantes**:
  - `location` (N:1, nullable) → Location
  - `repertoire` (N:1, nullable) → Repertoire

#### Validaciones

```python
def clean(self):
    # 1. Fecha de inicio < fecha de fin
    if self.start_datetime and self.end_datetime:
        if self.start_datetime >= self.end_datetime:
            raise ValidationError(
                'La fecha de inicio debe ser anterior a la de finalización'
            )

    # 2. No crear eventos en el pasado (solo para nuevos)
    if not self.pk and self.start_datetime < timezone.now():
        raise ValidationError(
            'No se puede crear un evento con fecha en el pasado'
        )

def save(self, *args, **kwargs):
    self.full_clean()  # Ejecuta clean() antes de guardar
    super().save(*args, **kwargs)
```

#### Properties

```python
@property
def is_upcoming(self):
    """True si el evento está programado para el futuro"""
    return self.start_datetime > timezone.now()

@property
def is_ongoing(self):
    """True si el evento está sucediendo ahora"""
    now = timezone.now()
    return self.start_datetime <= now <= self.end_datetime
```

#### Métodos

```python
def __str__(self):
    return (
        f"{self.title} - {self.get_event_type_display()} - "
        f"{self.start_datetime.strftime('%d/%m/%Y %H:%M')}"
    )
```

#### Meta

```python
class Meta:
    verbose_name = 'Evento'
    verbose_name_plural = 'Eventos'
    ordering = ['start_datetime']
```

---

## 4. Flujo de Datos Completo: Ejemplo Real

### Escenario: "One Step Beyond" en Jam de Vientos

#### Paso 1: Crear Theme

```python
theme = Theme.objects.create(
    title="One Step Beyond",
    artist="Madness",
    tonalidad="Cm",  # Concert pitch
    audio="one_step_beyond_reference.mp3"
)
```

#### Paso 2: Crear Version STANDARD

```python
version = Version.objects.create(
    theme=theme,
    type="STANDARD",  # ← Formato Standard
    audio_file="one_step_beyond_standard.mp3"
)
```

#### Paso 3: Crear Instrumentos (si no existen)

```python
trompeta_bb = Instrument.objects.get_or_create(
    name="Trompeta en Bb",
    family="VIENTO_METAL",
    afinacion="Bb"
)

saxo_alto_eb = Instrument.objects.get_or_create(
    name="Saxo Alto en Eb",
    family="VIENTO_MADERA",
    afinacion="Eb"
)

tuba_c = Instrument.objects.get_or_create(
    name="Tuba",
    family="VIENTO_METAL",
    afinacion="C"
)
```

#### Paso 4: Subir Partituras (con auto-transposición)

```python
# Trompeta Melodía Principal
sm1 = SheetMusic.objects.create(
    version=version,
    instrument=trompeta_bb,
    type="MELODIA_PRINCIPAL",
    file="one_step_trompeta_melodia.pdf"
)
# Auto-calculado: tonalidad_relativa = "Dm" (Cm + 2 semitonos)
# Auto-sugerido: clef = "SOL"

# Saxo Alto Melodía Principal
sm2 = SheetMusic.objects.create(
    version=version,
    instrument=saxo_alto_eb,
    type="MELODIA_PRINCIPAL",
    file="one_step_saxo_alto_melodia.pdf"
)
# Auto-calculado: tonalidad_relativa = "Am" (Cm + 9 semitonos)
# Auto-sugerido: clef = "SOL"

# Tuba Bajo
sm3 = SheetMusic.objects.create(
    version=version,
    instrument=tuba_c,
    type="BAJO",
    clef="FA",  # Especificado manualmente
    file="one_step_tuba_bajo.pdf"
)
# Auto-calculado: tonalidad_relativa = "Cm" (sin transposición, C concert)
# clef = "FA" (ya especificado)
```

#### Paso 5: Crear Repertorio

```python
repertorio = Repertoire.objects.create(
    name="Repertorio Jam de Vientos - Noviembre 2025"
)

RepertoireVersion.objects.create(
    repertoire=repertorio,
    version=version,
    order=1  # Primera canción del repertorio
)
```

#### Paso 6: Crear Evento Público

```python
location = Location.objects.create(
    name="Centro Cultural Konex",
    city="Buenos Aires",
    capacity=500
)

event = Event.objects.create(
    title="Jam de Vientos - Noche de Ska",
    event_type="CONCERT",
    status="CONFIRMED",
    start_datetime=datetime(2025, 11, 15, 20, 0),
    end_datetime=datetime(2025, 11, 15, 23, 0),
    location=location,
    repertoire=repertorio,
    is_public=True  # ← Visible en jam-de-vientos.com
)
```

#### Paso 7: Consumo desde jam-de-vientos

```typescript
// Frontend llama
GET /api/v1/events/jamdevientos/carousel/

// Recibe:
{
  events: [{
    id: 1,
    title: "Jam de Vientos - Noche de Ska",
    location_name: "Centro Cultural Konex",
    location_city: "Buenos Aires",
    repertoire: {
      name: "Repertorio Jam de Vientos - Noviembre 2025",
      versions: [{
        id: 1,
        theme_title: "One Step Beyond",
        artist: "Madness",
        tonalidad: "Cm",  // Concert pitch
        audio: "http://.../one_step_beyond_standard.mp3",
        sheet_music_count: 3,  // Trompeta, Saxo, Tuba
        order: 1
      }]
    }
  }]
}

// Usuario selecciona instrumento "Bb"
// Usuario selecciona tipo "MELODIA_PRINCIPAL"
// Frontend llama:
GET /api/v1/events/jamdevientos/sheet-music/{sm1.id}/download/

// Descarga: "One_Step_Beyond_Trompeta_en_Bb_Melodía_Principal.pdf"
// Con tonalidad escrita: Dm
```

---

## 5. Mejoras Propuestas (No Implementadas)

### 5.1 Agregar `default_clef` a Instrument

**Razón**: Prevenir errores humanos al subir partituras.

```python
class Instrument(models.Model):
    # ... campos existentes ...
    default_clef = models.CharField(
        max_length=10,
        choices=SheetMusic.CLEF_CHOICES,
        default='SOL',
        help_text='Clave predeterminada para este instrumento'
    )
```

**Impacto**:
- `get_clef_for_instrument()` sería obsoleto
- Validación más robusta en SheetMusicViewSet

### 5.2 Agregar `is_visible` a SheetMusic

**Razón**: Control granular de visibilidad de partituras individuales.

```python
class SheetMusic(models.Model):
    # ... campos existentes ...
    is_visible = models.BooleanField(
        default=True,
        help_text='Controla si esta partitura está visible públicamente'
    )
```

**Impacto**:
- JamDeVientosViewSet puede filtrar por `is_visible=True`
- Admin puede ocultar partituras sin eliminarlas

### 5.3 Hacer `tonalidad_relativa` read-only en Serializer

**Razón**: Es un campo calculado, no debería ser editable por clientes.

```python
# music/serializers.py

class SheetMusicSerializer(serializers.ModelSerializer):
    tonalidad_relativa = serializers.CharField(read_only=True)
    # ... resto de campos ...
```

### 5.4 Validadores de Archivos

**Razón**: Seguridad y prevención de errores.

```python
from django.core.validators import FileExtensionValidator

class SheetMusic(models.Model):
    file = models.FileField(
        upload_to=sheet_music_upload_path,
        validators=[
            FileExtensionValidator(allowed_extensions=['pdf', 'png', 'jpg']),
            FileSizeValidator(max_size_mb=10)
        ]
    )
```

---

## 6. Resumen de Relaciones

```
Theme (1) ────┬───> Version (N) ────┬───> SheetMusic (N)
              │                      │        │
              │                      │        └───> Instrument (N:1)
              │                      │
              │                      └───> RepertoireVersion (N) ───> Repertoire (N:1)
              │                                                           │
              └────────────────────────────────────────────────────────── └───> Event (1:N)
                                                                              │
                                                                              └───> Location (N:1)
```

---

## 7. Checklist de Validación

- [x] Todos los campos documentados con tipos y constraints
- [x] Todas las choices enumeradas
- [x] Relaciones FK y M2M claras
- [x] Validaciones a nivel de modelo identificadas
- [x] Comportamientos especiales (soft delete, auto-cálculo) explicados
- [x] Ejemplos prácticos de uso
- [x] Mejoras propuestas documentadas
- [x] Flujo completo de datos ejemplificado

---

**Documento generado**: 2025-10-24
**Última actualización**: 2025-10-24
**Próximo paso**: Documentar contratos API
