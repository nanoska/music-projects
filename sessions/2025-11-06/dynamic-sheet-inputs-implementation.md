# Dynamic Sheet Music Input System - SheetAPI

**Fecha:** 2025-11-06
**Proyecto:** sheet-api
**Rama:** feature/dynamic-sheet-inputs
**Estado:** Completado

## Resumen

Implementación de un sistema dinámico de inputs de partituras que varía según el tipo de versión musical. El sistema permite workflows especializados para diferentes tipos de arreglos: Standard, Dueto, Grupo Reducido y Ensamble.

## Objetivos Cumplidos

✅ Crear diccionario de configuración VERSION_TYPE_CONFIG
✅ Implementar componentes especializados por tipo de versión
✅ Agregar validaciones de cantidad de instrumentos
✅ Integrar con modelos existentes (SheetMusic y VersionFile)
✅ Mantener compatibilidad con API existente
✅ Documentar cambios en CLAUDE.md

## Cambios Técnicos

### Frontend

**Archivo:** `frontend/src/components/managers/VersionManager.tsx`

#### 1. Diccionario de Configuración (línea 42)

```typescript
const VERSION_TYPE_CONFIG = {
  STANDARD: {
    model: 'SheetMusic',
    fields: ['instrument', 'type', 'clef', 'file'],
    types: [
      { value: 'MELODIA_PRINCIPAL', label: 'Melodía Principal' },
      { value: 'MELODIA_SECUNDARIA', label: 'Melodía Secundaria' },
      { value: 'ARMONIA', label: 'Armonía' },
      { value: 'BAJO', label: 'Bajo' },
    ],
    clefs: [
      { value: 'SOL', label: 'Clave de Sol' },
      { value: 'FA', label: 'Clave de Fa' },
    ],
  },
  DUETO: {
    model: 'VersionFile',
    fileType: 'DUETO_TRANSPOSITION',
    fields: ['tuning', 'file', 'audio'],
    tunings: [
      { value: 'Bb', label: 'Si bemol - Clave de Sol' },
      { value: 'Eb', label: 'Mi bemol - Clave de Sol' },
      { value: 'F', label: 'Fa - Clave de Sol' },
      { value: 'C', label: 'Do - Clave de Sol' },
      { value: 'C_BASS', label: 'Do - Clave de Fa (Bass)' },
    ],
  },
  GRUPO_REDUCIDO: {
    model: 'VersionFile',
    fileType: 'STANDARD_SCORE',
    fields: ['instrument', 'file', 'audio'],
    minInstruments: 2,
    maxInstruments: 5,
  },
  ENSAMBLE: {
    model: 'VersionFile',
    fileType: 'ENSAMBLE_INSTRUMENT',
    fields: ['instrument', 'file', 'audio'],
    minInstruments: 6,
    maxInstruments: undefined,
  },
};
```

#### 2. Componentes Creados

**SheetMusicForVersion (línea 488):** Router principal
- Carga datos de la versión
- Switch statement para rutear al componente apropiado según tipo

**StandardSheetForm (línea 529):** Formulario para versiones Standard
- Mantiene funcionalidad original de SheetMusic
- Campos: Instrumento, Tipo de parte, Clave, PDF

**DuetoForm (línea 750):** Formulario para versiones Dueto
- Upload de archivos por transposición (Bb, Eb, F, C, C_BASS)
- Campos: Transposición, PDF, Audio opcional, Descripción
- Usa modelo VersionFile con file_type='DUETO_TRANSPOSITION'

**MultiInstrumentForm (línea 977):** Formulario para Grupo Reducido y Ensamble
- Componente compartido con prop `versionType`
- Validación de cantidad de instrumentos (2-5 para Grupo Reducido, 6+ para Ensamble)
- Campos: Instrumento, PDF, Audio opcional, Descripción
- Feedback visual del progreso (contador de instrumentos)

### Backend

No se requirieron cambios en el backend. El sistema utiliza:
- **Modelo SheetMusic** (existente): Para versiones STANDARD
- **Modelo VersionFile** (existente): Para DUETO, GRUPO_REDUCIDO, ENSAMBLE

Las validaciones y constraints ya estaban implementados en `backend/music/models.py`.

### API Integration

Métodos ya existentes en `frontend/src/services/api.ts`:
- `getVersionFiles(params)` - línea 282
- `createVersionFile(formData)` - línea 309
- `deleteVersionFile(id)` - línea 327

## Flujo de Usuario por Tipo

### STANDARD
1. Usuario crea versión tipo "Standard"
2. Click en botón "View Sheets"
3. Formulario muestra: Instrumento + Tipo + Clave + PDF
4. Upload individual por instrumento y tipo de parte
5. Sistema usa modelo SheetMusic con constraint (version, instrument, type)

### DUETO
1. Usuario crea versión tipo "Dueto"
2. Click en botón "View Sheets"
3. Formulario muestra selector de transposición y dropzones
4. Upload de 4-5 PDFs (uno por cada transposición común)
5. Audio opcional por transposición
6. Sistema usa VersionFile con constraint (version, tuning)

### GRUPO REDUCIDO
1. Usuario crea versión tipo "Grupo Reducido"
2. Click en botón "View Sheets"
3. Formulario muestra selector de instrumento + dropzones
4. Upload de 2-5 partituras (una por instrumento)
5. Validación: Mínimo 2, máximo 5 instrumentos
6. Contador visual "X/5 instrumentos"
7. Sistema usa VersionFile con file_type='STANDARD_SCORE'

### ENSAMBLE
1. Usuario crea versión tipo "Ensamble"
2. Click en botón "View Sheets"
3. Formulario muestra selector de instrumento + dropzones
4. Upload de 6+ partituras (una por instrumento)
5. Validación: Mínimo 6 instrumentos, sin máximo
6. Contador visual "X instrumentos"
7. Sistema usa VersionFile con file_type='ENSAMBLE_INSTRUMENT'

## Validaciones Implementadas

### Frontend
- Validación de campos requeridos (instrumento/transposición + archivo)
- Contador de instrumentos para Grupo Reducido y Ensamble
- Deshabilitar botón "Agregar" cuando se alcanza el máximo (Grupo Reducido)
- Mensajes de error claros para el usuario

### Backend (Existente)
- Unique constraints por tipo de versión
- Validación de file_type matching version.type
- Clean() method con ValidationError detallados

## Mejoras UX

1. **Feedback Visual:**
   - Chips de audio cuando un archivo tiene audio asociado
   - Contadores de progreso para multi-instrumento
   - Alertas de validación (warning/error)

2. **Consistencia:**
   - Mismo diseño Material-UI en todos los formularios
   - Drag-and-drop en todos los uploads
   - Iconografía consistente (Download, Delete)

3. **Accesibilidad:**
   - Labels claros en todos los campos
   - Mensajes de error descriptivos
   - Estados disabled cuando corresponde

## Testing Realizado

- ✅ Verificación de errores TypeScript (0 errores)
- ⏳ Testing manual pendiente (requiere backend running)

## Archivos Modificados

1. `frontend/src/components/managers/VersionManager.tsx`
   - +800 líneas (3 nuevos componentes + configuración)

2. `sheet-api/CLAUDE.md`
   - Nueva sección "Dynamic Sheet Music Input System (2025)"
   - Documentación completa de arquitectura y flujos

## Documentación

### Proyecto
- ✅ CLAUDE.md actualizado con sección completa
- ✅ Código comentado con JSDoc donde apropiado

### Repositorio General
- ✅ Session log en `/sessions/2025-11-06/`
- ⏳ Pendiente: Push a repo nanoska/music-projects

## Próximos Pasos

### Testing
1. Levantar backend Django
2. Levantar frontend React
3. Crear versiones de cada tipo
4. Probar flujo completo de upload
5. Verificar validaciones
6. Probar descarga y eliminación

### Mejoras Futuras

1. **Bulk Upload:** Permitir subir múltiples archivos de una vez
2. **Auto-suggestion:** Sugerir transposiciones/instrumentos faltantes
3. **Preview:** Vista previa de PDFs antes de subir
4. **Batch Download:** Descargar todos los archivos de una versión como ZIP
5. **Templates:** Plantillas de configuración por tipo de ensamble

## Lecciones Aprendidas

1. **Enfoque Híbrido:** Usar modelos existentes (SheetMusic + VersionFile) fue la decisión correcta vs. crear nuevos modelos
2. **Configuración Declarativa:** El diccionario VERSION_TYPE_CONFIG hace el código extensible y mantenible
3. **Componentes Compartidos:** MultiInstrumentForm sirve para dos tipos diferentes ahorrando código
4. **TypeScript Strictness:** Agregar `maxInstruments: undefined` para mantener consistencia de tipos

## Comandos Git

```bash
# Crear rama
git checkout -b feature/dynamic-sheet-inputs

# Commit
git add frontend/src/components/managers/VersionManager.tsx
git add sheet-api/CLAUDE.md
git commit -m "feat: add dynamic sheet music input system

- Implement VERSION_TYPE_CONFIG dictionary
- Add StandardSheetForm, DuetoForm, MultiInstrumentForm components
- Add instrument count validation for GRUPO_REDUCIDO and ENSAMBLE
- Update CLAUDE.md with comprehensive documentation
- Support for transposition-based uploads (DUETO)
- Support for multi-instrument uploads (GRUPO_REDUCIDO, ENSAMBLE)

🤖 Generated with Claude Code"

# Merge a main
git checkout main
git merge feature/dynamic-sheet-inputs
git branch -d feature/dynamic-sheet-inputs
```

## Contacto / Referencias

- Modelo VersionFile: `backend/music/models.py:143`
- Modelo SheetMusic: `backend/music/models.py:112`
- API Services: `frontend/src/services/api.ts:281-329`
- Version Types: `backend/music/models.py:88`

---

**Desarrollado por:** Claude Code
**Session ID:** 2025-11-06-dynamic-sheet-inputs
**Duración estimada:** 2-3 horas
