Perfecto ✅
A continuación te dejo un **prompt técnico detallado**, listo para pasarle a **Claude Code** (o a un entorno de IA de desarrollo tipo Code Interpreter o Cloud Code), para que genere la **arquitectura y los requerimientos técnicos** del proyecto “Alternativa Musical” — una versión reducida de *Alternativa Teatral* enfocada en **eventos musicales con venta de entradas o entrada a la gorra**, bajo tu stack estándar:

---

## 🎯 **Prompt técnico para Claude Code**

*(Puedes copiarlo y pegarlo completo en tu sesión de Claude Code dentro del repositorio `music-projects` o en un nuevo repo dedicado)*

---

**Prompt:**

Desarrollá la especificación técnica y la estructura base del proyecto **Alternativa Musical**, una aplicación web inspirada en Alternativa Teatral pero simplificada y orientada a **eventos musicales independientes con venta de entradas o entrada a la gorra**, pensada para integrarse al ecosistema de `music-projects` (junto con `jam-de-vientos`, `empiv`, `sheet-api`, `music-learning`).

### 🧩 Objetivo general

Construir una aplicación full-stack con:

* **Frontend:** React 19 + TypeScript + Tailwind CSS
* **Backend:** Django 5 + Django REST Framework
* **Base de datos:** PostgreSQL
* **Autenticación:** JWT (djangorestframework-simplejwt)
* **Pasarela de pagos:** MercadoPago (en primera instancia)
* **Despliegue:** Docker Compose (frontend + backend + DB)
* **Integración futura:** Sheet-API (para repertorios musicales)

---

### 🚀 Funcionalidades principales (MVP)

1. **Gestión de eventos musicales**

   * Alta / edición / eliminación de eventos.
   * Campos: título, descripción, lugar, fecha, hora, modalidad (“pago”, “a la gorra”, “gratuito”), aforo máximo, imagen, productor asociado.
   * Estado del evento: “Borrador”, “Publicado”, “Finalizado”.

2. **Venta o reserva de entradas**

   * Modalidades:

     * Venta con pago anticipado.
     * Entrada a la gorra (pago voluntario).
     * Entrada gratuita (solo registro).
   * Generación de código QR o número de entrada.
   * Confirmación por email (simulado o real vía SendGrid / Django EmailBackend).
   * Validación en puerta (endpoint para check-in).

3. **Panel del productor**

   * Visualización de eventos creados.
   * Métricas: entradas vendidas, reservas, ingresos totales, lista de asistentes.
   * Exportación de datos (CSV o Excel).
   * Gestión de pagos (ver estado, reenviar link de pago).

4. **Pasarela de pago (MercadoPago / Stripe)**

   * Creación de preferencia de pago vía API.
   * Webhook para confirmar pago y actualizar ticket.
   * Modo sandbox configurable vía `.env`.

5. **Portal público**

   * Listado de eventos (por fecha, artista, lugar).
   * Página individual de evento (info + botón “Reservar/Comprar/Donar”).
   * Buscador simple por palabra clave.

6. **Integración futura**

   * API de repertorios (vinculada a Sheet-API).
   * Cada evento podrá tener asociado un “set list” con temas, orden y duración.
   * En una versión posterior, permitir votaciones del público sobre temas.

---

### 🧠 Arquitectura técnica

#### Frontend (React + TS)

* Vite o CRA (preferencia: **Vite**).
* Estructura modular:

  ```
  src/
  ├── components/
  ├── pages/
  ├── services/
  ├── context/
  ├── hooks/
  ├── types/
  └── utils/
  ```
* Librerías:

  * **Axios** → comunicación con API REST.
  * **React Query (TanStack)** → manejo de estado del servidor.
  * **React Router v6** → navegación SPA.
  * **Tailwind CSS + shadcn/ui** → interfaz moderna y accesible.
  * **Zod** o **Yup** → validaciones de formularios.
  * **React Hook Form** → gestión de inputs.

#### Backend (Django + DRF)

* Apps principales:

  * `events` → modelos de eventos, tickets, productores.
  * `payments` → integración con MercadoPago / Stripe.
  * `users` → registro, login, JWT.
  * `repertoire` (placeholder futuro) → conexión con Sheet-API.
* Dependencias:

  ```bash
  pip install django djangorestframework djangorestframework-simplejwt psycopg2-binary corsheaders
  pip install mercadopago  # SDK oficial
  ```
* Configuración:

  * CORS habilitado (`CORS_ALLOWED_ORIGINS`).
  * `.env` con variables:

    ```
    SECRET_KEY=
    DEBUG=True
    DATABASE_URL=postgres://...
    MERCADOPAGO_ACCESS_TOKEN=
    FRONTEND_URL=http://localhost:5173
    ```
* Rutas:

  ```
  /api/auth/
  /api/events/
  /api/tickets/
  /api/payments/
  /api/repertoire/   # futuro
  ```
* Serializers + ViewSets + Permissions por roles (`is_producer`, `is_staff`, `is_public`).

---

### 🧱 Base de datos (PostgreSQL)

Modelo básico propuesto:

```python
# users/models.py
class User(AbstractUser):
    is_producer = models.BooleanField(default=False)
    alias_bancario = models.CharField(max_length=50, blank=True, null=True)

# events/models.py
class Event(models.Model):
    producer = models.ForeignKey(User, on_delete=models.CASCADE)
    title = models.CharField(max_length=200)
    description = models.TextField()
    location = models.CharField(max_length=150)
    date = models.DateField()
    time = models.TimeField()
    mode = models.CharField(choices=[('pago','Pago'),('gorra','A la gorra'),('gratis','Gratuito')])
    capacity = models.PositiveIntegerField()
    image = models.ImageField(upload_to='events/', null=True, blank=True)
    status = models.CharField(choices=[('draft','Borrador'),('published','Publicado'),('finished','Finalizado')])

class Ticket(models.Model):
    event = models.ForeignKey(Event, on_delete=models.CASCADE)
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    price = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    payment_status = models.CharField(choices=[('pending','Pendiente'),('paid','Pagado')])
    qr_code = models.CharField(max_length=100, blank=True)
```

---

### 🐳 Docker Compose

```yaml
version: '3.9'
services:
  backend:
    build: ./backend
    ports:
      - "8000:8000"
    env_file: ./backend/.env
    depends_on:
      - db
  frontend:
    build: ./frontend
    ports:
      - "5173:5173"
    env_file: ./frontend/.env
  db:
    image: postgres:16
    environment:
      POSTGRES_DB: alternamusical
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    volumes:
      - postgres_data:/var/lib/postgresql/data
volumes:
  postgres_data:
```

---

### 🧩 Extras y buenas prácticas

* Documentación de API con **drf-spectacular** o **swagger**.
* Tests con **pytest + factory_boy** (mínimo 3 endpoints cubiertos).
* CI/CD: GitHub Actions → test + build + deploy (Heroku o EC2).
* Branches por feature → `feature/{nombre}` → docs en `/docs/sessions/{fecha}/`.
* UX/UI coherente con `jam-de-vientos` (glassmorphism, sombras, animaciones sutiles).

---

### 🧾 Resultado esperado del prompt

Claude debe generar:

1. **Especificación técnica completa** (stack, dependencias, estructura de carpetas).
2. **Diagrama de arquitectura (Mermaid)** con frontend–backend–DB–pasarela.
3. **ERD básico** de las tablas principales.
4. **Lista de endpoints REST**.
5. **Comandos para inicializar el entorno** (backend, frontend, Docker).
6. **Roadmap de desarrollo** (MVP → Fase 2 repertorios).

---

¿Querés que te genere también el **Mermaid diagram** y el **modelo ERD base** para que lo copies en la documentación inicial del repo (`docs/sessions/2025-10-29/`)?
