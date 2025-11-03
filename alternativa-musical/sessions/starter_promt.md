## Información sobre Alternativa Teatral

![Image](https://img.alternativateatral.com/imagenes/logovertical2010.gif)

![Image](https://img.alternativateatral.com/scripts/es/fotos/notas/resumen/000069560.jpg)

![Image](https://www.alternativateatral.com/imagenes/promociones1200x627.png)

Aquí tienes un resumen bastante detallado de lo que encontré sobre Alternativa Teatral — lo que ofrece, su historial técnico/funcional, y luego te proveo un prompt starter adaptado para tu proyecto musical.

### ¿Qué es Alternativa Teatral?

* Alternativa Teatral es una plataforma digital argentina, con sede en Buenos Aires, que conecta a diversos actores del ámbito de las artes escénicas: público, artistas, productores, salas de teatro. ([Alternativa. Comunidad en escena.][1])
* Está orientada principalmente al circuito independiente de teatro, danza, performance. ([Alternativa. Comunidad en escena.][2])
* Tiene varias secciones: cartelera de espectáculos (teatro, danza, musicales, etc) con filtros por día, tipo, público. ([Alternativa. Comunidad en escena.][3])
* Permite también castings/convocatorias, cursos/talleres, publicación de espectáculos, inscripción de datos de artistas. ([Alternativa. Comunidad en escena.][4])
* Y en particular: un sistema de venta de entradas y reservas para obras en salas independientes. ([Alternativa. Comunidad en escena.][5])

### Historia / Datos técnicos relevantes

* Fue fundada alrededor del año 2000 por Javier Acuña. ([LA NACION][6])
* En su evolución, alrededor de 2010 desarrollaron el sistema de venta de entradas para el circuito independiente: “un sistema de gestión de localidades” que administra espacios, reservas, venta online, impresión de tickets. ([Alternativa. Comunidad en escena.][7])
* En la página “Cómo publicar” se menciona: «Contamos con un completo e integral sistema de gestión de localidades. Con el mismo pueden administrar la totalidad de localidades de un espacio, así como tomar reservas, ofrecer promociones, descuentos, gestionar localidades internas para prensa, invitaciones de elencos e incluso venta e impresión de tickets. ». ([Alternativa. Comunidad en escena.][7])
* También ofrecen un esquema de difusión: bases de datos de artistas, fichas de obras, salas, críticas, etc. ([LA NACION][6])
* Comercialmente, ofrecen espacios de publicidad y difusión para los espectáculos y espacios. ([Alternativa. Comunidad en escena.][8])
* Técnicamente, el sistema de entradas incluye reserva + compra online + gestión de localidades, lo cual implica backend que administre stock de localidades, promociones, printables, etc.

### Lo que ofrece – funcionalidades clave

Para que lo puedas tomar como referencia para tu proyecto:

* Listado/Cartelera de eventos (filtrable por día, tipo, público) para que el público encuentre qué ver.
* Publicación de espectáculos: para que artistas/productores ingresen título, descripción, elenco, duración, sala, días/horarios, precio. ([Alternativa. Comunidad en escena.][7])
* Sistema de gestión de localidades / entradas para el espacio: gestionar asiento o localidades (en espacio pequeño), reservas, promociones, invitaciones.
* Venta online de entradas + reservas (y posiblemente impresión de tickets).
* Base de datos de artistas / salas / obras / historial, generando comunidad y datos de consulta.
* Espacio de castings/convocatorias, cursos/talleres para que haya más oferta además de solo venta de entradas.
* Herramientas de difusión, anuncios, publicidad para salas/productores.
* Interfaz pública para que el público vea lo que hay, compre/ reserve, consulte.

### Puntos que podrían adaptarse/limitarse para tu proyecto

Dado que tu proyecto será más pequeño y enfocado en **eventos musicales** (venta de entradas o “a la gorra”), con sistema de gestión para el productor, pasarela de pagos, y futura integración de sistema de organización de repertorios, se puede tomar lo siguiente de Alternativa Teatral como inspiración:

**Tomar en cuenta**:

* En lugar de gestionar grandes salas de teatro, enfocarse en locales/conciertos más simples (capacidad, entradas generales, quizá sin asiento numerado).
* Simplificar la publicación del evento (artista, fecha/hora, lugar, precio o modalidad “entrada a la gorra”).
* Entrada “a la gorra” requiere modo de registro/reserva gratuita + donación/pago voluntario, o simplemente registro con check-in al evento.
* Para el productor: un dashboard donde vea cuántas entradas vendidas/reservadas, cuántas entradas quedan, ingresos generados, ventas por canal.
* Integrar una pasarela de pagos (ej. Stripe, MercadoPago, PayPal) para venta anticipada o donación.
* Escalable para futuro: módulo de repertorios (lista de canciones, duración, set list) que se vincule al evento y al artista.
* Si lo vinculas al ecosistema de tus proyectos “music-projects” (sheet-api, jam de vientos, empiv, music learning) hay que pensar API, microservicio, base de datos compartida, autorización, etc.

**Lo que no hace falta ahora** (o se puede poner versión mínima):

* Asientos numerados, impresión de tickets físicos.
* Gran base de datos de artistas, salas, fichas completas (puede haber versión simple).
* Sistema de promociones/dos×uno complejas.
* Gran comunidad de castings/convocatorias (aunque se puede dejar como posible módulo futuro).
* Múltiples filtros de cartelera (día por día, tipo, etc) si el foco es solo música.

### Técnicamente lo que encontré (y te puede dar pistas)

* Sistema de gestión de localidades: backend que controla stock, reservas, ventas, invitaciones.
* Módulo de publicación de espectáculos vía formulario web.
* Organización de la cartelera con filtros (teatro, danza, musical, etc).
* Venta online de entradas + reserva + impresión de tickets.
* Interfaz pública + panel de administración para productores/artistas.
* Integración de difusión/comunidad (críticas, base de datos, vídeos).

Nada encontré público sobre el stack tecnológico exacto (lenguajes, frameworks, etc) de Alternativa Teatral, al menos de lo que se encontró en la búsqueda. Pero la estructura funcional es clara: publicación + listado + gestión de entradas + ventas.

---

## Prompt starter para Claude (proyecto derivado)

Aquí tienes un prompt que puedas pasarle a Claude para que genere especificaciones, arquitectura, flujo de trabajo para tu proyecto (adaptado a música-eventos, más simple que Alternativa Teatral):

> **Prompt para Claude**:
>
> “Quiero diseñar una aplicación web (y móvil si lo deseas) llamada **[Nombre provisional: MusicEventsPro]**, orientada a organizar eventos musicales (conciertos, sesiones en vivo, jams, etc) para productores/organizadores independientes.
>
> **Objetivos principales:**
>
> 1. Permitir al productor crear un evento (artista o banda, fecha/hora, lugar, capacidad estimada, modalidad de entradas: anticipadas con pago / entrada a la gorra / registro gratuito + donación).
> 2. Gestionar la venta de entradas: establecer precio (o modalidad donación), cantidad de entradas, emisión de entradas digitales (código QR) o registro simple para acceso.
> 3. Integrar una pasarela de pagos segura para ventas anticipadas o donaciones (ej. Stripe, MercadoPago, PayPal).
> 4. Dashboard para el productor: ver número de entradas vendidas, ingresos, listado de asistentes, capacidad restante, exportar datos.
> 5. Página pública del evento: artista, descripción, lugar, fecha/hora, botón “Comprar/Reservar/Donar”, información de entradas.
> 6. Futuro módulo adicional: organización de repertorios / set-list para el artista: lista de canciones, orden, duración estimada, vinculación al evento, posibilidad de que los asistentes voten o vean el repertorio.
> 7. Integración con la API externa Sheet‑API (y otros proyectos de tu ecosistema como Jam de Vientos, Empiv, Music Learning): permitir que los datos de eventos, artistas, repertorios se sincronicen con esa API/fuente de datos compartida.
>
> **Requisitos técnicos a especificar:**
>
> * Arquitectura del sistema (frontend React o similar, backend Django o similar, base de datos relacional/post-relacional).
> * Definición de los endpoints principales de la API (por ejemplo: /api/events, /api/tickets, /api/artists, /api/repertoire).
> * Gestión de autenticación/autorización para productores, artistas, público.
> * Modelo de datos básicos (Entidad Evento, Artista/Banda, Entrada/Ticket, Usuario, Repertorio).
> * Flujo de compra/registro de entradas (confirmación, QR, validación en puerta).
> * Integración de pasarela de pagos: flujo, seguridad, webhooks, reconciliación.
> * Panel de administración para productores.
> * Responsive UI para público y móvil.
> * Escalabilidad y modularidad para agregar en el futuro el módulo de repertorios y vinculación con la Sheet-API.
> * Opciones para entrada ‘a la gorra’ (donación voluntaria, registro sin pago).
>
> **Entregables esperados:**
>
> * Documento de especificación funcional (módulos, flujos de usuario).
> * Esquema de base de datos (diagrama ER).
> * Lista de endpoints de la API con descripción de cada uno (método, parámetros, respuestas).
> * Propuesta de tecnología (stack recomendado) y justificación.
> * Cronograma de desarrollo (fase MVP: por ejemplo, 3 meses) con hitos.
> * Esquema de integración con Sheet-API y cómo los eventos/artistas se sincronizan.
>
> “Por favor, genera una versión inicial del documento de especificación funcional para este proyecto, pensando en una versión simplificada que ya pueda salir al aire con lo mínimo viable pero tenga la estructura limpia para la futura ampliación de repertorios y vinculación con tu ecosistema.”

---

Si quieres, puedo armar **un documento más completo** para tu proyecto (especificación, módulo por módulo, estimación de horas, stack sugerido) listo para entregar al equipo de desarrollo. ¿Te lo preparo?

[1]: https://www.alternativateatral.com/propuesta.asp?utm_source=chatgpt.com "Sobre Alternativa en Alternativa. Comunidad en escena."
[2]: https://www.alternativateatral.com/?utm_source=chatgpt.com "Alternativa Teatral"
[3]: https://www.alternativateatral.com/obras.asp?utm_source=chatgpt.com "Cartelera de espectáculos en Alternativa. Comunidad en escena."
[4]: https://www.alternativateatral.com/convocatorias.php?utm_source=chatgpt.com "Castings y convocatorias 2025 - Alternativa Teatral"
[5]: https://www.alternativateatral.com/entradas.asp?utm_source=chatgpt.com "Reserva y compra de entradas para obras de teatro y espectaculos"
[6]: https://www.lanacion.com.ar/lifestyle/la-historia-detras-de-alternativa-teatral-nid1976627/?utm_source=chatgpt.com "La historia detrás de Alternativa Teatral - La Nación"
[7]: https://www.alternativateatral.com/gacetillas.asp?utm_source=chatgpt.com "Cómo publicar espectáculos - Alternativa Teatral"
[8]: https://www.alternativateatral.com/publicidad/RatecardAlternativaTeatral2012.pdf?utm_source=chatgpt.com "[PDF] Alternativa Teatral - Contacto: publicidad@alternativateatral.com"
