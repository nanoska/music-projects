# Sesión 2025-11-04: Implementación Multi-Evento (Incompleta)

**Fecha**: 2025-11-04
**Duración**: ~4 horas
**Estado**: ⚠️ **INCOMPLETO - REQUIERE ROLLBACK**

---

## 🎯 Objetivo de la Sesión

Transformar Jam de Vientos de un sitio de evento único a una plataforma multi-evento con:
- ✅ Backend: Campo `slug` en modelo Event + endpoint `/by-slug/`
- ⚠️ Frontend: Nueva página principal con hero, calendario, eventos
- ❌ **PROBLEMA**: Next.js no compila - se queda colgado en "Starting..."

---

## ✅ Completado - Backend (Sheet-API)

### 1. Modelo Event: Campo Slug

**Archivo**: `sheet-api/backend/events/models.py`

```python
# Líneas 106-112
slug = models.SlugField(
    max_length=100,
    unique=True,
    blank=True,
    verbose_name='Slug',
    help_text='URL amigable generada automáticamente desde el título'
)

# Líneas 178-203 - Método generate_slug()
def generate_slug(self):
    """
    Genera un slug único basado en el título del evento.
    Si el slug ya existe, agrega un contador numérico.
    """
    if not self.title:
        return ''

    # Generar slug base desde el título
    base_slug = slugify(self.title)[:50]
    slug = base_slug
    counter = 1

    # Si estamos actualizando un evento existente, excluirlo de la búsqueda
    queryset = Event.objects.exclude(pk=self.pk) if self.pk else Event.objects.all()

    # Mientras el slug exista, agregar contador
    while queryset.filter(slug=slug).exists():
        slug = f"{base_slug}-{counter}"
        counter += 1
        if len(slug) > 100:
            base_slug = base_slug[:50 - len(str(counter)) - 1]
            slug = f"{base_slug}-{counter}"

    return slug

# Líneas 205-211 - Auto-generación en save()
def save(self, *args, **kwargs):
    if not self.slug:
        self.slug = self.generate_slug()
    self.full_clean()
    super().save(*args, **kwargs)
```

### 2. Migración de Datos

**Archivo**: `sheet-api/backend/events/migrations/0002_event_slug.py`

Migración en 3 pasos:
1. Agregar campo `slug` (sin unique, sin blank)
2. Ejecutar función de migración de datos `generate_slugs_for_existing_events()`
3. Modificar campo para agregar `unique=True` y `blank=True`

**Estado**: ✅ Migración aplicada exitosamente

### 3. Serializers Actualizados

**Archivo**: `sheet-api/backend/events/serializers.py`

Campo `slug` agregado en:
- `EventSerializer` (línea 83, read_only)
- `EventCarouselSerializer` (línea 112)
- `JamDeVientosEventSerializer` (línea 190)

### 4. Nuevo Endpoint API

**Archivo**: `sheet-api/backend/events/views.py` (líneas 208-230)

```python
@action(detail=False, methods=['get'], url_path='by-slug')
def by_slug(self, request):
    """
    Endpoint para obtener un evento por su slug
    GET /api/v1/events/jamdevientos/by-slug/?slug=concierto-primavera-2025
    """
    slug = request.query_params.get('slug')

    if not slug:
        return Response(
            {'error': 'El parámetro "slug" es requerido'},
            status=status.HTTP_400_BAD_REQUEST
        )

    try:
        event = self.get_queryset().get(slug=slug)
        serializer = JamDeVientosEventSerializer(event)
        return Response(serializer.data)
    except Event.DoesNotExist:
        return Response(
            {'error': 'Evento no encontrado'},
            status=status.HTTP_404_NOT_FOUND
        )
```

**Testing**:
```bash
# Backend corriendo en http://localhost:8000
curl "http://localhost:8000/api/v1/events/jamdevientos/by-slug/?slug=test-slug"
```

---

## ⚠️ Incompleto - Frontend (Jam de Vientos)

### Cambios Realizados

#### 1. Cliente API Actualizado

**Archivo**: `jam-de-vientos/frontend/lib/sheetmusic-api.ts`

```typescript
// Líneas 30-46 - Interfaz actualizada
export interface SheetMusicEvent {
  id: number
  title: string
  slug?: string  // ← NUEVO
  event_type: 'CONCERT' | 'REHEARSAL' | 'RECORDING' | 'WORKSHOP' | 'OTHER'
  // ... resto de campos
  is_upcoming?: boolean
  is_ongoing?: boolean
}

// Líneas 127-133 - Nuevo método
async getEventBySlug(slug: string): Promise<SheetMusicEvent> {
  const url = `${this.baseURL}/api/v1/events/jamdevientos/by-slug/?slug=${encodeURIComponent(slug)}`
  return this.fetchWithErrorHandling(url)
}
```

#### 2. Librerías Instaladas

```bash
npm install @fullcalendar/react @fullcalendar/daygrid @fullcalendar/interaction framer-motion
```

**Estado**: ⚠️ Estas librerías pueden estar causando el problema de compilación

#### 3. Archivo de Compatibilidad Creado

**Archivo**: `jam-de-vientos/frontend/lib/api.ts` (NUEVO)

```typescript
// API types and exports for admin components
export interface BackendFile {
  id: string
  name: string
  url: string
  type: 'pdf' | 'audio' | 'image' | 'musescore'
  size?: number
  uploadedAt?: string
}

export { sheetMusicAPI, type SheetMusicEvent, type SheetMusicVersion, type SheetMusicRepertoire } from './sheetmusic-api'
```

**Razón**: Componentes admin importaban `@/lib/api` que no existía

#### 4. Correcciones TypeScript

**Archivo**: `jam-de-vientos/frontend/app/admin/dashboard/page.tsx`

```typescript
// Línea 622 - Cast a any para evitar error de tipos
const events = Array.isArray(allEventsResponse) ? allEventsResponse : ((allEventsResponse as any).events || [])

// Línea 626 - Cast a any
const upcomingEvents = Array.isArray(upcomingResponse) ? upcomingResponse : ((upcomingResponse as any).events || [])

// Línea 740 - Removida prop inexistente
<ProtectedRoute>  // Era: <ProtectedRoute requireAdmin>
```

#### 5. Configuración Next.js Limpiada

**Archivo**: `jam-de-vientos/frontend/next.config.mjs`

```javascript
// REMOVIDO - Causaba problemas:
experimental: {
  optimizePackageImports: ['lucide-react', '@radix-ui/react-icons'],
}
```

**Razón**: El proyecto no usa `lucide-react`, usa iconos custom en `@/components/icons`

---

## ❌ Problema Crítico: Next.js No Compila

### Síntoma

```bash
$ npm run dev

> jam-de-vientos@0.1.0 dev
> next dev

  ▲ Next.js 14.2.32
  - Local:        http://localhost:3000

 ✓ Starting...
# SE QUEDA COLGADO AQUÍ INDEFINIDAMENTE
```

### Diagnóstico Realizado

1. ✅ Errores TypeScript corregidos: `npx tsc --noEmit` pasa
2. ✅ Cache limpiado: `rm -rf .next`
3. ✅ Procesos matados: `pkill -9 node`
4. ✅ Configuración simplificada: Removido `experimental.optimizePackageImports`
5. ❌ **El problema persiste**

### Hipótesis

1. **Conflicto con librerías nuevas**: FullCalendar o Framer Motion incompatibles con Next.js 14.2.32
2. **Corrupción en node_modules**: Necesita `rm -rf node_modules && npm install`
3. **Página nueva muy compleja**: La página `app/page.tsx` tiene demasiada lógica en el primer render
4. **Issue de Next.js**: Bug conocido en versión 14.2.32

### Estado del Código

**Archivo actual**: `jam-de-vientos/frontend/app/page.tsx`
**Estado**: Restaurado a versión original con carousel (desde git)
**Backup creado**: `app/page.tsx.original` (nueva portada multi-evento)

---

## 🔄 Plan de Recuperación - Próxima Sesión

### Opción 1: Rollback Completo (Recomendado)

#### Paso 1: Identificar Commit Estable

```bash
cd /home/nano/nahue/satori/porfolio/portfolio-apps/music-projects/jam-de-vientos

# Ver historial de commits
git log --oneline -10

# Ver estado actual
git status

# Ver últimos commits estables (antes de hoy)
git log --before="2025-11-04" --oneline -5
```

#### Paso 2: Rollback del Frontend

```bash
# Opción A: Revert completo a commit anterior
git reset --hard <commit-hash-estable>

# Opción B: Solo revertir archivos específicos
git checkout <commit-hash-estable> -- frontend/app/page.tsx
git checkout <commit-hash-estable> -- frontend/lib/
git checkout <commit-hash-estable> -- frontend/package.json
git checkout <commit-hash-estable> -- frontend/package-lock.json
git checkout <commit-hash-estable> -- frontend/next.config.mjs

# Limpiar node_modules y reinstalar
rm -rf frontend/node_modules frontend/package-lock.json
npm install
```

#### Paso 3: Mantener Backend (Está Funcional)

El backend de sheet-api **NO necesita rollback**. Todo está funcionando correctamente:
- ✅ Migración aplicada
- ✅ Endpoint `/by-slug/` funcionando
- ✅ Sin errores

**Solo preservar estos cambios del backend**:
- `sheet-api/backend/events/models.py` (campo slug)
- `sheet-api/backend/events/serializers.py` (slug en serializers)
- `sheet-api/backend/events/views.py` (endpoint by-slug)
- `sheet-api/backend/events/migrations/0002_event_slug.py`

#### Paso 4: Verificar Funcionamiento

```bash
# Backend (Sheet-API)
cd sheet-api/backend
python3 manage.py runserver
# → http://localhost:8000 debe funcionar

# Frontend (Jam de Vientos)
cd jam-de-vientos/frontend
npm run dev
# → http://localhost:3000 debe compilar y funcionar
```

### Opción 2: Reinstalar Dependencias

Si no quieres hacer rollback completo:

```bash
cd jam-de-vientos/frontend

# Limpiar completamente
rm -rf node_modules package-lock.json .next

# Reinstalar sin las librerías nuevas
npm uninstall @fullcalendar/react @fullcalendar/daygrid @fullcalendar/interaction framer-motion

# Reinstalar dependencias
npm install

# Probar
npm run dev
```

Si esto funciona, entonces el problema son las librerías de FullCalendar o Framer Motion.

### Opción 3: Enfoque Incremental (Para Futuro)

Una vez que el sitio vuelva a funcionar:

1. **Crear rama de desarrollo**:
   ```bash
   git checkout -b feature/multi-evento-incremental
   ```

2. **Implementar cambios de a uno**:
   - Día 1: Solo agregar ruta `[eventSlug]/page.tsx` (sin cambiar portada)
   - Día 2: Agregar componentes simples (sin librerías externas)
   - Día 3: Probar FullCalendar en página separada `/eventos`
   - Día 4: Integrar todo

3. **Testear después de cada cambio**:
   ```bash
   npm run dev
   # Si funciona → commit
   # Si no funciona → revert y buscar alternativa
   ```

---

## 📝 Commits y Estado del Repositorio

### Sheet-API (Backend)

**Branch**: main
**Estado**: ✅ Funcionando correctamente

```bash
cd sheet-api
git log --oneline -3
# a3310d8 (HEAD -> main) pusheo proxima sessions
# b3f59a2 docs: add final comprehensive session summary
# fee1db0 docs: add git setup and push documentation
```

**Cambios a preservar**:
- `backend/events/models.py` (+60 líneas aprox)
- `backend/events/serializers.py` (+3 campos slug)
- `backend/events/views.py` (+23 líneas método by_slug)
- `backend/events/migrations/0002_event_slug.py` (+79 líneas)

### Jam de Vientos (Frontend)

**Branch**: main
**Estado**: ❌ No compila

```bash
cd jam-de-vientos
git status
# Modified:
#   frontend/app/admin/dashboard/page.tsx
#   frontend/app/page.tsx (restaurado pero no funciona)
#   frontend/lib/sheetmusic-api.ts
#   frontend/next.config.mjs
#   frontend/package.json

# Untracked:
#   frontend/lib/api.ts (nuevo)
#   frontend/app/page.tsx.original (backup)
```

**Último commit estable** (buscar en próxima sesión):
```bash
git log --before="2025-11-04" --oneline -3
```

---

## 🛠️ Archivos Modificados - Resumen

### Sheet-API ✅
| Archivo | Estado | Líneas | Descripción |
|---------|--------|--------|-------------|
| `events/models.py` | ✅ OK | +60 | Campo slug + generate_slug() |
| `events/serializers.py` | ✅ OK | +3 | Slug en 3 serializers |
| `events/views.py` | ✅ OK | +23 | Endpoint by_slug() |
| `events/migrations/0002_event_slug.py` | ✅ OK | +79 | Migración de datos |

### Jam de Vientos ⚠️
| Archivo | Estado | Problema |
|---------|--------|----------|
| `lib/sheetmusic-api.ts` | ⚠️ | Tipos + método getEventBySlug() |
| `lib/api.ts` | ⚠️ | Nuevo archivo, puede causar conflicto |
| `app/page.tsx` | ❌ | Restaurado pero Next.js no compila |
| `app/admin/dashboard/page.tsx` | ⚠️ | Casts a `any` |
| `next.config.mjs` | ⚠️ | Experimental config removida |
| `package.json` | ❌ | Librerías nuevas instaladas |

---

## 🎓 Lecciones Aprendidas

### 1. Testing Incremental es Crítico

**Error cometido**: Instalamos librerías + modificamos múltiples archivos sin testear entre cambios.

**Solución futura**: Después de cada cambio significativo:
```bash
npm run dev  # Verificar que compile
git add .
git commit -m "descripción del cambio"
```

### 2. Librerías Externas Requieren Validación

**Error cometido**: Instalamos FullCalendar y Framer Motion sin verificar compatibilidad con Next.js 14.2.32.

**Solución futura**:
1. Crear rama de prueba
2. Instalar librería
3. Crear página de prueba simple
4. Solo si funciona → integrar al proyecto principal

### 3. Next.js Experimental Config es Peligroso

**Error cometido**: `next.config.mjs` tenía `optimizePackageImports` para librerías que no usábamos.

**Solución futura**: Limpiar configuración experimental regularmente.

### 4. Backups Before Major Changes

**Error cometido**: No creamos snapshot del estado funcional antes de comenzar.

**Solución futura**:
```bash
git checkout -b snapshot-before-multi-evento
git add .
git commit -m "Snapshot: Estado funcional antes de multi-evento"
git checkout main
```

---

## 🚀 Próximos Pasos - Sesión Siguiente

### Prioridad 1: Recuperar Estado Funcional (30 min - 1h)

1. **Identificar commit estable**
2. **Rollback completo de jam-de-vientos/frontend**
3. **Verificar que compila**: `npm run dev` debe funcionar
4. **Crear snapshot**: Branch de respaldo del estado funcional

### Prioridad 2: Enfoque Incremental (Si queda tiempo)

Una vez recuperado el estado funcional, implementar **solo** la ruta dinámica:

1. Crear `app/[eventSlug]/page.tsx` (copiar código actual de `app/page.tsx`)
2. Modificar `app/page.tsx` para que sea una portada SUPER simple:
   ```typescript
   export default function HomePage() {
     return <div>Portada temporal - ver /[eventSlug]</div>
   }
   ```
3. Testear: `npm run dev` debe funcionar
4. Commit

### Prioridad 3: Documentar Rollback (Si queda tiempo)

Crear `sessions/2025-11-04/ROLLBACK.md` con los comandos exactos usados.

---

## 📚 Referencias

- [Roadmap v2.0](../proxima/roadmap-jam-vientos-v2.md) - Plan original multi-evento
- [Plan de Producción](../proxima/plan-produccion.md) - Fases 1-10
- [Sesión 2025-10-24](../2025-10-24/FINAL-SUMMARY.md) - Análisis de arquitectura

---

## ⚠️ IMPORTANTE - Estado Final

**Backend Sheet-API**: ✅ **FUNCIONANDO** - NO hacer rollback
**Frontend Jam de Vientos**: ❌ **NO FUNCIONA** - REQUIERE rollback completo

**Comando de Emergencia**:
```bash
cd jam-de-vientos
git reset --hard <commit-antes-de-2025-11-04>
rm -rf frontend/node_modules frontend/.next
cd frontend && npm install
npm run dev  # Debe funcionar
```

---

*Sesión documentada el 2025-11-04*
*Estado: INCOMPLETO - Requiere rollback en próxima sesión*
