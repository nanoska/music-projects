# Roadmap: Jam de Vientos v2.0 - Plataforma Multi-Evento con Lector Avanzado

**Fecha**: 2025-11-02
**Versión**: 2.0 (Propuesta)
**Estado**: 📝 Documentación - No implementado
**Prioridad**: Alta (post-producción v1.0)

---

## Índice

1. [Visión General](#visión-general)
2. [Arquitectura de URLs Dinámicas](#arquitectura-de-urls-dinámicas)
3. [Página Portada](#página-portada)
4. [Lector de Partituras Avanzado](#lector-de-partituras-avanzado)
5. [Stack Tecnológico Adicional](#stack-tecnológico-adicional)
6. [Endpoints API Necesarios](#endpoints-api-necesarios)
7. [Plan de Implementación](#plan-de-implementación)
8. [Consideraciones Técnicas](#consideraciones-técnicas)
9. [Cronograma y Recursos](#cronograma-y-recursos)

---

## Visión General

### Situación Actual (v1.0)

Jam de Vientos v1.0 es un sitio de **visualización única**:
- Una sola página con carousel de un evento seleccionado desde el admin dashboard
- Enfoque en mostrar el próximo evento importante
- Funcionalidad básica: carousel + detalles de temas + reproducción audio
- URL estática: `jamdevientos.com`

### Visión v2.0

Transformar Jam de Vientos en una **plataforma completa** para:
- **Músicos**: Acceder a partituras de cualquier evento, leerlas en móvil con herramientas profesionales
- **Público**: Explorar calendario de eventos, conocer la jam, ver galería de fotos
- **Organización**: Tener presencia web profesional con múltiples eventos activos

### Objetivos v2.0

1. **Multi-Evento**: Soporte para múltiples eventos simultáneos con URLs únicas
2. **Portada Profesional**: Página de presentación institucional
3. **Navegación Avanzada**: Calendario interactivo y exploración de eventos
4. **Lector de Partituras**: Herramienta profesional para músicos en móvil
5. **SEO y Compartir**: URLs amigables y metadata optimizada

---

## Arquitectura de URLs Dinámicas

### Estructura de Rutas v2.0

```
jamdevientos.com/
├── /                                    # Portada principal
├── /eventos                             # Calendario/lista de eventos
├── /sobre-nosotros                      # Información de la jam
├── /galeria                             # Galería de fotos/videos
│
├── /{evento-slug}                       # Página del evento
│   ├── carousel de temas
│   ├── detalles del evento
│   └── lista de partituras
│
└── /{evento-slug}/partituras/{version-id}   # Lector de partituras
    ├── visualización PDF
    ├── controles de reproducción
    ├── metrónomo
    └── herramientas de lectura
```

### Generación de Slugs

**Reglas**:
- Basado en el título del evento
- Lowercase, sin acentos, espacios → guiones
- Máximo 50 caracteres
- Único por evento

**Ejemplos**:
```
"Concierto de Primavera 2025" → "concierto-de-primavera-2025"
"Ensayo General - Junio"      → "ensayo-general-junio"
"Jam Session #3"              → "jam-session-3"
```

**Implementación**:
```typescript
function generateSlug(title: string): string {
  return title
    .toLowerCase()
    .normalize('NFD').replace(/[\u0300-\u036f]/g, '') // Quitar acentos
    .replace(/[^\w\s-]/g, '') // Quitar caracteres especiales
    .replace(/\s+/g, '-') // Espacios → guiones
    .replace(/--+/g, '-') // Múltiples guiones → uno
    .substring(0, 50) // Máximo 50 chars
    .replace(/^-+|-+$/g, ''); // Quitar guiones al inicio/fin
}
```

### Routing en Next.js

**App Router Structure**:
```
app/
├── page.tsx                             # Portada
├── eventos/
│   └── page.tsx                         # Lista de eventos
├── sobre-nosotros/
│   └── page.tsx                         # Sobre la jam
├── galeria/
│   └── page.tsx                         # Galería
├── [eventSlug]/
│   ├── page.tsx                         # Página del evento (carousel)
│   └── partituras/
│       └── [versionId]/
│           └── page.tsx                 # Lector de partituras
```

**Dynamic Route Example** (`app/[eventSlug]/page.tsx`):
```typescript
export async function generateStaticParams() {
  const events = await sheetMusicAPI.getEvents()
  return events.map(event => ({
    eventSlug: event.slug
  }))
}

export default async function EventPage({ params }: { params: { eventSlug: string } }) {
  const event = await sheetMusicAPI.getEventBySlug(params.eventSlug)
  return <EventCarouselView event={event} />
}
```

### Consideraciones SEO

**Metadata Dinámica**:
```typescript
export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const event = await getEvent(params.eventSlug)

  return {
    title: `${event.title} | Jam de Vientos`,
    description: event.description || `Repertorio del evento ${event.title}`,
    openGraph: {
      title: event.title,
      description: event.description,
      images: event.repertoire?.versions[0]?.image ? [event.repertoire.versions[0].image] : [],
      type: 'website',
    },
    twitter: {
      card: 'summary_large_image',
      title: event.title,
      description: event.description,
    }
  }
}
```

---

## Página Portada

### Hero Section

**Diseño**:
- Background: Imagen del próximo evento o imagen genérica de la jam
- Overlay con gradiente oscuro para legibilidad
- Contenido centrado:
  - Logo/nombre de Jam de Vientos
  - Tagline: "Música de viento en comunidad"
  - Próximo evento destacado con countdown
  - CTA: "Ver Repertorio" → Link al evento

**Componente** (`components/home/hero-section.tsx`):
```typescript
interface HeroSectionProps {
  upcomingEvent: SheetMusicEvent | null
}

export function HeroSection({ upcomingEvent }: HeroSectionProps) {
  return (
    <section className="relative h-screen">
      {/* Background image */}
      <div className="absolute inset-0">
        <Image
          src={upcomingEvent?.image || '/default-hero.jpg'}
          alt="Hero"
          fill
          className="object-cover"
        />
        <div className="absolute inset-0 bg-gradient-to-b from-black/60 to-black/30" />
      </div>

      {/* Content */}
      <div className="relative z-10 flex flex-col items-center justify-center h-full">
        <h1 className="text-6xl font-bold text-white mb-4">Jam de Vientos</h1>
        <p className="text-xl text-gray-200 mb-8">Música de viento en comunidad</p>

        {upcomingEvent && (
          <div className="bg-white/10 backdrop-blur-lg rounded-lg p-6 max-w-md">
            <p className="text-sm text-gray-300 mb-2">Próximo evento</p>
            <h2 className="text-2xl font-semibold text-white mb-4">
              {upcomingEvent.title}
            </h2>
            <EventCountdown date={upcomingEvent.start_datetime} />
            <Link href={`/${upcomingEvent.slug}`}>
              <Button size="lg" className="w-full mt-4">
                Ver Repertorio
              </Button>
            </Link>
          </div>
        )}
      </div>
    </section>
  )
}
```

### Calendario Interactivo

**Librería recomendada**: [FullCalendar](https://fullcalendar.io/) o [React Big Calendar](https://github.com/jquense/react-big-calendar)

**Características**:
- Vista mensual con eventos marcados
- Click en evento → Modal con detalles + CTA "Ver Repertorio"
- Responsive: móvil muestra lista, desktop muestra calendario
- Sincronizado con Sheet-API

**Componente** (`components/home/events-calendar.tsx`):
```typescript
import FullCalendar from '@fullcalendar/react'
import dayGridPlugin from '@fullcalendar/daygrid'
import interactionPlugin from '@fullcalendar/interaction'

export function EventsCalendar({ events }: { events: SheetMusicEvent[] }) {
  const calendarEvents = events.map(event => ({
    id: event.id.toString(),
    title: event.title,
    start: event.start_datetime,
    end: event.end_datetime,
    url: `/${event.slug}`,
    backgroundColor: getEventColor(event.event_type),
  }))

  return (
    <section className="py-16 px-4">
      <h2 className="text-4xl font-bold text-center mb-12">Calendario de Eventos</h2>
      <div className="max-w-6xl mx-auto">
        <FullCalendar
          plugins={[dayGridPlugin, interactionPlugin]}
          initialView="dayGridMonth"
          events={calendarEvents}
          locale="es"
          headerToolbar={{
            left: 'prev,next today',
            center: 'title',
            right: 'dayGridMonth,dayGridWeek'
          }}
          eventClick={(info) => {
            info.jsEvent.preventDefault()
            // Abrir modal o navegar
            router.push(info.event.url)
          }}
        />
      </div>
    </section>
  )
}
```

### Sección "Sobre Nosotros"

**Contenido**:
- Historia de la jam
- Misión y valores
- Equipo/músicos destacados
- Contacto

**Diseño**:
- Layout tipo revista con imágenes
- Timeline de historia (opcional)
- Cards de músicos/directores

### Galería de Eventos Pasados

**Características**:
- Grid masonry de fotos
- Lightbox para ver imágenes en grande
- Filtros por año/tipo de evento
- Lazy loading

**Librería**: [PhotoSwipe](https://photoswipe.com/) o [React Image Gallery](https://github.com/xiaolin/react-image-gallery)

---

## Lector de Partituras Avanzado

### Visión del Lector

Un **visor de partituras optimizado para músicos** que permite:
- Leer partituras en PDF en el móvil durante ensayos/conciertos
- Sincronizar lectura con audio de la pieza
- Ajustar tempo para practicar
- Usar metrónomo para mantener tempo
- Modo performance (fullscreen, no sleep)

### Arquitectura Técnica

#### Stack Base

**Renderizado PDF**:
- **PDF.js**: Librería estándar para renderizar PDFs en web
- **react-pdf**: Wrapper React para PDF.js

**Audio**:
- **Web Audio API**: Control preciso de reproducción y tempo
- **Tone.js** (opcional): Wrapper de alto nivel para audio

**Metrónomo**:
- **Web Audio API**: Generar clicks con precisión
- **AudioContext**: Buffer de sonidos de click

**State Management**:
- **Zustand** o **Context API**: Estado del reproductor
- **React Query**: Fetch de PDFs y audio

#### Componentes Principales

```
components/sheet-music-reader/
├── SheetMusicReader.tsx          # Componente principal
├── PDFViewer.tsx                 # Renderizado del PDF
├── AudioPlayer.tsx               # Reproductor con tempo control
├── Metronome.tsx                 # Metrónomo visual y audible
├── ControlPanel.tsx              # Controles (play, tempo, zoom)
├── PageNavigator.tsx             # Navegación de páginas
└── PerformanceMode.tsx           # Modo fullscreen
```

### Funcionalidades Detalladas

#### 1. Visualización PDF

**Features**:
- Renderizado de alta calidad
- Zoom: pinch, botones +/-, fit-to-width, fit-to-page
- Navegación: swipe, botones prev/next, thumbnail sidebar
- Orientación: portrait/landscape automático
- Calidad adaptativa según viewport

**Implementación** (`components/sheet-music-reader/PDFViewer.tsx`):
```typescript
import { Document, Page, pdfjs } from 'react-pdf'
import 'react-pdf/dist/Page/AnnotationLayer.css'
import 'react-pdf/dist/Page/TextLayer.css'

pdfjs.GlobalWorkerOptions.workerSrc = `//cdnjs.cloudflare.com/ajax/libs/pdf.js/${pdfjs.version}/pdf.worker.min.js`

interface PDFViewerProps {
  pdfUrl: string
  currentPage: number
  onPageChange: (page: number) => void
  zoom: number
}

export function PDFViewer({ pdfUrl, currentPage, onPageChange, zoom }: PDFViewerProps) {
  const [numPages, setNumPages] = useState<number>(0)
  const containerRef = useRef<HTMLDivElement>(null)

  return (
    <div ref={containerRef} className="relative w-full h-full overflow-auto">
      <Document
        file={pdfUrl}
        onLoadSuccess={({ numPages }) => setNumPages(numPages)}
        loading={<LoadingSpinner />}
      >
        <Page
          pageNumber={currentPage}
          scale={zoom}
          renderTextLayer={false}
          renderAnnotationLayer={false}
          className="mx-auto"
        />
      </Document>

      {/* Page indicator */}
      <div className="absolute bottom-4 left-1/2 -translate-x-1/2 bg-black/70 text-white px-4 py-2 rounded-full">
        {currentPage} / {numPages}
      </div>
    </div>
  )
}
```

#### 2. Scrolling Automático Sincronizado

**Concepto**:
- Al reproducir el audio, las páginas avanzan automáticamente
- Basado en marcas de tiempo por página (configurables)
- Smooth transition entre páginas

**Configuración**:
```typescript
interface PageTimestamp {
  page: number
  timestamp: number // segundos desde el inicio
}

// Ejemplo: una pieza de 3 minutos, 4 páginas
const pageTimestamps: PageTimestamp[] = [
  { page: 1, timestamp: 0 },
  { page: 2, timestamp: 45 },
  { page: 3, timestamp: 90 },
  { page: 4, timestamp: 135 },
]
```

**Implementación**:
```typescript
function useAutoScroll(
  audioCurrentTime: number,
  pageTimestamps: PageTimestamp[],
  isPlaying: boolean
) {
  const [currentPage, setCurrentPage] = useState(1)

  useEffect(() => {
    if (!isPlaying) return

    // Encontrar página actual basada en timestamp
    const targetPage = pageTimestamps
      .reverse()
      .find(pt => audioCurrentTime >= pt.timestamp)
      ?.page || 1

    if (targetPage !== currentPage) {
      setCurrentPage(targetPage)
    }
  }, [audioCurrentTime, isPlaying, pageTimestamps])

  return currentPage
}
```

#### 3. Control de Tempo

**Features**:
- Slider de tempo: 0.5x - 2.0x (50% - 200%)
- Presets: 0.5x, 0.75x, 1.0x, 1.25x, 1.5x, 2.0x
- Preservar pitch (no chipmunk effect)
- Display de BPM actual

**Implementación con Web Audio API**:
```typescript
class AudioPlayerWithTempo {
  private audioContext: AudioContext
  private sourceNode: AudioBufferSourceNode | null = null
  private audioBuffer: AudioBuffer | null = null
  private playbackRate: number = 1.0
  private startTime: number = 0
  private pauseTime: number = 0

  constructor() {
    this.audioContext = new AudioContext()
  }

  async loadAudio(url: string) {
    const response = await fetch(url)
    const arrayBuffer = await response.arrayBuffer()
    this.audioBuffer = await this.audioContext.decodeAudioData(arrayBuffer)
  }

  play() {
    if (!this.audioBuffer) return

    this.sourceNode = this.audioContext.createBufferSource()
    this.sourceNode.buffer = this.audioBuffer
    this.sourceNode.playbackRate.value = this.playbackRate
    this.sourceNode.connect(this.audioContext.destination)

    this.sourceNode.start(0, this.pauseTime)
    this.startTime = this.audioContext.currentTime - this.pauseTime
  }

  pause() {
    if (this.sourceNode) {
      this.pauseTime = this.audioContext.currentTime - this.startTime
      this.sourceNode.stop()
      this.sourceNode = null
    }
  }

  setTempo(rate: number) {
    const wasPlaying = this.sourceNode !== null
    if (wasPlaying) this.pause()

    this.playbackRate = rate

    if (wasPlaying) this.play()
  }

  getCurrentTime(): number {
    if (this.sourceNode) {
      return (this.audioContext.currentTime - this.startTime) * this.playbackRate
    }
    return this.pauseTime
  }
}
```

**Componente React**:
```typescript
export function TempoControl({
  tempo,
  onTempoChange
}: {
  tempo: number
  onTempoChange: (tempo: number) => void
}) {
  const presets = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <Label>Tempo</Label>
        <span className="text-sm font-mono">{(tempo * 100).toFixed(0)}%</span>
      </div>

      <Slider
        value={[tempo]}
        onValueChange={([value]) => onTempoChange(value)}
        min={0.5}
        max={2.0}
        step={0.05}
        className="w-full"
      />

      <div className="flex gap-2 flex-wrap">
        {presets.map(preset => (
          <Button
            key={preset}
            variant={tempo === preset ? "default" : "outline"}
            size="sm"
            onClick={() => onTempoChange(preset)}
          >
            {(preset * 100).toFixed(0)}%
          </Button>
        ))}
      </div>
    </div>
  )
}
```

#### 4. Metrónomo Integrado

**Features**:
- Click audible sincronizado con tempo del audio
- Indicador visual (flash o círculo pulsante)
- Configuración de subdivisiones (1/4, 1/8, 1/16)
- Acentos en el primer tiempo
- Volume control

**Implementación**:
```typescript
class Metronome {
  private audioContext: AudioContext
  private bpm: number
  private isPlaying: boolean = false
  private intervalId: number | null = null
  private clickBuffer: AudioBuffer | null = null
  private accentBuffer: AudioBuffer | null = null

  constructor(audioContext: AudioContext, bpm: number = 120) {
    this.audioContext = audioContext
    this.bpm = bpm
    this.createClickSounds()
  }

  private async createClickSounds() {
    // Crear sonidos de click (simple beep)
    const sampleRate = this.audioContext.sampleRate
    const clickLength = 0.05 // 50ms
    const samples = sampleRate * clickLength

    // Click normal
    this.clickBuffer = this.audioContext.createBuffer(1, samples, sampleRate)
    const clickData = this.clickBuffer.getChannelData(0)
    for (let i = 0; i < samples; i++) {
      clickData[i] = Math.sin(2 * Math.PI * 1000 * i / sampleRate) * Math.exp(-3 * i / samples)
    }

    // Accent (tono más alto)
    this.accentBuffer = this.audioContext.createBuffer(1, samples, sampleRate)
    const accentData = this.accentBuffer.getChannelData(0)
    for (let i = 0; i < samples; i++) {
      accentData[i] = Math.sin(2 * Math.PI * 1500 * i / sampleRate) * Math.exp(-3 * i / samples)
    }
  }

  private playClick(isAccent: boolean = false) {
    const source = this.audioContext.createBufferSource()
    source.buffer = isAccent ? this.accentBuffer : this.clickBuffer

    const gainNode = this.audioContext.createGain()
    gainNode.gain.value = 0.5

    source.connect(gainNode)
    gainNode.connect(this.audioContext.destination)
    source.start()
  }

  start() {
    if (this.isPlaying) return
    this.isPlaying = true

    let beatCount = 0
    const interval = (60 / this.bpm) * 1000 // ms

    this.intervalId = window.setInterval(() => {
      const isAccent = (beatCount % 4) === 0
      this.playClick(isAccent)
      beatCount++
    }, interval)
  }

  stop() {
    if (this.intervalId) {
      clearInterval(this.intervalId)
      this.intervalId = null
    }
    this.isPlaying = false
  }

  setBPM(bpm: number) {
    const wasPlaying = this.isPlaying
    if (wasPlaying) this.stop()
    this.bpm = bpm
    if (wasPlaying) this.start()
  }
}
```

**Componente React**:
```typescript
export function MetronomeControl() {
  const [isActive, setIsActive] = useState(false)
  const [bpm, setBpm] = useState(120)
  const metronomeRef = useRef<Metronome | null>(null)

  useEffect(() => {
    const audioContext = new AudioContext()
    metronomeRef.current = new Metronome(audioContext, bpm)

    return () => {
      metronomeRef.current?.stop()
    }
  }, [])

  useEffect(() => {
    metronomeRef.current?.setBPM(bpm)
  }, [bpm])

  const toggleMetronome = () => {
    if (isActive) {
      metronomeRef.current?.stop()
    } else {
      metronomeRef.current?.start()
    }
    setIsActive(!isActive)
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <Label>Metrónomo</Label>
        <Button
          variant={isActive ? "default" : "outline"}
          size="sm"
          onClick={toggleMetronome}
        >
          {isActive ? <Pause /> : <Play />}
          {bpm} BPM
        </Button>
      </div>

      <Slider
        value={[bpm]}
        onValueChange={([value]) => setBpm(value)}
        min={40}
        max={240}
        step={1}
        className="w-full"
      />

      {/* Visual indicator */}
      {isActive && <MetronomeBeat bpm={bpm} />}
    </div>
  )
}

function MetronomeBeat({ bpm }: { bpm: number }) {
  const [beat, setBeat] = useState(0)

  useEffect(() => {
    const interval = (60 / bpm) * 1000
    const timer = setInterval(() => {
      setBeat(b => (b + 1) % 4)
    }, interval)

    return () => clearInterval(timer)
  }, [bpm])

  return (
    <div className="flex gap-2 justify-center">
      {[0, 1, 2, 3].map(i => (
        <div
          key={i}
          className={cn(
            "w-4 h-4 rounded-full transition-colors",
            beat === i ? "bg-primary" : "bg-gray-300"
          )}
        />
      ))}
    </div>
  )
}
```

#### 5. Modo Performance

**Features**:
- Fullscreen automático
- Evitar que la pantalla se apague (Wake Lock API)
- Controles grandes táctiles
- Brillo ajustable
- Orientación bloqueada

**Implementación**:
```typescript
export function PerformanceMode({
  children,
  isActive
}: {
  children: React.ReactNode
  isActive: boolean
}) {
  const [wakeLock, setWakeLock] = useState<WakeLockSentinel | null>(null)

  useEffect(() => {
    if (!isActive) return

    // Request fullscreen
    document.documentElement.requestFullscreen()

    // Request wake lock
    if ('wakeLock' in navigator) {
      navigator.wakeLock.request('screen').then(lock => {
        setWakeLock(lock)
      })
    }

    // Lock orientation (mobile)
    if ('orientation' in screen && 'lock' in screen.orientation) {
      screen.orientation.lock('landscape').catch(() => {
        // Orientation lock might fail, that's ok
      })
    }

    return () => {
      // Exit fullscreen
      if (document.fullscreenElement) {
        document.exitFullscreen()
      }

      // Release wake lock
      if (wakeLock) {
        wakeLock.release()
      }
    }
  }, [isActive])

  return (
    <div className={cn(
      "relative",
      isActive && "fixed inset-0 z-50 bg-black"
    )}>
      {children}
    </div>
  )
}
```

#### 6. Herramientas Adicionales

**Anotaciones** (v2.1 - futuro):
- Dibujar en el PDF
- Notas de texto
- Guardar en localStorage o backend

**Loop de sección**:
- Marcar inicio/fin de compases
- Repetir sección infinitamente
- Útil para practicar partes difíciles

**Cambio de instrumento**:
- Dropdown para seleccionar instrumento
- Cargar partitura correspondiente
- Mantener sincronización

---

## Stack Tecnológico Adicional

### Librerías Necesarias

```json
{
  "dependencies": {
    // Existentes
    "next": "14.x",
    "react": "19.x",
    "typescript": "5.x",

    // Nuevas para v2.0
    "@fullcalendar/react": "^6.1.0",
    "@fullcalendar/daygrid": "^6.1.0",
    "@fullcalendar/interaction": "^6.1.0",
    "react-pdf": "^7.7.0",
    "pdfjs-dist": "^3.11.0",
    "tone": "^14.7.77",
    "photoswipe": "^5.4.0",
    "react-image-gallery": "^1.3.0",
    "framer-motion": "^10.16.0",
    "zustand": "^4.5.0"
  }
}
```

### APIs Web Utilizadas

- **Web Audio API**: Control de audio y tempo
- **Wake Lock API**: Evitar que pantalla se apague
- **Fullscreen API**: Modo performance
- **Screen Orientation API**: Bloquear orientación
- **Page Visibility API**: Pausar al cambiar de tab

---

## Endpoints API Necesarios

### Nuevos Endpoints en Sheet-API

#### 1. Slug Management

```python
# sheet-api/backend/events/views.py

class JamDeVientosViewSet(viewsets.ReadOnlyModelViewSet):
    # ... existing code ...

    @action(detail=False, methods=['get'])
    def by_slug(self, request):
        """
        Obtener evento por slug
        GET /api/v1/events/jamdevientos/by-slug/?slug=concierto-primavera-2025
        """
        slug = request.query_params.get('slug')
        if not slug:
            return Response({'error': 'Slug is required'}, status=400)

        try:
            event = self.get_queryset().get(slug=slug)
            serializer = JamDeVientosEventSerializer(event)
            return Response(serializer.data)
        except Event.DoesNotExist:
            return Response({'error': 'Event not found'}, status=404)
```

#### 2. Page Timestamps para Auto-Scroll

```python
# sheet-api/backend/music/models.py

class Version(models.Model):
    # ... existing fields ...
    page_timestamps = models.JSONField(
        blank=True,
        null=True,
        help_text='Timestamps de páginas para auto-scroll: [{"page": 1, "timestamp": 0}, ...]'
    )
```

#### 3. Gallery Endpoint

```python
# sheet-api/backend/events/views.py

class EventGalleryViewSet(viewsets.ReadOnlyModelViewSet):
    """
    Endpoint para galería de fotos de eventos
    """
    queryset = EventPhoto.objects.filter(is_public=True)
    serializer_class = EventPhotoSerializer
    permission_classes = []

    def get_queryset(self):
        queryset = super().get_queryset()
        event_id = self.request.query_params.get('event')
        year = self.request.query_params.get('year')

        if event_id:
            queryset = queryset.filter(event_id=event_id)
        if year:
            queryset = queryset.filter(event__start_datetime__year=year)

        return queryset.order_by('-event__start_datetime')
```

### Actualización de Modelos

```python
# sheet-api/backend/events/models.py

class Event(models.Model):
    # ... existing fields ...
    slug = models.SlugField(
        max_length=100,
        unique=True,
        blank=True,
        help_text='URL slug para jamdevientos.com'
    )

    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = self.generate_slug()
        super().save(*args, **kwargs)

    def generate_slug(self):
        from django.utils.text import slugify
        base_slug = slugify(self.title)[:50]
        slug = base_slug
        counter = 1

        while Event.objects.filter(slug=slug).exists():
            slug = f"{base_slug}-{counter}"
            counter += 1

        return slug

class EventPhoto(models.Model):
    """Nuevo modelo para galería de fotos"""
    event = models.ForeignKey(Event, on_delete=models.CASCADE, related_name='photos')
    image = models.ImageField(upload_to='event_photos/')
    caption = models.CharField(max_length=200, blank=True)
    photographer = models.CharField(max_length=100, blank=True)
    is_public = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
```

---

## Plan de Implementación

### FASE 9: Multi-Evento y Portada

**Duración estimada**: 8-12 horas
**Rama Git**: `feature/multi-event-architecture`

#### Tareas:

1. **Backend (Sheet-API)**:
   - [ ] Agregar campo `slug` al modelo Event
   - [ ] Crear migración de base de datos
   - [ ] Implementar generación automática de slugs
   - [ ] Crear endpoint `/by-slug/`
   - [ ] Crear modelo EventPhoto y endpoints
   - [ ] Testing de endpoints

2. **Frontend (Jam de Vientos)**:
   - [ ] Crear nueva estructura de rutas en App Router
   - [ ] Implementar página portada (`app/page.tsx`)
   - [ ] Crear HeroSection component
   - [ ] Integrar FullCalendar
   - [ ] Crear página "Sobre Nosotros"
   - [ ] Crear galería de fotos
   - [ ] Implementar dynamic routes `[eventSlug]`
   - [ ] Migrar carousel existente a ruta dinámica
   - [ ] Implementar metadata dinámica para SEO
   - [ ] Testing responsive

3. **Contenido**:
   - [ ] Recopilar fotos para galería
   - [ ] Escribir contenido "Sobre Nosotros"
   - [ ] Crear/obtener imágenes hero

**Entregables**:
- Sitio multi-evento funcional
- Portada profesional
- Calendario interactivo
- SEO optimizado

---

### FASE 10: Lector de Partituras Avanzado

**Duración estimada**: 12-16 horas
**Rama Git**: `feature/advanced-sheet-music-reader`

#### Tareas:

1. **Setup**:
   - [ ] Instalar PDF.js y react-pdf
   - [ ] Configurar worker de PDF.js
   - [ ] Crear estructura de componentes

2. **Visualización PDF**:
   - [ ] Implementar PDFViewer component
   - [ ] Zoom controls (pinch, botones)
   - [ ] Page navigation (swipe, botones)
   - [ ] Thumbnail sidebar
   - [ ] Loading states
   - [ ] Error handling

3. **Reproductor de Audio Avanzado**:
   - [ ] Implementar AudioPlayerWithTempo class
   - [ ] Integrar Web Audio API
   - [ ] Crear TempoControl component
   - [ ] Testing de cambio de tempo sin chipmunk
   - [ ] Implementar preservación de pitch

4. **Metrónomo**:
   - [ ] Implementar Metronome class con Web Audio API
   - [ ] Crear sonidos de click (normal y accent)
   - [ ] MetronomeControl component
   - [ ] Indicador visual de beat
   - [ ] Configuración de BPM

5. **Auto-Scroll**:
   - [ ] Agregar campo page_timestamps a modelo Version
   - [ ] Crear migración
   - [ ] Implementar useAutoScroll hook
   - [ ] Testing de sincronización
   - [ ] UI para configurar timestamps (admin)

6. **Modo Performance**:
   - [ ] Implementar PerformanceMode component
   - [ ] Integrar Wake Lock API
   - [ ] Fullscreen automático
   - [ ] Lock de orientación
   - [ ] Controles grandes para móvil

7. **Integración**:
   - [ ] Crear SheetMusicReader component principal
   - [ ] Integrar todos los subcomponentes
   - [ ] State management con Zustand
   - [ ] Testing en móviles reales (iOS, Android)
   - [ ] Optimización de performance

8. **UI/UX**:
   - [ ] Diseño de ControlPanel
   - [ ] Responsive design
   - [ ] Dark mode
   - [ ] Gestos táctiles
   - [ ] Feedback visual

**Entregables**:
- Lector de partituras totalmente funcional
- Sincronización audio-partitura
- Control de tempo
- Metrónomo integrado
- Modo performance
- Testing completo en móviles

---

## Consideraciones Técnicas

### Performance

**Optimizaciones**:
- Lazy loading de PDFs
- Virtualización de páginas (renderizar solo visible)
- Service Worker para cache de partituras
- Compresión de imágenes en galería
- ISR (Incremental Static Regeneration) para páginas de eventos

### Compatibilidad Móvil

**Testing requerido**:
- iOS Safari (iPhone, iPad)
- Android Chrome
- Landscape y portrait
- Diferentes tamaños de pantalla
- Performance en dispositivos antiguos

**Consideraciones iOS**:
- Web Audio API requiere user gesture para iniciar
- Wake Lock API puede no estar disponible
- Fullscreen API limitado en iOS Safari

### Accesibilidad

- ARIA labels en controles
- Keyboard navigation
- Screen reader support
- Contraste de colores (WCAG AA)
- Focus indicators

### Seguridad

- Validación de slugs (prevenir XSS)
- Rate limiting en endpoints
- CORS configurado correctamente
- CSP headers

---

## Cronograma y Recursos

### Cronograma Detallado

| Semana | Fase | Horas | Hitos |
|--------|------|-------|-------|
| 1 | Documentación completa | 3h | Este documento |
| 2-3 | Backend: Slugs + Endpoints | 8h | API lista |
| 3-4 | Frontend: Multi-evento + Portada | 12h | Sitio navegable |
| 5-6 | Lector: PDF + Audio | 10h | Visor funcional |
| 7-8 | Lector: Tempo + Metrónomo | 8h | Controles avanzados |
| 9 | Auto-scroll + Performance mode | 6h | Feature completo |
| 10 | Testing + Optimización | 8h | Producción ready |

**Total**: ~55 horas de desarrollo

### Recursos Necesarios

**Desarrollo**:
- 1 desarrollador Full-stack (Next.js + Django)
- Acceso a dispositivos móviles para testing
- Cuenta de hosting para staging

**Contenido**:
- Fotos de eventos (galería)
- Textos institucionales
- Assets gráficos (logo, hero images)

**Testing**:
- Beta testers (músicos de la jam)
- Feedback de UX en móvil

---

## Próximos Pasos Inmediatos

1. ✅ **Documentación aprobada**
2. ⏳ **Investigación de librerías**:
   - Evaluar FullCalendar vs React Big Calendar
   - Testing de PDF.js performance en móvil
   - Evaluar Tone.js vs Web Audio API nativo
3. ⏳ **Prototipos**:
   - Mockup de portada (Figma)
   - Prototipo de lector en CodeSandbox
4. ⏳ **Setup backend**:
   - Agregar campo slug
   - Crear migraciones
5. ⏳ **Primera iteración**:
   - Implementar routing dinámico
   - Crear portada básica

---

## Referencias

### Documentación Técnica
- [PDF.js Documentation](https://mozilla.github.io/pdf.js/)
- [Web Audio API MDN](https://developer.mozilla.org/en-US/docs/Web/API/Web_Audio_API)
- [Wake Lock API](https://developer.mozilla.org/en-US/docs/Web/API/Screen_Wake_Lock_API)
- [Next.js Dynamic Routes](https://nextjs.org/docs/app/building-your-application/routing/dynamic-routes)
- [FullCalendar React](https://fullcalendar.io/docs/react)

### Ejemplos e Inspiración
- [MuseScore Web Viewer](https://musescore.com)
- [IMSLP](https://imslp.org) (Petrucci Music Library)
- [ForScore](https://forscore.co) (iPad app para partituras)

---

**Última actualización**: 2025-11-02
**Versión**: 2.0 (Propuesta)
**Estado**: 📝 Documentación completa - Listo para aprobación e implementación
**Autor**: Claude Code con input del equipo Jam de Vientos
