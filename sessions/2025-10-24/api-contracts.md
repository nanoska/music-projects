# Contratos API: Sheet-API v1

**Fecha**: 2025-10-24
**Versión API**: v1
**Base URL**: `/api/v1/`
**Formato**: JSON
**Autenticación**: JWT (SimpleJWT)

---

## 1. Introducción

Este documento define los contratos API completos del backend sheet-api, incluyendo endpoints, schemas de request/response, códigos de estado y ejemplos reales.

### 1.1 Aplicaciones Consumidoras

| Aplicación | Endpoints Usados | Autenticación Requerida |
|------------|------------------|-------------------------|
| **sheet-api/frontend** | Todos | ✅ Sí (JWT) |
| **jam-de-vientos** | `/events/jamdevientos/*` | ❌ No (público) |
| **music-learning-app** | Ninguno (independiente) | N/A |
| **empiv-web** | Ninguno (independiente) | N/A |

### 1.2 Convenciones Generales

**Paginación**:
```json
{
  "count": 100,
  "next": "http://api.example.com/resource/?page=2",
  "previous": null,
  "results": [ ... ]
}
```
- **Page size**: 20 items por página
- **Query param**: `?page=2`

**Timestamps**:
- Formato: ISO 8601 (`2025-10-24T14:30:00Z`)
- Zona horaria: UTC

**Errores**:
```json
{
  "detail": "Mensaje de error descriptivo"
}
```

**Códigos de Estado HTTP**:
- `200 OK`: Éxito en GET, PUT, PATCH
- `201 Created`: Éxito en POST
- `204 No Content`: Éxito en DELETE
- `400 Bad Request`: Datos inválidos
- `401 Unauthorized`: No autenticado
- `403 Forbidden`: Sin permisos
- `404 Not Found`: Recurso no encontrado
- `500 Internal Server Error`: Error del servidor

---

## 2. Autenticación

### 2.1 POST /api/v1/auth/login/

**Descripción**: Obtener tokens JWT.

**Request**:
```json
{
  "username": "admin",
  "password": "password123"
}
```

**Response** (200 OK):
```json
{
  "access": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Errores**:
- `401 Unauthorized`: Credenciales inválidas

### 2.2 POST /api/v1/auth/token/refresh/

**Descripción**: Renovar access token.

**Request**:
```json
{
  "refresh": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Response** (200 OK):
```json
{
  "access": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### 2.3 Uso de Tokens

**Headers en requests autenticados**:
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## 3. Music App Endpoints

### 3.1 Themes

#### GET /api/v1/themes/

**Descripción**: Listar todos los temas musicales.

**Autenticación**: ✅ Requerida

**Query Params**:
- `tonalidad`: Filtrar por tonalidad (ej: `?tonalidad=Cm`)
- `artist`: Filtrar por artista (ej: `?artist=Madness`)
- `search`: Buscar en title, artist, description (ej: `?search=ska`)
- `ordering`: Ordenar por campo (ej: `?ordering=-created_at`)

**Response** (200 OK):
```json
{
  "count": 42,
  "next": "http://localhost:8000/api/v1/themes/?page=2",
  "previous": null,
  "results": [
    {
      "id": 1,
      "title": "One Step Beyond",
      "artist": "Madness",
      "tonalidad": "Cm",
      "tonalidad_display": "Do menor",
      "description": "Clásico del ska británico",
      "image": "http://localhost:8000/media/one_step_beyond/theme_image.jpg",
      "audio": "http://localhost:8000/media/one_step_beyond/theme_audio.mp3",
      "versions_count": 3,
      "created_at": "2025-10-24T10:00:00Z",
      "updated_at": "2025-10-24T12:30:00Z"
    }
  ]
}
```

#### POST /api/v1/themes/

**Descripción**: Crear un nuevo tema.

**Autenticación**: ✅ Requerida

**Request** (multipart/form-data):
```
title: "One Step Beyond"
artist: "Madness"
tonalidad: "Cm"
description: "Clásico del ska británico"
image: [binary file]
audio: [binary file]
```

**Response** (201 Created):
```json
{
  "id": 1,
  "title": "One Step Beyond",
  "artist": "Madness",
  "tonalidad": "Cm",
  "tonalidad_display": "Do menor",
  "description": "Clásico del ska británico",
  "image": "http://localhost:8000/media/one_step_beyond/theme_image.jpg",
  "audio": "http://localhost:8000/media/one_step_beyond/theme_audio.mp3",
  "versions_count": 0,
  "created_at": "2025-10-24T10:00:00Z",
  "updated_at": "2025-10-24T10:00:00Z"
}
```

#### GET /api/v1/themes/{id}/

**Descripción**: Obtener detalle de un tema.

**Response** (200 OK): Mismo formato que POST response.

#### PUT/PATCH /api/v1/themes/{id}/

**Descripción**: Actualizar un tema (PUT completo, PATCH parcial).

#### DELETE /api/v1/themes/{id}/

**Descripción**: Eliminar un tema (cascade elimina versiones y partituras).

**Response** (204 No Content)

#### GET /api/v1/themes/{id}/versions/

**Descripción**: Listar versiones de un tema específico.

**Response** (200 OK):
```json
[
  {
    "id": 1,
    "theme_title": "One Step Beyond",
    "title": "",
    "type": "STANDARD",
    "type_display": "Standard",
    "sheet_music_count": 5,
    "created_at": "2025-10-24T11:00:00Z"
  }
]
```

---

### 3.2 Instruments

#### GET /api/v1/instruments/

**Descripción**: Listar todos los instrumentos.

**Query Params**:
- `family`: Filtrar por familia (ej: `?family=VIENTO_METAL`)
- `afinacion`: Filtrar por afinación (ej: `?afinacion=Bb`)
- `search`: Buscar en name, family
- `ordering`: Ordenar

**Response** (200 OK):
```json
{
  "count": 15,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 1,
      "name": "Trompeta en Bb",
      "family": "VIENTO_METAL",
      "family_display": "Vientos-Metales",
      "afinacion": "Bb",
      "afinacion_display": "Si bemol",
      "sheet_music_count": 12
    },
    {
      "id": 2,
      "name": "Saxo Alto en Eb",
      "family": "VIENTO_MADERA",
      "family_display": "Vientos-Madera",
      "afinacion": "Eb",
      "afinacion_display": "Mi bemol",
      "sheet_music_count": 8
    }
  ]
}
```

#### POST /api/v1/instruments/

**Request**:
```json
{
  "name": "Trompeta en Bb",
  "family": "VIENTO_METAL",
  "afinacion": "Bb"
}
```

#### GET /api/v1/instruments/{id}/sheet_music/

**Descripción**: Listar todas las partituras para este instrumento.

**Response** (200 OK):
```json
[
  {
    "id": 1,
    "version_title": "Standard",
    "theme_title": "One Step Beyond",
    "instrument_name": "Trompeta en Bb",
    "type": "MELODIA_PRINCIPAL",
    "clef": "SOL",
    "tonalidad_relativa": "Dm",
    "file": "http://localhost:8000/media/one_step_beyond_standard_trompeta_bb_melodia.pdf"
  }
]
```

---

### 3.3 Versions

#### GET /api/v1/versions/

**Descripción**: Listar todas las versiones (con paginación).

**Query Params**:
- `theme`: Filtrar por theme_id (ej: `?theme=1`)
- `type`: Filtrar por tipo (ej: `?type=STANDARD`)
- `search`: Buscar en titles, notes
- `ordering`: Ordenar (default: `-created_at`)

**Response** (200 OK):
```json
{
  "count": 58,
  "next": "http://localhost:8000/api/v1/versions/?page=2",
  "previous": null,
  "results": [
    {
      "id": 1,
      "theme": 1,
      "theme_title": "One Step Beyond",
      "title": "",
      "type": "STANDARD",
      "type_display": "Standard",
      "image": null,
      "audio_file": "http://localhost:8000/media/one_step_beyond_standard_audio.mp3",
      "mus_file": "http://localhost:8000/media/one_step_beyond_standard_score.mscz",
      "notes": "",
      "sheet_music_count": 5,
      "created_at": "2025-10-24T11:00:00Z",
      "updated_at": "2025-10-24T11:00:00Z"
    }
  ]
}
```

#### GET /api/v1/versions/{id}/

**Descripción**: Detalle completo de una versión (con sheet_music anidados).

**Response** (200 OK):
```json
{
  "id": 1,
  "theme": {
    "id": 1,
    "title": "One Step Beyond",
    "artist": "Madness",
    "tonalidad": "Cm",
    "tonalidad_display": "Do menor",
    "description": "Clásico del ska británico",
    "image": "http://localhost:8000/media/one_step_beyond/theme_image.jpg",
    "audio": "http://localhost:8000/media/one_step_beyond/theme_audio.mp3",
    "versions_count": 3,
    "created_at": "2025-10-24T10:00:00Z",
    "updated_at": "2025-10-24T12:30:00Z"
  },
  "title": "",
  "type": "STANDARD",
  "type_display": "Standard",
  "image": null,
  "audio_file": "http://localhost:8000/media/one_step_beyond_standard_audio.mp3",
  "mus_file": "http://localhost:8000/media/one_step_beyond_standard_score.mscz",
  "notes": "",
  "sheet_music": [
    {
      "id": 1,
      "instrument": {
        "id": 1,
        "name": "Trompeta en Bb",
        "family": "VIENTO_METAL",
        "afinacion": "Bb"
      },
      "type": "MELODIA_PRINCIPAL",
      "type_display": "Melodía Principal",
      "clef": "SOL",
      "clef_display": "Clave de Sol",
      "tonalidad_relativa": "Dm",
      "file": "http://localhost:8000/media/one_step_beyond_standard_trompeta_bb_melodia.pdf",
      "created_at": "2025-10-24T11:30:00Z"
    },
    {
      "id": 2,
      "instrument": {
        "id": 2,
        "name": "Saxo Alto en Eb",
        "family": "VIENTO_MADERA",
        "afinacion": "Eb"
      },
      "type": "MELODIA_PRINCIPAL",
      "type_display": "Melodía Principal",
      "clef": "SOL",
      "clef_display": "Clave de Sol",
      "tonalidad_relativa": "Am",
      "file": "http://localhost:8000/media/one_step_beyond_standard_saxo_alto_melodia.pdf",
      "created_at": "2025-10-24T11:35:00Z"
    }
  ],
  "created_at": "2025-10-24T11:00:00Z",
  "updated_at": "2025-10-24T11:00:00Z"
}
```

#### POST /api/v1/versions/

**Request** (multipart/form-data):
```
theme: 1
type: "STANDARD"
title: ""
notes: ""
audio_file: [binary]
mus_file: [binary]
image: [binary]
```

**Response** (201 Created): Mismo formato que GET detail.

#### GET /api/v1/versions/{id}/sheet_music/

**Descripción**: Listar partituras de una versión.

**Response** (200 OK): Array de SheetMusic objects.

---

### 3.4 SheetMusic

#### GET /api/v1/sheet-music/

**Descripción**: Listar todas las partituras.

**Query Params**:
- `version`: Filtrar por version_id
- `instrument`: Filtrar por instrument_id
- `theme`: Filtrar por theme_id (via version)
- `type`: Filtrar por tipo (MELODIA_PRINCIPAL, ARMONIA, BAJO)
- `clef`: Filtrar por clave (SOL, FA)
- `tonalidad_relativa`: Filtrar por tonalidad escrita
- `search`: Buscar en version title, theme title, instrument name
- `ordering`: Ordenar

**Response** (200 OK):
```json
{
  "count": 123,
  "next": "http://localhost:8000/api/v1/sheet-music/?page=2",
  "previous": null,
  "results": [
    {
      "id": 1,
      "version": 1,
      "version_title": "Standard",
      "theme_title": "One Step Beyond",
      "theme_tonalidad": "Cm",
      "instrument": 1,
      "instrument_name": "Trompeta en Bb",
      "instrument_afinacion": "Bb",
      "type": "MELODIA_PRINCIPAL",
      "type_display": "Melodía Principal",
      "clef": "SOL",
      "clef_display": "Clave de Sol",
      "tonalidad_relativa": "Dm",
      "file": "http://localhost:8000/media/one_step_beyond_standard_trompeta_bb_melodia.pdf",
      "created_at": "2025-10-24T11:30:00Z",
      "updated_at": "2025-10-24T11:30:00Z"
    }
  ]
}
```

#### POST /api/v1/sheet-music/

**Descripción**: Subir una nueva partitura (auto-calcula tonalidad_relativa).

**Request** (multipart/form-data):
```
version: 1
instrument: 1
type: "MELODIA_PRINCIPAL"
clef: "SOL"  (opcional, se auto-sugiere)
file: [binary PDF]
```

**Response** (201 Created):
```json
{
  "id": 1,
  "version": 1,
  "version_title": "Standard",
  "theme_title": "One Step Beyond",
  "theme_tonalidad": "Cm",
  "instrument": 1,
  "instrument_name": "Trompeta en Bb",
  "instrument_afinacion": "Bb",
  "type": "MELODIA_PRINCIPAL",
  "type_display": "Melodía Principal",
  "clef": "SOL",
  "clef_display": "Clave de Sol",
  "tonalidad_relativa": "Dm",  ← AUTO-CALCULADO
  "file": "http://localhost:8000/media/one_step_beyond_standard_trompeta_bb_melodia.pdf",
  "created_at": "2025-10-24T11:30:00Z",
  "updated_at": "2025-10-24T11:30:00Z"
}
```

**Lógica de Auto-Cálculo**:
1. Backend obtiene `version.theme.tonalidad` → "Cm"
2. Backend obtiene `instrument.afinacion` → "Bb"
3. Backend llama `calculate_relative_tonality("Cm", "Bb")` → "Dm"
4. Guarda `tonalidad_relativa = "Dm"`

#### GET /api/v1/sheet-music/{id}/

**Descripción**: Detalle completo de una partitura (con instrument y version anidados).

**Response** (200 OK):
```json
{
  "id": 1,
  "version": {
    "id": 1,
    "theme_title": "One Step Beyond",
    "title": "",
    "type": "STANDARD",
    "type_display": "Standard",
    "sheet_music_count": 5
  },
  "instrument": {
    "id": 1,
    "name": "Trompeta en Bb",
    "family": "VIENTO_METAL",
    "family_display": "Vientos-Metales",
    "afinacion": "Bb",
    "afinacion_display": "Si bemol",
    "sheet_music_count": 12
  },
  "type": "MELODIA_PRINCIPAL",
  "type_display": "Melodía Principal",
  "clef": "SOL",
  "clef_display": "Clave de Sol",
  "tonalidad_relativa": "Dm",
  "file": "http://localhost:8000/media/one_step_beyond_standard_trompeta_bb_melodia.pdf",
  "created_at": "2025-10-24T11:30:00Z",
  "updated_at": "2025-10-24T11:30:00Z"
}
```

#### PUT/PATCH /api/v1/sheet-music/{id}/

**Descripción**: Actualizar partitura (recalcula tonalidad_relativa automáticamente).

#### DELETE /api/v1/sheet-music/{id}/

**Response** (204 No Content)

---

## 4. Events App Endpoints

### 4.1 Locations

#### GET /api/v1/events/locations/

**Query Params**:
- `city`: Filtrar por ciudad
- `capacity`: Filtrar por capacidad (ej: `?capacity__gte=100`)
- `search`: Buscar en name, city, address

**Response** (200 OK):
```json
{
  "count": 8,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 1,
      "name": "Centro Cultural Konex",
      "address": "Sarmiento 3131",
      "city": "Buenos Aires",
      "postal_code": "1196",
      "country": "Argentina",
      "capacity": 500,
      "contact_email": "info@cckonex.org",
      "contact_phone": "+54 11 4864-3200",
      "website": "https://cckonex.org",
      "notes": "",
      "is_active": true,
      "created_at": "2025-10-20T09:00:00Z",
      "updated_at": "2025-10-20T09:00:00Z"
    }
  ]
}
```

#### POST /api/v1/events/locations/

**Permisos**: ✅ IsAdminUser solamente

**Request**:
```json
{
  "name": "Centro Cultural Konex",
  "address": "Sarmiento 3131",
  "city": "Buenos Aires",
  "postal_code": "1196",
  "country": "Argentina",
  "capacity": 500,
  "contact_email": "info@cckonex.org",
  "contact_phone": "+54 11 4864-3200",
  "website": "https://cckonex.org"
}
```

---

### 4.2 Repertoires

#### GET /api/v1/events/repertoires/

**Query Params**:
- `all=true`: Incluir repertorios inactivos (default: solo activos)

**Response** (200 OK):
```json
{
  "count": 5,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 1,
      "name": "Repertorio Jam de Vientos - Noviembre 2025",
      "description": "Repertorio ska y reggae",
      "versions": [
        {
          "version": {
            "id": 1,
            "theme_title": "One Step Beyond",
            "title": "",
            "type": "STANDARD",
            "type_display": "Standard",
            "sheet_music_count": 5
          },
          "order": 1,
          "notes": "",
          "created_at": "2025-10-21T10:00:00Z"
        },
        {
          "version": {
            "id": 2,
            "theme_title": "Madness",
            "title": "",
            "type": "STANDARD",
            "type_display": "Standard",
            "sheet_music_count": 4
          },
          "order": 2,
          "notes": "",
          "created_at": "2025-10-21T10:05:00Z"
        }
      ],
      "version_count": 2,
      "is_active": true,
      "created_at": "2025-10-21T09:00:00Z",
      "updated_at": "2025-10-21T10:05:00Z"
    }
  ]
}
```

#### POST /api/v1/events/repertoires/

**Request**:
```json
{
  "name": "Repertorio Jam de Vientos - Noviembre 2025",
  "description": "Repertorio ska y reggae",
  "versions": [
    {
      "version": 1,
      "order": 1,
      "notes": ""
    },
    {
      "version": 2,
      "order": 2,
      "notes": ""
    }
  ]
}
```

#### DELETE /api/v1/events/repertoires/{id}/

**Comportamiento**: Soft delete (marca `is_active=False`)

**Response** (204 No Content)

---

### 4.3 Events

#### GET /api/v1/events/events/

**Query Params**:
- `start_date`: Filtrar eventos después de fecha (ej: `?start_date=2025-11-01`)
- `end_date`: Filtrar eventos antes de fecha
- `upcoming=true`: Solo eventos futuros
- `ongoing=true`: Solo eventos en curso

**Response** (200 OK):
```json
{
  "count": 12,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 1,
      "title": "Jam de Vientos - Noche de Ska",
      "event_type": "CONCERT",
      "event_type_display": "Concierto",
      "status": "CONFIRMED",
      "status_display": "Confirmado",
      "description": "Una noche de ska y reggae en vivo",
      "start_datetime": "2025-11-15T20:00:00Z",
      "end_datetime": "2025-11-15T23:00:00Z",
      "location": {
        "id": 1,
        "name": "Centro Cultural Konex",
        "city": "Buenos Aires",
        "capacity": 500
      },
      "repertoire": {
        "id": 1,
        "name": "Repertorio Jam de Vientos - Noviembre 2025",
        "version_count": 2
      },
      "is_public": true,
      "max_attendees": null,
      "price": "0.00",
      "is_upcoming": true,
      "is_ongoing": false,
      "created_at": "2025-10-22T14:00:00Z",
      "updated_at": "2025-10-22T14:00:00Z"
    }
  ]
}
```

#### POST /api/v1/events/events/

**Request**:
```json
{
  "title": "Jam de Vientos - Noche de Ska",
  "event_type": "CONCERT",
  "status": "CONFIRMED",
  "description": "Una noche de ska y reggae en vivo",
  "start_datetime": "2025-11-15T20:00:00Z",
  "end_datetime": "2025-11-15T23:00:00Z",
  "location": 1,
  "repertoire": 1,
  "is_public": true,
  "price": "0.00"
}
```

**Validaciones**:
- `start_datetime < end_datetime`
- No se puede crear evento en el pasado

**Errores** (400 Bad Request):
```json
{
  "start_datetime": ["La fecha de inicio debe ser anterior a la de finalización"]
}
```

#### POST /api/v1/events/events/{id}/duplicate/

**Descripción**: Clonar evento como borrador.

**Response** (201 Created): Nuevo evento con `status="DRAFT"`.

#### POST /api/v1/events/events/{id}/cancel/

**Descripción**: Cancelar evento (cambia status a CANCELLED).

**Response** (200 OK): Event actualizado.

#### POST /api/v1/events/events/{id}/complete/

**Descripción**: Marcar evento como completado.

**Response** (200 OK): Event actualizado.

---

## 5. JamDeVientos Public Endpoints (Sin Autenticación)

### 5.1 GET /api/v1/events/jamdevientos/carousel/

**Descripción**: Próximos 10 eventos públicos para carousel.

**Autenticación**: ❌ No requerida (público)

**Response** (200 OK):
```json
{
  "events": [
    {
      "id": 1,
      "title": "Jam de Vientos - Noche de Ska",
      "event_type": "CONCERT",
      "event_type_display": "Concierto",
      "description": "Una noche de ska y reggae en vivo",
      "start_datetime": "2025-11-15T20:00:00Z",
      "end_datetime": "2025-11-15T23:00:00Z",
      "location_name": "Centro Cultural Konex",
      "location_city": "Buenos Aires",
      "repertoire_name": "Repertorio Jam de Vientos - Noviembre 2025"
    }
  ],
  "total": 1
}
```

### 5.2 GET /api/v1/events/jamdevientos/upcoming/

**Descripción**: Todos los eventos públicos próximos con repertorios completos.

**Response** (200 OK):
```json
[
  {
    "id": 1,
    "title": "Jam de Vientos - Noche de Ska",
    "event_type": "CONCERT",
    "status": "CONFIRMED",
    "description": "Una noche de ska y reggae en vivo",
    "start_datetime": "2025-11-15T20:00:00Z",
    "end_datetime": "2025-11-15T23:00:00Z",
    "location": {
      "id": 1,
      "name": "Centro Cultural Konex",
      "address": "Sarmiento 3131",
      "city": "Buenos Aires"
    },
    "repertoire": {
      "id": 1,
      "name": "Repertorio Jam de Vientos - Noviembre 2025",
      "description": "Repertorio ska y reggae",
      "versions": [
        {
          "id": 1,
          "title": "",
          "theme_title": "One Step Beyond",
          "artist": "Madness",
          "tonalidad": "Cm",
          "order": 1,
          "sheet_music_count": 5,
          "audio": "http://localhost:8000/media/one_step_beyond_standard_audio.mp3",
          "image": "http://localhost:8000/media/one_step_beyond/theme_image.jpg",
          "is_visible": true
        }
      ]
    },
    "is_public": true,
    "price": "0.00"
  }
]
```

### 5.3 GET /api/v1/events/jamdevientos/{id}/

**Descripción**: Detalle completo de un evento público específico.

**Response** (200 OK): Mismo formato que `upcoming/` para un solo evento.

**Errores**:
- `404 Not Found`: Evento no existe o no es público

### 5.4 GET /api/v1/events/jamdevientos/{id}/repertoire/

**Descripción**: Solo el repertorio de un evento.

**Response** (200 OK):
```json
{
  "id": 1,
  "name": "Repertorio Jam de Vientos - Noviembre 2025",
  "description": "Repertorio ska y reggae",
  "versions": [
    {
      "id": 1,
      "title": "",
      "theme_title": "One Step Beyond",
      "artist": "Madness",
      "tonalidad": "Cm",
      "order": 1,
      "sheet_music_count": 5,
      "audio": "http://localhost:8000/media/one_step_beyond_standard_audio.mp3",
      "image": "http://localhost:8000/media/one_step_beyond/theme_image.jpg"
    }
  ]
}
```

---

## 6. Endpoints Propuestos (No Implementados)

### 6.1 GET /api/v1/events/jamdevientos/versions/{version_id}/sheet-music/

**Descripción**: Listar todas las partituras disponibles para una versión con metadata de instrumentos y tipos.

**Propósito**: Permitir al frontend de jam-de-vientos saber qué combinaciones instrumento+tipo están disponibles.

**Response Propuesto**:
```json
{
  "version_id": 1,
  "version_title": "One Step Beyond - Standard",
  "theme_tonalidad": "Cm",
  "available_parts": [
    {
      "id": 1,
      "instrument": "Trompeta en Bb",
      "afinacion": "Bb",
      "type": "MELODIA_PRINCIPAL",
      "type_display": "Melodía Principal",
      "clef": "SOL",
      "tonalidad_relativa": "Dm",
      "file_url": "http://localhost:8000/media/one_step_beyond_standard_trompeta_bb_melodia.pdf"
    },
    {
      "id": 2,
      "instrument": "Saxo Alto en Eb",
      "afinacion": "Eb",
      "type": "MELODIA_PRINCIPAL",
      "type_display": "Melodía Principal",
      "clef": "SOL",
      "tonalidad_relativa": "Am",
      "file_url": "http://localhost:8000/media/one_step_beyond_standard_saxo_alto_melodia.pdf"
    },
    {
      "id": 3,
      "instrument": "Tuba",
      "afinacion": "C",
      "type": "BAJO",
      "type_display": "Bajo",
      "clef": "FA",
      "tonalidad_relativa": "Cm",
      "file_url": "http://localhost:8000/media/one_step_beyond_standard_tuba_bajo.pdf"
    }
  ],
  "grouped_by_instrument": {
    "Bb": ["MELODIA_PRINCIPAL", "ARMONIA"],
    "Eb": ["MELODIA_PRINCIPAL"],
    "C": ["BAJO"]
  }
}
```

### 6.2 GET /api/v1/events/jamdevientos/sheet-music/{id}/download/

**Descripción**: Descarga directa del PDF.

**Response**: Binary stream (application/pdf)

**Headers**:
```
Content-Type: application/pdf
Content-Disposition: attachment; filename="One_Step_Beyond_Trompeta_Bb_Melodia_Principal.pdf"
```

**Implementación Propuesta**:
```python
from django.http import FileResponse

@action(detail=False, methods=['get'], url_path='sheet-music/(?P<sm_id>[^/.]+)/download')
def download_sheet_music(self, request, sm_id=None):
    try:
        sheet_music = SheetMusic.objects.get(
            id=sm_id,
            version__repertoires__events__is_public=True
        )
        return FileResponse(
            open(sheet_music.file.path, 'rb'),
            content_type='application/pdf',
            as_attachment=True,
            filename=f"{sheet_music.version.theme.title}_{sheet_music.instrument.name}_{sheet_music.get_type_display()}.pdf"
        )
    except SheetMusic.DoesNotExist:
        return Response({'error': 'Partitura no encontrada'}, status=404)
```

---

## 7. Códigos de Error Comunes

### 7.1 400 Bad Request

**Causas**:
- Datos de formulario inválidos
- Violación de constraints (unique_together)
- Validaciones custom falladas

**Ejemplo**:
```json
{
  "version": ["Este campo es requerido."],
  "instrument": ["Este campo es requerido."]
}
```

### 7.2 401 Unauthorized

**Causas**:
- Token JWT ausente
- Token JWT expirado
- Token JWT inválido

**Response**:
```json
{
  "detail": "Authentication credentials were not provided."
}
```

### 7.3 403 Forbidden

**Causas**:
- Usuario autenticado pero sin permisos
- Intento de crear Location sin ser admin

**Response**:
```json
{
  "detail": "You do not have permission to perform this action."
}
```

### 7.4 404 Not Found

**Causas**:
- Recurso no existe
- Evento no público en endpoints jamdevientos

**Response**:
```json
{
  "detail": "Not found."
}
```

### 7.5 500 Internal Server Error

**Causas**:
- Error en lógica de transposición
- Error al guardar archivos
- Error de base de datos

**Response** (DEBUG=False):
```json
{
  "detail": "Server error. Please contact support."
}
```

---

## 8. Rate Limiting (Propuesto)

**Estado actual**: ❌ No implementado

**Propuesta**:
- 100 requests/minuto para endpoints autenticados
- 20 requests/minuto para endpoints públicos (jamdevientos)

**Headers de respuesta**:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1698156000
```

---

## 9. Versionamiento API

**Versión actual**: v1

**Estrategia**:
- URL-based: `/api/v1/`, `/api/v2/`
- Retrocompatibilidad mantenida dentro de v1
- Breaking changes requieren nueva versión

**Deprecation Policy**:
- Anuncio con 3 meses de anticipación
- Header `Deprecation: true` en respuestas de endpoints obsoletos
- Campo `deprecated_at` en documentación OpenAPI

---

## 10. Documentación Interactiva

### 10.1 Swagger UI

**URL**: `http://localhost:8000/swagger/`

**Características**:
- Exploración interactiva de endpoints
- Prueba de requests desde el navegador
- Autenticación JWT integrada

### 10.2 ReDoc

**URL**: `http://localhost:8000/redoc/`

**Características**:
- Documentación estática elegante
- Búsqueda de endpoints
- Ejemplos de código

---

## 11. Checklist de Contrato API

- [x] Todos los endpoints documentados
- [x] Schemas de request/response completos
- [x] Códigos de estado HTTP especificados
- [x] Parámetros de query explicados
- [x] Validaciones y errores documentados
- [x] Ejemplos reales de uso
- [x] Endpoints públicos vs autenticados claros
- [x] Endpoints propuestos separados de implementados
- [x] Documentación de auto-cálculo de campos

---

**Documento generado**: 2025-10-24
**Última actualización**: 2025-10-24
**Próximo paso**: Documentar estrategias Docker
