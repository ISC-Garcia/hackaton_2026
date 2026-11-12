# VeraGo

App de turismo inteligente para el Centro Histórico de Veracruz.
Hecha con **Flutter + Dart** y **Supabase (PostgreSQL)**.

Documentación del equipo (documentos compartidos de Claude):

- **Documentación integral** (qué es VeraGo, módulos, arquitectura, base de datos, seguridad):
  https://claude.ai/artifact/Hp9CAXgVd5qvhU9xVvV5Dq
- **Guía de estudio del código + 116 preguntas para la demo**:
  https://claude.ai/artifact/GxJK58vGE6jzZZe4ckyUuE

## Tecnologías

| Pieza | Para qué |
| --- | --- |
| Flutter + Dart | La app (Android, iPhone y web) |
| Supabase Auth | Cuentas con correo y contraseña |
| Supabase Database (PostgreSQL) | Tablas, reglas RLS, permisos GRANT y funciones protegidas |
| `supabase_flutter` | Conexión de la app con Supabase |
| `flutter_map` + `latlong2` | Mapa de OpenStreetMap y coordenadas |
| `geolocator` | GPS: al abrir Explorar (si la persona da permiso), con "Mostrar dónde estoy" y con "Mi ubicación" en Rutas. Se toma una vez; no se guarda |
| `mobile_scanner` / `qr_flutter` | Leer y dibujar códigos QR |
| `shared_preferences` | Guardar en el celular: bienvenida vista, intereses y tiempo de la ruta |
| `http` + Nominatim (OpenStreetMap) | Convertir el punto tocado en el mapa en una dirección escrita (registro de negocios y lugares del admin; solo coordenadas del negocio) y **"Buscar en el mapa"** en Explorar (solo el texto buscado, al tocar el botón) |
| `http` + OSRM (routing.openstreetmap.de) | Dibujar la ruta **por las calles** en lugar de en línea recta, desde el inicio hasta la última parada. Se envían las paradas y el punto de inicio (si es "Mi ubicación", la ubicación del turista, una vez y sin guardarla). Si falla, se dibuja la línea recta |
| `http` + Google Gemini (IA) | Chat **"Pregúntale a VeraGo"**: la persona escribe lo que busca y la IA recomienda lugares de la app. Se envían sus mensajes y la lista pública de lugares (nunca ubicación, correo ni sellos). Modelo por defecto `gemini-flash-lite-latest` |
| Supabase Storage + `image_picker` | **Fotos de los lugares**: `image_picker` abre la galería o la cámara (en web, el selector de archivos); la foto se achica (máx. 1280 px) y se guarda en el bucket público `fotos-lugares`. Las reglas del bucket solo dejan subir al admin (cualquier lugar) y al comerciante (su negocio) |
| `url_launcher` | Botón de emergencia: abre la app de llamadas del celular con el **911** ya escrito |

## Estado

| Fase | Contenido | Estado |
| --- | --- | --- |
| 1. Fundamentos | Paquetes, tema visual, navegación, SQL (tablas, RLS, funciones, datos demo, permisos) | Implementado; SQL corrido en Supabase |
| 2. Turista | Explorar (mapa/lista, búsqueda, filtros, leyenda, centrar), ficha del lugar con "Cerca de aquí", agenda | Implementado y probado en celular |
| 3. Rutas | Formulario (tiempo, intereses **obligatorio al menos uno**, ritmo, inicio), algoritmo voraz **filtrado por intereses** (**solo** entran las categorías elegidas; los Puntos VeraGo también se pueden elegir), ruta en mapa, "Quitar" parada, sugerencia cercana | Implementado, con pruebas automáticas del algoritmo |
| 4. Pasaporte | Login con correo y contraseña (con confirmar contraseña), QR del comerciante (cambia cada 60 s), escaneo con cámara o código escrito, animación del sello, colección e historial | Implementado |
| 5. Cierre | Estadísticas (DATOS SIMULADOS, solo admin), pruebas, compilación web | Implementado. Falta ensayo de la demo |
| Extra UI/UX | Pantalla de bienvenida (primera vez), botón de ojo en contraseñas, leyenda y centrar en el mapa | Implementado, con pruebas automáticas |
| Ajustes | Engrane en el Pasaporte: mi cuenta (correo, rol, cambiar nombre), mis intereses, ver bienvenida otra vez, privacidad y cerrar sesión | Implementado, con pruebas automáticas |
| Comerciantes | "Soy un negocio" (bienvenida y Ajustes): registro de negocio formal (local en mapa) o informal (giro en un **Punto VeraGo**), inicio de sesión, estado de la solicitud y panel (QR, ficha, editar datos) | Implementado, con pruebas automáticas. **Falta correr SQL 008 y 009** y probar con Supabase |
| Admin en la app | El rol **admin** crea, edita, publica, pasa a borrador, cancela y elimina eventos de la Agenda desde la app | Implementado, con pruebas automáticas. **Falta correr SQL 010** |
| Logo | Logo de VeraGo como ícono de la app (Android, iPhone, web) y en la bienvenida y el registro de negocios | Implementado |
| Panel de administración | Pasaporte → "Panel de administración" (solo admin): **solicitudes de negocios** (aprobar, rechazar, suspender, reactivar, horario; compara la dirección escrita con la del mapa) y **lugares y Puntos VeraGo** (crear, editar, ocultar, horario) | Implementado, con pruebas automáticas. **Falta correr SQL 011** |
| Dirección automática | Al tocar el mapa, la dirección se llena sola (registro de negocio y lugares del admin) | Implementado. Necesita internet |
| Cambio de ubicación | Panel del comerciante → "Cambiar ubicación" (formal: mapa) o "Cambiar de Punto VeraGo" (no formal). El admin lo revisa en **Solicitudes de negocios → Cambios de ubicación** (mapa nuevo y dirección) y lo acepta o rechaza | Implementado, con pruebas automáticas. **Falta correr SQL 013** |
| Dónde estoy | Al abrir Explorar se pide la ubicación una vez (si no hay permiso, se usa el Zócalo). Botón "Mostrar dónde estoy" para volver a pedirla: punto azul "Estás aquí" y distancias desde el turista. La ruta que empieza en "Mi ubicación" también marca el inicio. Si está a más de 15 km del Zócalo, se sigue usando el Zócalo | Implementado, con pruebas automáticas |
| Ruta por las calles | El mapa de la ruta dibuja todo el camino a pie por las calles (OSRM de OpenStreetMap), también el primer tramo desde el inicio. Los tiempos siguen siendo los estimados de la app | Implementado, con pruebas automáticas. Necesita internet (si no, línea recta punteada) |
| Emergencia 911 | Botón rojo **"911"** en la pantalla de la ruta y en la barra de Explorar: abre directo la app de llamadas con el 911 escrito (la persona toca "llamar") | Implementado, con pruebas automáticas |
| Fotos | 1 foto principal por lugar: grande en la ficha y chica en la tarjeta (sin foto, color e ícono como antes). El comerciante la pone en "Editar mis datos" (solo su negocio); el admin en Solicitudes de negocios y en Lugares (cualquier lugar). Se publica al instante; el admin la puede quitar; "Reportar un problema" tiene el motivo "La foto no corresponde" | Implementado, con pruebas automáticas. **Falta correr SQL 018** |
| Guía con IA | Botón flotante **"Pregúntale a VeraGo"** en Explorar: chat con Gemini que responde en JSON (`respuesta` + `lugares_ids`) y muestra las tarjetas de los lugares recomendados. Recuerda la conversación solo mientras está abierto. Ver "Configurar la guía con IA" | Implementado, con pruebas automáticas y probado en vivo (respuesta en ~1.5 s) |
| Insignia del pasaporte | 5 niveles (Visitante, Explorador, Viajero, Jarocho, Embajador VeraGo). El nivel k se gana con ⌈total × k ÷ 5⌉ sellos; el último, con todos los negocios. Cada nivel se ve más elaborado; el último es dorado con brillo animado | Implementado, con pruebas automáticas |
| Buscar en el mapa | Si lo buscado no es un lugar de VeraGo (ej. "Tecnológico"), botón "Buscar en todo el mapa": consulta Nominatim solo en Veracruz y Boca del Río y lo muestra con pin morado | Implementado, con pruebas automáticas. Necesita internet |
| Guía de la app | La bienvenida ahora tiene 7 páginas: qué es, intereses, una por pestaña (con la barra de abajo dibujada) y seguridad (911, Ajustes, "Soy un negocio"). Se vuelve a ver en Ajustes | Implementado, con pruebas automáticas |
| Eventos que se repiten | Al crear un evento: "Se repite" cada N días, M veces, con la hora de Inicia/Termina; crea un evento por fecha (se cancelan por separado) | Implementado, con pruebas automáticas |
| Vitrina digital | Panel del comerciante → "Mi vitrina": productos o servicios con precio aproximado (máx. 20) y una promoción. La ficha muestra la sección "Vitrina" y la tarjeta la etiqueta "Promoción" | Implementado, con pruebas automáticas. **Falta correr SQL 015** |
| Estadísticas | Admin (Panel de administración) y comerciante ("Mis estadísticas"). Por defecto, **datos FICTICIOS de demostración** con aviso; el selector "Reales" muestra lo que hay en la base (cuentas, sellos por día, negocios con más sellos), solo totales | Implementado, con pruebas automáticas. "Reales" necesita el SQL 016 |
| Borrar mi cuenta | Ajustes → "Borrar mi cuenta" (con confirmación): borra cuenta, perfil y sellos; un negocio sin aprobar se borra y uno publicado se oculta. Un admin no se borra desde la app | Implementado, con pruebas automáticas. **Falta correr SQL 016** |
| Costo de entrada | Ficha: "Entrada gratis", "Entrada aprox. $X MXN" o (lugar público sin dato) "no disponible". Lo pone el negocio formal en "Editar mis datos" (se publica directo) y el admin en lugares y en cada negocio formal | Implementado, con pruebas automáticas. **Falta correr SQL 014** |
| Legal y confianza | Ajustes → **Legal y confianza**: ¿Cómo funciona VeraGo?, Reglas operativas, Términos de uso, Términos para negocios y Aviso de privacidad (textos en `lib/legal/documentos.dart`). Ventana **Confirmar / Cancelar** con los términos antes de registrar un negocio; enlaces a Términos y Aviso al crear cuenta; **Reportar un problema** en la ficha de cada lugar (copia un reporte para enviarlo por correo) | Implementado, con pruebas automáticas. Son textos de hackatón: **un abogado debe revisarlos** antes de un uso real |

Verificado en esta computadora: `flutter analyze` sin problemas, **124 pruebas automáticas** pasan
y la app compila para web (`flutter build web`).

### Qué NO hace la app (a propósito, MVP)

- No hay premios ni canjes: el pasaporte **solo junta sellos**.
- **Solo los negocios formales** (local propio) dan sellos. Los no formales (en un Punto VeraGo),
  los Puntos y los lugares públicos no.
- **Solo los desarrolladores entran a Supabase.** El admin de VeraGo maneja desde la app la
  **Agenda**, las **solicitudes de negocios** y los **lugares y Puntos VeraGo**.
  Todavía se hace en Supabase (por un desarrollador): **cambiar roles** (por ejemplo, nombrar a un admin).
- Los pagos de los comerciantes por su espacio se acuerdan **fuera de la app**.
- Los comercios y eventos son **ficticios**; los lugares públicos no tienen horarios inventados.
- Las estadísticas son **simuladas**.

## Cómo configurar Supabase (una sola vez)

1. Entrar al proyecto en [supabase.com](https://supabase.com) → **SQL Editor**.
2. Pegar y ejecutar (**Run**), **en este orden**, cada archivo de `supabase/migrations/`:
   1. `001_tablas.sql` — crea las tablas.
   2. `002_rls.sql` — activa las reglas de seguridad.
   3. `003_funciones.sql` — funciones para generar el QR y registrar sellos.
   4. `004_datos_demo.sql` — lugares públicos (coordenadas aproximadas) y comercios/eventos **ficticios**.
   5. `005_permisos.sql` — permisos (GRANT) para que la app pueda leer las tablas. Sin este archivo la app no muestra nada.
   6. `006_perfiles_faltantes.sql` — crea el perfil de cuentas registradas antes del trigger. Se puede correr cuando sea.
   7. `007_costo_eventos.sql` — agrega el costo aproximado de los eventos (la Agenda muestra "≈ $150 MXN").
   8. `008_negocios.sql` — registro de comerciantes, giros, Puntos VeraGo (demo: Parque Zamora con
      2 comerciantes **ficticios**) y estado de aprobación.
   9. `009_roles_enum.sql` — el rol pasa a ser una **lista cerrada**: en Table Editor aparece un menú
      con `usuario`, `comerciante` y `admin` (no se puede escribir otro).
   10. `010_admin_eventos.sql` — permite que el **admin** cree, edite y borre eventos **desde la app**
       (la regla RLS sigue impidiéndolo a cualquier otro rol).
   11. `011_admin_app.sql` — permite que el **admin** apruebe negocios y cree o edite lugares,
       Puntos VeraGo y horarios **desde la app** (tampoco se pueden borrar lugares: se ocultan).
   12. `012_sellos_solo_formales.sql` — **solo los negocios formales dan sellos**: les quita el
       sello a los no formales (Puntos VeraGo) y agrega una regla (CHECK) para que no vuelva a pasar.
   13. `013_cambio_ubicacion.sql` — el comerciante **pide** cambiar su ubicación (o de Punto VeraGo)
       y el **admin la acepta o rechaza**; mientras tanto sigue en su ubicación actual. También:
       un comerciante ya no puede sellarse a sí mismo y un QR deja de servir si el negocio se suspende.
   14. `014_costo_entrada.sql` — **costo de entrada** de un lugar: el negocio formal pone el suyo y el
       admin puede ponerlo o corregirlo en cualquier lugar (los no formales y los Puntos no cobran).
   15. `015_vitrina.sql` — **vitrina digital**: lista de productos o servicios (con precio aproximado) y
       una promoción por negocio, que el comerciante edita en "Mi vitrina".
   16. `016_estadisticas_y_borrar_cuenta.sql` — **estadísticas reales** (solo totales, sin datos
       personales) para el admin y para cada negocio, y **"Borrar mi cuenta"** desde Ajustes.
   17. `017_limpieza_pruebas.sql` — borra las **4 cuentas de prueba** (`@verago-demo.mx`) y el
       "Negocio de Prueba VeraGo" que creó la IA para probar. No toca nada del equipo.
   18. `018_fotos.sql` — **fotos**: crea el bucket `fotos-lugares` en Storage (público, máx. 2 MB, solo
       JPG/PNG/WEBP), sus reglas (admin a cualquier lugar; comerciante solo a su negocio) y la función
       `guardar_mi_foto`.
3. Revisar en **Table Editor** que existan las tablas y los datos.
4. En **Authentication → Sign In / Providers → Email**:
   - Dejar activado **Email**.
   - **Desactivar "Confirm email"** para la demo (así la cuenta funciona al instante).
     Si queda activado, la cuenta no puede iniciar sesión hasta abrir el enlace del correo,
     y el Pasaporte sigue pidiendo "Iniciar sesión". Además, el correo incluido de Supabase
     solo envía unos pocos mensajes por hora.
5. Si ya hay cuentas creadas sin confirmar, confirmarlas en **SQL Editor**:

```sql
-- Marca como confirmadas todas las cuentas pendientes (solo para la demo).
update auth.users set email_confirmed_at = now() where email_confirmed_at is null;
```

## Administrar desde Supabase

La app no tiene pantallas de administración: todo esto se hace en el panel de Supabase.

### Cambiar el rol (permisos) de una persona

Roles: `usuario` (por defecto), `comerciante` (puede mostrar el QR de su comercio) y
`admin` (ve estadísticas y administra todo).

- **Con clics:** Table Editor → `perfiles` → buscar a la persona → columna `rol`.
- **Con SQL** (SQL Editor):

```sql
update public.perfiles set rol = 'comerciante'
where id = (select id from auth.users where email = 'correo@ejemplo.com');
```

El cambio se ve al recargar el Pasaporte (jalar hacia abajo) o al volver a iniciar sesión.

### Asignar un comercio a un comerciante (para mostrar el QR en la demo)

1. Crear una cuenta desde la app (Pasaporte → Iniciar sesión → crear una).
2. Cambiar su `rol` a `comerciante` (arriba).
3. Asignarle el comercio:

```sql
update public.lugares
set dueno_id = (select id from auth.users where email = 'correo@ejemplo.com')
where nombre = 'Café Brisa del Golfo';
```

### Revisar y aprobar negocios ("Soy un negocio")

**Desde la app (lo normal):** cuenta admin → Pasaporte → **Panel de administración** →
**Solicitudes de negocios**. Ahí se ve cada solicitud con su ubicación en el mapa, la dirección
que escribió el comerciante y la dirección que da el mapa (para revisar que coincidan), y los
botones **Aprobar / Rechazar / Suspender / Reactivar** y **Guardar horario**.

Las solicitudes nuevas quedan con `estado_aprobacion = 'pendiente'` y **no** se ven en la app
hasta aprobarlas. El SQL de abajo es solo de respaldo para los desarrolladores.

```sql
-- APROBAR (después de que el comerciante pagó su espacio): aparece en la app.
-- participa_pasaporte = true SOLO si es formal (local propio); si es de un Punto VeraGo, false.
update public.lugares
set estado_aprobacion = 'aprobado', publicado = true, participa_pasaporte = (punto_id is null)
where nombre = 'Nombre del negocio';

-- RECHAZAR (libera el giro en el punto):
update public.lugares set estado_aprobacion = 'rechazado' where nombre = 'Nombre del negocio';

-- SUSPENDER (deja de verse en la app):
update public.lugares
set estado_aprobacion = 'suspendido', publicado = false
where nombre = 'Nombre del negocio';

-- HORARIO de un comerciante informal (ej. sábado y domingo de 17:00 a 21:00):
delete from public.horarios
where lugar_id = (select id from public.lugares where nombre = 'Nombre del negocio');
insert into public.horarios (lugar_id, dia_semana, abre, cierra)
select id, d, '17:00'::time, '21:00'::time from public.lugares, unnest(array[0, 6]) as d
where nombre = 'Nombre del negocio';
```

"Te notificaremos" es **manual**: el equipo avisa por correo o teléfono al comerciante.
El comerciante también puede ver su estado entrando en "Soy un negocio → Iniciar sesión".

**Crear un Punto VeraGo nuevo:** insertar un lugar con `es_punto = true`, `categoria_id = 8`,
`publicado = true`, sus coordenadas y su horario (ver el bloque de demo al final de `008_negocios.sql`).

**Correo para "¿Olvidaste tu contraseña?":** agregar `"SOPORTE_CORREO": "correo@del-equipo.com"`
a `env.json`. Si se deja vacío, la app dice "Contacta al equipo de VeraGo".

### Administrar la Agenda (desde la app)

Una cuenta con rol `admin` (asignado por un desarrollador) entra a la app y en **Agenda** ve:

- **"Nuevo evento"** (botón abajo a la derecha): título, descripción, lugar, inicio, fin,
  gratuito o costo aproximado, y estado.
- Al tocar un evento: **Editar**, **Publicar**, **Borrador**, **Cancelar** y **Eliminar**.

Estados: `publicado` (todos lo ven), **borrador** (`pendiente`, solo lo ven los admins) y
`cancelado` (se ve tachado para avisar). Requiere correr `010_admin_eventos.sql`.

### Si los eventos ya pasaron

Las fechas de los eventos ficticios se calculan cuando se corre `004_datos_demo.sql`.
Si ya pasaron, en **SQL Editor** borrar los eventos (`delete from eventos where es_demo;`)
y volver a correr solo el bloque de eventos de ese archivo.

## Cómo ejecutar la app

1. Copiar `env.example.json` como `env.json` y llenar:
   - `SUPABASE_URL`: Supabase → Project Settings → API → Project URL.
   - `SUPABASE_KEY`: la **publishable key** (pública).
   - **Nunca** poner la clave secreta (`service_role` / `secret`).
2. Desde la carpeta `verago`:

```bash
flutter pub get
flutter run --dart-define-from-file=env.json
```

Si `flutter` no se reconoce, usar la ruta completa (ej. `C:\Users\HP\flutter\bin\flutter.bat run ...`).

- **En una computadora sin Android Studio** solo se puede correr en Chrome:
  `flutter run -d chrome --dart-define-from-file=env.json`.
- **En un celular Android** hace falta Android Studio (Android SDK) y el celular conectado por USB
  con "Depuración USB" activada.

`env.json` está en `.gitignore`: no se sube a GitHub.

## Guion de la demo

0. (Primera vez) Pantalla de **bienvenida**: elegir intereses o "Saltar".
   Ahí mismo está **"Soy un negocio"** para mostrar el registro de comerciantes.
   Para volver a verla, borrar los datos de la app o desinstalarla.
1. Abrir VeraGo → **Explorar**: mapa del centro, filtrar "Cafeterías", abrir una ficha.
2. **Rutas** → 3 h → Historia y monumentos + Restaurantes → **Generar ruta**.
3. Mostrar paradas, motivos, "Quitar" una parada y la sugerencia "Te quedan X min".
4. Abrir la ficha de un comercio → ver "Da sello en tu pasaporte" y "Cerca de aquí".
5. **Pasaporte** → Iniciar sesión.
6. En otro celular (cuenta comerciante): Pasaporte → **Mostrar el QR de mi comercio**.
7. Visitante: **Escanear QR** → "¡Nuevo sello!" + sugerencia de otro lugar cercano.
8. Ver la colección y el historial actualizados.

Si no hay segundo celular: copiar el código que aparece debajo del QR y escribirlo en
"¿No funciona la cámara? Escribe el código".

## Comandos útiles

```bash
flutter analyze   # revisa errores y malas prácticas
flutter test      # corre las pruebas automáticas
```

## Configurar la guía con IA (Gemini)

1. Crear la clave en **Google AI Studio** (aistudio.google.com → Get API key). Es gratis.
2. Agregarla a `env.json` (NO se sube a GitHub) con el nombre `GEMINI_API_KEY` (también sirve `GEMINI_KEY`).
   Opcional: `GEMINI_MODELO` para cambiar de modelo (por defecto `gemini-flash-lite-latest`).
3. Volver a correr la app (detener con **q** y `flutter run ... --dart-define-from-file=env.json`).
4. **Restringir la clave** (importante: la clave queda dentro de la app compilada y en la web se puede ver):
   Google Cloud Console → proyecto del equipo → APIs y servicios → Credenciales → la clave →
   - *Restricciones de API*: solo **Generative Language API**.
   - *Restricciones de aplicación* (si publican la web): **Referentes HTTP** con su dominio.

Si falta la clave, el chat solo muestra "Falta configurar la guía"; el resto de la app funciona igual.
Si Google está saturado (error 503) o se acaba la cuota gratuita (429), el chat dice "Espera un minuto".

## Estructura

```text
lib/
├─ main.dart       → arranque: conecta con Supabase y abre la app
├─ config.dart     → lee las claves de env.json
├─ theme/          → colores y letras de VeraGo
├─ screens/        → pantallas (bienvenida, principal, explorar, lugar, rutas, ruta,
│                    agenda, pasaporte, ajustes, login, escanear, qr_comercio, estadisticas,
│                    negocio, negocio_registrado, estado_negocio, panel_comerciante, editar_negocio,
│                    evento_form, admin, admin_negocios, admin_lugares, admin_lugar_form)
├─ services/       → hablan con Supabase o hacen cálculos (rutas, distancias)
├─ models/         → clases de datos (Lugar, Evento, Sello, Perfil)
├─ legal/          → textos de Aviso de privacidad, Términos y Reglas operativas
└─ widgets/        → piezas visuales reutilizables (mapa, tarjetas, etiquetas)
test/              → pruebas automáticas (45)
supabase/migrations/ → SQL de la base de datos (001 a 018)
```

## Bitácora de IA

Registro de cómo usamos inteligencia artificial en el proyecto: qué herramienta, para qué y qué
decisiones se tomaron. Se actualiza con cada petición que hacemos a la IA.

**Regla del equipo:** la IA propone y escribe; el equipo decide. Las decisiones marcadas
como *Equipo* las tomamos nosotros cuando la IA nos preguntó.

### Herramientas

| Herramienta | Para qué la usamos |
| --- | --- |
| **Claude Code** (modelo Claude Opus 5.5, en VS Code) | Escribir y revisar el código Flutter/Dart y el SQL, correr `flutter analyze` y `flutter test`, diagnosticar errores con Supabase |
| **Claude Docs** (documentos compartidos de Claude) | Documentación integral del proyecto y guía de estudio con 100 preguntas para la demo |
| **ChatGPT** | Mencionado en `README.txt` de la raíz. *Pendiente: el equipo debe describir para qué se usó* |

### Registro

| # | Fecha | Petición al equipo de IA | Herramienta | Qué se hizo | Decisiones clave |
| --- | --- | --- | --- | --- | --- |
| 1 | 2026-11-11 | Documentación integral del proyecto (24 secciones) | Claude Code + Claude Docs | Documento técnico, funcional y de negocio | Nombre oficial **VeraGo** (*Equipo*). Lugares y comercios en una sola tabla. Rutas con algoritmo, no con IA generativa |
| 2 | 2026-11-11 | Simplificar tecnologías y explicar todo | Claude Code + Claude Docs | Documento reescrito con "qué es / qué hace / por qué" | Quitar Edge Functions, PostGIS, Riverpod/Bloc, Realtime; usar funciones de PostgreSQL y lo que trae Flutter (*Equipo pidió simplicidad*) |
| 3 | 2026-11-11 | Quitar el "café gratis" | Claude Code + Claude Docs | Se eliminaron recompensas y canjes del documento y del SQL | El pasaporte **solo junta sellos** (*Equipo*) |
| 4 | 2026-11-11 | Implementar la app (Fase 1: fundamentos) | Claude Code | Paquetes, tema visual, navegación, SQL 001–004, permisos Android/iOS | Solo el MVP del documento; comercios y eventos **100 % ficticios**; lugares públicos reales sin horarios inventados; sin fotos, íconos por categoría (*Equipo*). Clave pública en `env.json` fuera de GitHub |
| 5 | 2026-11-11 | Fase 2: experiencia del turista | Claude Code | Explorar (mapa/lista/filtros), ficha con "Cerca de aquí", agenda | Distancias desde el Zócalo para no pedir GPS al explorar |
| 6 | 2026-11-11 | Fase 3: rutas | Claude Code | Algoritmo voraz, pantalla de ruta, "Quitar", sugerencia cercana, 7 pruebas | Columna `en_recorrido_a_pie` para excluir San Juan de Ulúa de rutas a pie |
| 7 | 2026-11-11 | Fase 4: pasaporte | Claude Code | Login, QR del comercio que cambia cada 60 s, escaneo, sellos | Login con correo y contraseña (más simple que enlace mágico); plan B de escribir el código a mano |
| 8 | 2026-11-11 | Fase 5: cierre | Claude Code | Estadísticas con "DATOS SIMULADOS", README con guion de demo | Las estadísticas miden uso de la app, nunca afluencia real |
| 9 | 2026-11-11 | "No aparece nada en el celular" | Claude Code | Diagnóstico: la API respondía `permission denied`; se creó `005_permisos.sql` | Faltaban permisos GRANT (los proyectos nuevos de Supabase no los dan solos). `codigos_qr` se deja sin permisos a propósito |
| 10 | 2026-11-11 | "El pasaporte está vacío" | Claude Code | `006_perfiles_faltantes.sql` y la app tolera cuentas sin perfil | Cuentas creadas antes del trigger no tenían fila en `perfiles` |
| 11 | 2026-11-11 | Guía de estudio del código + preguntas | Claude Code + Claude Docs | Guía de 16 secciones con 100 preguntas y respuestas y guion de demo | Respuestas honestas sobre límites (distancias aproximadas, ruta no óptima, datos simulados) |
| 12 | 2026-11-11 | Crear esta bitácora de IA | Claude Code | Sección "Bitácora de IA" en este README | Se actualiza en cada petición futura |
| 13 | 2026-11-11 | Confirmar contraseña; ¿quién agenda eventos?; ¿cómo cambiar permisos?; mejorar UI/UX | Claude Code | Campo "Confirmar contraseña" al crear cuenta + prueba automática (17 en total). Se explicó quién crea eventos y cómo cambiar roles. Se propusieron mejoras de UI/UX | La IA no implementó mejoras de UI/UX sin aprobación (*Equipo pidió preguntar antes*) |
| 14 | 2026-11-11 | Implementar las mejoras de UI/UX elegidas | Claude Code | Pantalla de bienvenida (3 páginas, elegir intereses, se puede saltar), animación al ganar sello, botón de ojo en contraseñas, leyenda de colores y botón "centrar" en el mapa. 18 pruebas automáticas | *Equipo* eligió: bienvenida y detalles visuales. *Equipo* decidió: eventos y roles se siguen manejando desde el panel de Supabase (sin pantallas nuevas de admin) |
| 15 | 2026-11-11 | Actualizar README y documentación con lo que faltaba | Claude Code + Claude Docs | README: tecnologías, enlaces a documentos, estado real, "Qué NO hace la app", cómo cambiar roles, asignar comercio y crear eventos. Guía: estructura de archivos, bienvenida, 18 pruebas, preguntas 101–106. Documento integral: permisos reales (eventos y fichas solo por admin en Supabase), sección de GRANT, RF-17/18, estructura de carpetas real, columnas `clave`, `es_gratuito`, `es_demo` | Los documentos describen **lo implementado**, no lo planeado: se corrigieron partes que decían que el comerciante crea eventos o edita su ficha |
| 16 | 2026-11-11 | "El pasaporte no muestra nada" (pedía iniciar sesión aunque ya habían entrado) | Claude Code | 2 pruebas nuevas que dibujan el pasaporte con datos (descartan errores de diseño). Se leyó la configuración pública de Auth: `mailer_autoconfirm: false` → "Confirm email" activado. Login ahora explica con un cuadro de diálogo si falta confirmar el correo; el pasaporte se recarga al volver del login. 20 pruebas | Causa: cuentas sin confirmar no pueden iniciar sesión. Solución: desactivar "Confirm email" y confirmar cuentas pendientes por SQL. *Equipo* autorizó crear una cuenta de prueba, pero no hizo falta (Supabase rechazó `example.com` y la causa se encontró sin ella) |
| 17 | 2026-11-11 | "El inicio de sesión sigue sin funcionar" | Claude Code | Se volvió a leer la configuración de Auth: `mailer_autoconfirm` sigue en `false` (la confirmación de correo sigue activada en Supabase). Se dieron los pasos exactos para desactivarla | No se cambió código: la causa es la configuración del proyecto, y la app no puede saltarse la confirmación (sería un hueco de seguridad). No se crearon cuentas de prueba para no gastar el límite de correos del proyecto |
| 18 | 2026-11-11 | Botón de ajustes en Pasaporte; el pasaporte sigue sin mostrar información | Claude Code | Pantalla **Ajustes** (engrane): mi cuenta con cambiar nombre, mis intereses, ver bienvenida otra vez, privacidad y cerrar sesión; 2 pruebas (22 en total). Diagnóstico: con "Confirm email" ya apagado (`mailer_autoconfirm: true`) se creó la cuenta de prueba `prueba.verago@verago-demo.mx` (dominio inventado, sin envío de correo) y se repitieron las consultas de la app: perfil, sellos y comercios responden bien | *Equipo* eligió las 4 opciones de Ajustes. Conclusión: la base de datos funciona; lo más probable es que sus cuentas viejas sigan sin confirmar → correr el `UPDATE` de confirmación. El botón de cerrar sesión se movió dentro de Ajustes. *Pendiente:* borrar la cuenta de prueba al terminar |
| 19 | 2026-11-11 | "No entró ni con la cuenta de prueba" (captura en Chrome/web) | Claude Code | Se comprobó con la librería `supabase` fuera de Flutter que el login con la cuenta de prueba devuelve sesión y lee el perfil (backend OK). Un intento de prueba automática en Chrome se quedó colgado en "loading" y se detuvo; los archivos temporales de diagnóstico se borraron. El login ahora muestra el **detalle técnico del error solo en modo desarrollo** (`kDebugMode`) y avisa si Supabase no devuelve sesión | La falla está en la app al correr en web, no en Supabase. Se necesita el mensaje exacto que aparece al tocar "Entrar" para ubicarla. En la versión final no se muestran detalles técnicos |
| 20 | 2026-11-11 | Log de la consola de Chrome: `setState() callback argument returned a Future` | Claude Code | **Causa real del Pasaporte vacío:** se escribía `setState(() => _futuro = ...)`; la flecha `=>` devuelve el Future asignado y Flutter rechaza ese setState, así que la pantalla no se actualizaba aunque el login sí funcionaba. Se corrigieron 7 lugares (Pasaporte, y el botón "Reintentar" de Explorar, Agenda y Rutas) usando llaves `{ }`, y `..ignore()` para que un error temprano de red no se reporte como "no atendido". Prueba nueva que toca "Reintentar" | El log del equipo fue clave. Las pruebas anteriores no lo detectaban porque nunca recargaban con sesión ni tocaban "Reintentar"; ahora sí |
| 21 | 2026-11-11 | Costo aproximado en la Agenda; ¿la Agenda es para eventos o para apuntar planes / alertas? | Claude Code | Columna `costo_aprox_mxn` (SQL 007) y etiqueta en cada evento: "Gratuito", "≈ $150 MXN" o "Con costo"; también en el detalle. 3 pruebas (25 en total). Se explicó qué es la Agenda hoy | Costo solo en **eventos**; no se inventan precios de lugares reales (museos). El costo del taller ficticio también es ficticio y se marca así. El cambio de concepto de la Agenda queda a decisión del *Equipo* |
| 22 | 2026-11-11 | Módulo de comerciantes "Soy un negocio" (registro por defecto, inicio de sesión, confirmación, estados, validaciones) | Claude Code | SQL 008: tabla `giros`, columnas `estado_aprobacion`, `es_punto`, `punto_id`, `giro_id`; reglas UNIQUE (un giro por punto, nombre comercial único); funciones protegidas `registrar_negocio`, `giros_ocupados`, `actualizar_mi_negocio`, `guardar_mi_horario`; Punto VeraGo Parque Zamora (demo) con 2 comerciantes ficticios. App: pantalla única con registro (predeterminado) e inicio de sesión, selector de ubicación en mapa, confirmación, estado de solicitud, panel (QR, ficha, editar datos y horario). Rutas: al menos 1 comercio formal y 1 Punto VeraGo. 8 pruebas nuevas (33 en total) | *Equipo* definió el modelo: **Puntos VeraGo** rentados a informales, **un negocio por giro en cada punto**, formales marcan su local en el mapa, giros fijos y horario asignado por el admin, rutas con al menos 1 formal + 1 punto, recuperar contraseña = contacto con el equipo, panel = QR + ficha + editar, acceso en bienvenida y Ajustes. La IA propuso hacer el registro con una función protegida (nadie se da el rol a sí mismo) y dejar los pagos fuera de la app |
| 23 | 2026-11-11 | "En Supabase solo se permitan los roles que hay" | Claude Code | SQL 009: `rol` pasa de texto con CHECK a **ENUM** `rol_usuario` (`usuario`, `comerciante`, `admin`). En Table Editor aparece un menú desplegable | Antes ya se rechazaban valores inválidos (CHECK), pero se escribían a mano; con ENUM no se puede escribir otro valor |
| 24 | 2026-11-11 | "En perfiles no se guarda el correo, ¿cómo se inicia sesión?" | Claude Code | Explicación: correo y contraseña (cifrada) viven en `auth.users` (Supabase Auth); `perfiles` comparte el mismo `id` y guarda nombre y rol. Se dio una consulta SQL de solo lectura para ver correo + rol juntos | Sin cambios de código. Se ofreció agregar una columna `correo` a `perfiles`; queda a decisión del *Equipo* |
| 25 | 2026-11-11 | Poner el logo de VeraGo en la app | Claude Code | Con un script de Python (Pillow) se recortó la imagen del equipo y se generaron: `assets/logo.png` (fondo transparente) y todos los íconos de Android, iPhone y web (logo centrado en cuadrado blanco). Logo en la bienvenida y en el registro de negocios (widget `VgLogo`). Nombre "VeraGo" en la versión web | *Equipo* eligió: ícono de la app + bienvenida + registro de negocios. Sin paquetes nuevos (se evitó `flutter_launcher_icons`) |
| 26 | 2026-11-11 | Dejar de editar la documentación; botón "Soy un negocio" en Pasaporte; teléfono de 10 números; dirección vs. ubicación del mapa; admin edita la Agenda desde la app (solo desarrolladores en Supabase) | Claude Code | Botón "Soy un negocio" en Pasaporte (invitado y usuario; el comerciante ve su panel). Teléfono: el campo solo acepta números, máximo 10, con contador. SQL 010 + formulario de evento + opciones de admin en la Agenda (editar, publicar, borrador, cancelar, eliminar). 6 pruebas nuevas (39 en total). Se propusieron soluciones para validar la dirección contra el mapa | *Equipo*: la guía de estudio y el documento integral ya **no se editan**; solo el README. La seguridad de la Agenda la da la regla RLS (solo admin), no la app. Aprobar negocios y cambiar roles sigue en Supabase hasta que el *Equipo* decida pasarlo a la app. La validación de dirección queda en espera de decisión del *Equipo* |
| 27 | 2026-11-11 | Implementar la validación de dirección (A + C) y pasar a la app: aprobar negocios y lugares/Puntos VeraGo | Claude Code | **A:** al tocar el mapa la dirección se llena sola con Nominatim (OpenStreetMap) vía el paquete `http`. **C:** el detalle de cada solicitud muestra la dirección escrita junto a la del mapa. SQL 011 (GRANT de escritura en `lugares` y `horarios`; RLS solo admin). Panel de administración (reemplaza el botón de estadísticas del admin): solicitudes de negocios (aprobar, rechazar, suspender, reactivar, horario) y lugares/Puntos VeraGo (crear, editar, ocultar, horario). Widget `EditorHorario` reutilizable. 6 pruebas nuevas (45 en total); compila para web | *Equipo* eligió A + C, aprobar negocios y lugares/Puntos en la app; **cambiar roles sigue en Supabase**. Los lugares no se borran (tienen sellos y eventos): se ocultan. A Nominatim solo se envían coordenadas del negocio/lugar, nunca la ubicación del usuario |
| 28 | 2026-11-11 | "¿Ya añadiste todo a la guía de estudio?" | Claude Code | Se respondió que no: la guía quedó hasta las preguntas 111–116 (comerciantes y roles). Se listó lo que falta (logo, botón en Pasaporte, teléfono, Agenda del admin, dirección automática, panel de administración) | Sin cambios: el *Equipo* pidió no editar la documentación. Se ofreció actualizar la guía solo si lo confirman |
| 29 | 2026-11-11 | "Eliminé a un compañero de la base de datos pero lo deja entrar" | Claude Code | Explicación: el acceso lo decide Supabase Auth (`auth.users`), no la tabla `perfiles`; borrar solo el perfil no quita la cuenta, y la app tolera cuentas sin perfil (rol "usuario"). Pasos para borrarlo en Authentication → Users (borra en cascada perfil y sellos) o, si solo se quieren quitar permisos, cambiar su rol | Sin cambios de código. Se ofreció bloquear en la app las cuentas sin perfil; queda a decisión del *Equipo* |
| 30 | 2026-11-11 | Quitar el error largo que sale al iniciar sesión con datos incorrectos | Claude Code | Se eliminó el "[Detalle técnico: …]" que se agregó en la entrada 19 para diagnosticar; ahora solo sale el mensaje amable ("Correo o contraseña incorrectos."). 45 pruebas pasan | El diagnóstico ya no hace falta (el problema del Pasaporte se resolvió en la entrada 20). Mostrar solo mensajes amables evita revelar información interna |
| 31 | 2026-11-11 | ¿Dónde se aceptan comerciantes desde la app? | Claude Code | Sin cambios de código. Se explicó la ruta: Pasaporte → Panel de administración → Solicitudes de negocios → pestaña Pendientes → tocar el negocio → revisar datos y direcciones → Aprobar (o Rechazar) | El botón solo aparece con rol `admin` y la aprobación necesita el SQL 011 corrido. La app no avisa al comerciante: se le debe avisar por teléfono o correo |
| 32 | 2026-11-11 | ¿Dónde está la guía de estudio? | Claude Code | Sin cambios de código. Se volvió a compartir el enlace de la guía de estudio (también está al inicio de este README) | La guía no se ha actualizado desde que el *Equipo* pidió dejar de editar la documentación; lo más reciente (admin en la app, dirección automática, panel de negocios) solo está en este README |
| 33 | 2026-11-11 | Mejorar las rutas (error sin intereses), rutas por categorías, separar negocios formales y no formales, solo formales dan sellos | Claude Code | **Rutas:** elegir al menos un interés es obligatorio (botón apagado y aviso en rojo); se limpian intereses guardados de categorías que ya no existen; el algoritmo ahora **solo usa las categorías elegidas** (antes solo les daba +2 puntos) más 1 comercio formal y 1 Punto VeraGo; los chips ya no muestran "Puntos VeraGo" ni categorías que no pueden ser parada; la sugerencia final solo propone negocios formales; si no hay ruta, botón "Cambiar preferencias". **Sellos:** SQL 012 (quita sellos a no formales + regla CHECK `sello_solo_formales`); al aprobar, solo los formales quedan con sello; el panel de un negocio no formal ya no muestra "Mostrar mi QR". **Formal / no formal:** etiqueta en tarjeta y ficha, y filtro Todos / Formales / No formales en Solicitudes de negocios. 5 pruebas nuevas (50 en total) | *Equipo* eligió: generador filtrado (la IA lo recomendó en vez de rutas creadas por el admin: menos trabajo y la ruta sigue siendo "a la medida"), no formales sin QR ni sellos, etiqueta en tarjeta/ficha y filtro en el panel del admin. Los sellos ya dados por no formales se quedan en el historial. **Falta correr SQL 012** |
| 34 | 2026-11-11 | Explicar el modelo de negocio y la lógica de la app para que el *Equipo* confirme; (en curso) cambio de ubicación con aprobación del admin y revisión completa | Claude Code | Explicación del modelo (roles, formales/no formales, Puntos VeraGo, sellos, rutas, agenda, admin). Pruebas reales contra Supabase con cuentas de prueba `turista.prueba@verago-demo.mx` y `comercio.prueba@verago-demo.mx` (negocio ficticio "Negocio de Prueba VeraGo", pendiente): **29 de 29 pasan** (nadie se da rol admin, nadie se aprueba solo, nadie escribe sellos directo, cada quien ve solo lo suyo) | *Equipo* eligió: durante el cambio el negocio sigue en su ubicación actual; los no formales también pueden pedir cambiarse de Punto VeraGo; se pueden usar cuentas de prueba. Se pausó la implementación hasta que el *Equipo* confirme el modelo |
| 35 | 2026-11-11 | Reglas operativas, privacidad, términos y confianza; ventana "Confirmar / Cancelar" antes de registrar un negocio; (continuación) cambio de ubicación con aprobación y revisión completa | Claude Code | **Legal y confianza** (Ajustes): ¿Cómo funciona VeraGo?, Reglas operativas, Términos de uso, Términos para negocios y Aviso de privacidad (con derechos ARCO), en `lib/legal/documentos.dart`. Ventana de términos al registrar negocio; enlaces al crear cuenta; "Reportar un problema" (copia el reporte, no se guarda nada). **SQL 013:** solicitar/cancelar/resolver cambio de ubicación; `actualizar_mi_negocio` ya no cambia la dirección; `registrar_visita` rechaza sellarse a sí mismo (`ES_TU_NEGOCIO`) y QR de negocios que ya no dan sellos. App: pantalla "Cambiar ubicación", aviso en el panel con "Cancelar", filtro "Cambios de ubicación" y revisión en el panel del admin. **Arreglos de la revisión:** el QR reintenta si falla la red y usa el reloj del celular; texto viejo "asignarlo en Supabase"; botón "Actualizar" en Explorar y Rutas; "Crear cuenta" ahora exige 8+ caracteres con letras y números (igual que negocios); "Ver mi ficha" ya no truena sin internet. 9 pruebas nuevas (**59 en total**). Cuenta de prueba `admin.prueba@verago-demo.mx` creada; script de pruebas del admin listo | *Equipo* confirmó el modelo y eligió: los 4 documentos + "¿Cómo funciona VeraGo?", turistas solo con texto y enlaces, "Reportar un problema". La IA propuso reportes sin base de datos (copiar y enviar por correo) para no agregar tablas. Los textos legales son de hackatón: deben revisarse por un abogado. **Falta:** correr SQL 012 y 013, dar rol admin a la cuenta de prueba, y luego borrar las 3 cuentas de prueba |
| 36 | 2026-11-11 | ¿Quién pone el costo de entrada de un lugar: el comercio o el admin? | Claude Code | **SQL 014:** columna `costo_entrada_mxn` (vacío = sin dato, 0 = gratis, >0 = pesos aprox.), regla CHECK (no formales y Puntos VeraGo no cobran entrada) y función protegida `guardar_mi_costo_entrada` para el negocio formal. App: editor de costo en "Editar mis datos" (No cobro / Cobro entrada), en el formulario de lugares del admin (Sin confirmar / Gratis / Con costo) y en la solicitud de cada negocio formal; ficha: "Entrada gratis", "Entrada aprox. $X MXN" o, en lugares públicos sin dato, "Costo de entrada no disponible: confírmalo en el lugar"; tarjeta: etiqueta solo si cobra. Términos y Reglas actualizados. 6 pruebas nuevas (**65 en total**) | *Equipo* eligió: lo ponen **ambos** (negocio el suyo, admin cualquiera), el del negocio **se publica directo** sin aprobación, y se muestra en ficha y tarjeta (no en la ruta). La IA propuso "Sin confirmar" para lugares públicos para no inventar precios reales. **Falta correr SQL 014** |
| 37 | 2026-11-11 | "No me deja guardar los cambios, me da error en lugares" | Claude Code | **Causa:** en Supabase aún no se corren los SQL 012, 013 ni 014 (se revisó: la columna `costo_entrada_mxn` no existe), y el formulario de lugares siempre enviaba el costo, así que Supabase rechazaba todo el guardado. **Arreglo:** el costo solo se envía si el admin lo cambia (`incluirCosto`); si falta un SQL, el error ahora dice "Falta actualizar la base de datos (correr el SQL más reciente)" en lugar de un mensaje genérico o "Revisa tu conexión" (admin y comerciante). 1 prueba nueva (**66 en total**) | La app no debe romperse por un SQL pendiente. **Falta correr SQL 012, 013 y 014 en orden** |
| 38 | 2026-11-11 | "La ubicación no funciona en el mapa, no dice dónde estoy" | Claude Code | **Causa:** el mapa nunca mostraba la ubicación del turista (por diseño medía desde el Zócalo), y el botón "Centrar" usaba el ícono de "mi ubicación" (🎯), lo que confundía. **Cambios:** botón nuevo "Mostrar dónde estoy" en el mapa de Explorar (pide permiso, punto azul "Estás aquí", centra el mapa); la lista y la tarjeta miden distancias desde el turista; el botón "Centrar" cambió de ícono; el mapa de la ruta marca el inicio si es "Mi ubicación"; si el turista está a más de 15 km del Zócalo, se avisa y se usa el Zócalo (en Explorar y en Rutas, antes salía "No encontramos una ruta"). 2 pruebas nuevas | *Equipo* eligió: botón en Explorar + marca en la ruta, distancias desde el turista, ubicación tomada **una sola vez** (no lo sigue; el Aviso de privacidad no cambia). Los permisos de Android/iPhone ya estaban bien |
| 39 | 2026-11-11 | "¿No es mejor que el admin dibuje la ruta? La app cruza los edificios en línea recta" | Claude Code | `TrazoService`: pide a OSRM (servidor de rutas a pie de OpenStreetMap, routing.openstreetmap.de) el camino por las calles entre las paradas y lo dibuja como línea continua; del inicio a la 1.ª parada va punteado; sin internet, línea recta como antes. Se guarda en memoria para no repetir peticiones. Se probó el servidor con coordenadas reales del centro (camino de 29 puntos, ~1 km) y permite el uso desde el navegador (CORS). Aviso de privacidad actualizado. 5 pruebas nuevas (**73 en total**) | La IA explicó que el admin no puede dibujar rutas que se arman a la medida de cada turista (habría que volver a rutas fijas). *Equipo* eligió: trazo automático por las calles, enviar **solo las paradas** (nunca la ubicación del turista) y **solo el dibujo** (los tiempos siguen siendo los estimados) |
| 40 | 2026-11-11 | Decirle al comerciante que, si su solicitud está pendiente, espere mientras un admin la revisa | Claude Code | Pantalla "Solicitud en revisión": "Por favor espera mientras un administrador de VeraGo revisa tu solicitud" + recuadro "¿Qué pasa ahora?" (qué se revisa, no necesitas hacer nada, te contactaremos por teléfono o correo, mientras tanto no apareces en la app) + botón "Revisar de nuevo". Mismo mensaje al terminar el registro. **Arreglos:** se quitó "Te avisaremos / Te notificaremos" (la app no envía notificaciones); desde Pasaporte → Panel de mi negocio, la pantalla de pendiente salía con dos barras de título encimadas. 3 pruebas nuevas (**76 en total**) | La app no tiene notificaciones (decisión de MVP), así que el mensaje dice que el aviso llega por teléfono o correo |
| 41 | 2026-11-11 | Botón de emergencia 911; ¿los términos dicen que no nos hacemos responsables de accidentes y robos?; organizar Términos y Aviso de privacidad; Explorar dice "Centro Histórico" estando en el Tecnológico; la línea del inicio de la ruta sale recta | Claude Code | **911:** paquete `url_launcher` + `BotonEmergencia` (abre `tel:911`; si el aparato no puede llamar, avisa que marquen 911); en la ruta (botón flotante rojo) y en la barra de Explorar; `<queries>` DIAL en Android. **Legales (versión 2):** Términos de uso en 11 secciones con "Tu seguridad" y "Limitación de responsabilidad" (accidentes, lesiones, asaltos, robos, extravíos, actos de terceros, clima, tránsito, negocios, eventos, fallas) y "VeraGo no es servicio de emergencias"; Aviso de privacidad en 13 secciones (ubicación, celular robado o perdido, cómo protegemos los datos, ARCO con plazo de 20 días hábiles, menores); Términos para negocios con "Responsabilidad del negocio" y permisos; Reglas operativas con "Emergencias". **Explorar:** el texto de arriba era fijo; ahora dice "Mostrando el Centro Histórico" o, con ubicación, "Estás a X km del Centro Histórico" (se calcula en el celular). **Ruta:** el primer tramo también va por las calles (antes salía recto incluso desde el Zócalo). 4 pruebas nuevas (**80 en total**) | La respuesta a la pregunta fue: antes solo había una frase general ("no se hace responsable de lo que pase durante tu recorrido"). *Equipo* eligió: botón en la ruta y en Explorar, abrir **directo** sin confirmar, y **sí enviar** el punto de inicio al servicio de rutas (cambia la decisión de la entrada 39; el Aviso de privacidad ya lo dice). El botón no llama solo: abre la app de llamadas con el número escrito |
| 42 | 2026-11-11 | 1) Siendo admin, al crear un negocio me pide otra vez datos y contraseña; 2) la ubicación debería detectarse sola al abrir; 3) en Explorar se queda la última búsqueda aunque actualice | Claude Code | **1:** con sesión abierta (turista o admin), "Soy un negocio" ya no pide nombre, correo ni contraseña: muestra "Se registrará con tu cuenta" (con "Usar otra" para cerrar sesión) y el negocio se liga a esa cuenta (un admin conserva su rol). Si la cuenta ya tiene negocio, abre directo su panel o el estado de su solicitud (el admin no ve "Panel de mi negocio" en el Pasaporte). **2:** Explorar pide la ubicación una vez al abrir; si no hay permiso o GPS, sigue desde el Zócalo sin mensajes. Aviso de privacidad (versión 3) y texto de permiso de iPhone actualizados. **3:** el buscador tiene "X" para borrar; "Actualizar" borra búsqueda, filtro y selección; el teclado se cierra al buscar, al tocar fuera o al cambiar de pestaña. 1 prueba nueva (**81 en total**) | *Equipo* eligió: usar la cuenta con sesión (no dar de alta negocios sin dueño). La ubicación sigue tomándose **una vez** (no se sigue al turista) y solo en el celular |
| 43 | 2026-11-11 | Revisión general en busca de errores; mejorar la guía de estudio | Claude Code + Claude Docs | **Errores corregidos:** 1) el selector de fecha cerraba la app al editar un evento que ya había empezado (fecha mínima posterior a la del evento); 2) si a alguien le rechazaban su negocio, "Soy un negocio" lo mandaba siempre a "rechazado" y no podía volver a intentarlo (la base sí lo permite): ahora se queda en el formulario con un aviso; 3) cambiar intereses en Ajustes no se reflejaba en Rutas hasta reiniciar (`ValueNotifier` en `PreferenciasService`); 4) Agenda sin eventos no se podía recargar (botón "Actualizar"). Se confirmó en Supabase que ya corrieron los SQL 012, 013 y 014; las pruebas del admin no se pudieron hacer porque la cuenta `admin.prueba@verago-demo.mx` aún no tiene rol admin (sí se comprobó que un no admin no puede aceptar cambios de ubicación ni moverse). La app compila para web. 1 prueba nueva (**82 en total**). **Guía de estudio:** se corrigió lo desactualizado (algoritmo de rutas con filtro por intereses, eventos y aprobaciones ahora desde la app, paquetes, tablas, migraciones 007–014, mapa de archivos, privacidad, número de pruebas, antitrampas) y se agregaron la sección 17 (modelo de negocio, vida de un negocio con diagrama, mapa/trazo/911, legal, panel del admin, costo de entrada, archivos nuevos y errores arreglados), el guion 11.4 de negocio y admin y la sección 18 con 24 preguntas nuevas (140 en total) | El *Equipo* pidió explícitamente actualizar la guía (excepción a "no editar la documentación"). Un admin del equipo rechazó el negocio de prueba, lo cual está bien |
| 44 | 2026-11-11 | 1) Dos usuarios con el mismo correo; 2) insignia que mejora cada x negocios; 3) buscar cualquier lugar; 4) onboarding que guíe; 5) eventos que se repiten; 6) ¿dónde está la vitrina digital? | Claude Code | **1:** se probó contra Supabase: crear una cuenta con un correo existente (también con otras mayúsculas) responde "User already registered"; lo más probable es que sean dos perfiles con el mismo NOMBRE (la tabla `perfiles` no guarda el correo). **2:** `Insignia` + `InsigniaVisual` + tarjeta en el Pasaporte (nivel, barra de avance, "te faltan N sellos", fila de los 5 niveles). **3:** `GeocodificacionService.buscar` (Nominatim, rectángulo Veracruz–Boca del Río) + pin morado y lista "En el mapa"; probado en vivo ("Tecnológico" encuentra el Instituto Tecnológico de Veracruz). **4:** bienvenida de 7 páginas con la barra dibujada. **5:** `DatosEvento.repetir` + `crearVarios` (una sola petición) + vista previa de fechas + validación (1–60 días, 2–30 veces, sin encimarse). **6:** era el Módulo 4 del documento original; en el MVP solo era la ficha. **SQL 015** (`vitrina_productos` jsonb y `promocion`, función `guardar_mi_vitrina`) + pantalla "Mi vitrina" + sección en la ficha + etiqueta. Términos (v4) y Aviso actualizados. 9 pruebas nuevas (**91 en total**) | *Equipo* eligió: 5 niveles jarochos, mostrar en el mapa (sin ruta), ampliar la bienvenida (no recorrido sobre la app), "cada N días, M veces" y vitrina con productos y promoción (sin fotos). Nominatim no permite buscar mientras se escribe: por eso se busca solo al tocar el botón. **Falta correr SQL 015** |
| 45 | 2026-11-12 | Error en la terminal: "AppInspector: Error calling Runtime.evaluate … Cannot find context with specified id" | Claude Code | Sin cambios de código. Explicación: es un aviso del depurador de Flutter para web (no de la app): aparece cuando la pestaña de Chrome se recarga (F5), se cierra o Chrome la "duerme", y el depurador pierde la conexión con la página. Se revisó que el botón 911 no lo causa (en Chrome abre otra pestaña). Solución: no recargar con F5 (usar r/R en la terminal) o detener con q y volver a correr; alternativa sin depurador: `flutter run -d web-server` | Es ruido del modo depuración; no afecta a la app ni a los datos |
| 46 | 2026-11-12 | 1) En el historial del Pasaporte aparecen los escaneos que le hicieron a mi negocio; 2) buscar errores en las insignias; 3) ¿qué mejorarías? | Claude Code | **1 (causa):** la regla RLS de `visitas` deja al **admin** ver los sellos de todos, y `misSellos()` no filtraba por usuario: un admin con negocio veía en su historial a quienes lo escanearon. Se agregó `.eq(usuario_id, …)`. **2:** el mismo error inflaba la insignia del admin con sellos ajenos (corregido con lo anterior); las insignias bloqueadas medían menos que las ganadas y la fila de 5 quedaba desalineada (corregido). Se documentaron dos efectos de la fórmula: con menos de 5 negocios se ganan varios niveles con un sello, y el nivel puede bajar si se aprueban negocios nuevos o se suspende uno sellado (pendiente de decisión del *Equipo*). **3:** lista de mejoras propuestas, sin implementar. 1 prueba nueva (**92 en total**) | Los turistas que escanean siguen viendo su sello (correcto). Se proponen mejoras y se espera que el *Equipo* elija |
| 47 | 2026-11-12 | Aplicar las mejoras 2 (estadísticas reales), 5 (borrar mi cuenta) y 6 (limpieza, correo ververagoo@gmail.com); "deja los números, tengo que tener datos ficticios" | Claude Code | **SQL 016:** `estadisticas_admin()` y `estadisticas_mi_negocio()` (solo totales: cuentas, turistas con sellos, sellos totales y de 7 días, por día de los últimos 14, top 5 negocios) y `borrar_mi_cuenta()` (borra negocio sin aprobar, oculta el publicado, borra `auth.users` → perfil y sellos en cascada; un admin no se borra). App: estadísticas con selector **Demostración (ficticio, por defecto) / Reales**, "Mis estadísticas" en el panel del comerciante, "Borrar mi cuenta" en Ajustes con confirmación. Aviso de privacidad v5. **Limpieza:** SQL 017 borra solo las 4 cuentas `@verago-demo.mx` y el negocio de prueba; `SOPORTE_CORREO` = ververagoo@gmail.com en `env.json`, en `env.example.json` y como valor por defecto en `config.dart` (no es secreto, así todos lo reciben). 6 pruebas nuevas (**98 en total**) | El *Equipo* pidió conservar los números ficticios para la demo: se dejan por defecto con aviso "DATOS FICTICIOS" y lo real queda en "Reales". Las pruebas del admin contra Supabase ya no se harán porque las cuentas de prueba se borran. **Falta correr SQL 016 y 017** |
| 48 | 2026-11-12 | Revisar que todos los campos tengan restricciones según lo que piden (nombre sin números, nombre de negocio con números, edad sin letras…) | Claude Code | Se revisaron los 30 campos de texto de 12 pantallas (no hay ningún campo de edad). Nuevas reglas en `validaciones.dart`, cada una con **formateador** (no deja escribir lo que no va) y **validador** (revisa al guardar): nombre de persona (solo letras, espacios, apóstrofo, guion y punto; el encargado debe poner nombre y apellido) en Crear cuenta, Ajustes y registro de negocio; nombre de negocio, lugar, producto y título de evento (letras, números y signos comunes; debe llevar letras); dirección (letras, números, #, °, /; con nombre de calle); descripciones y promoción (deben llevar palabras); precios y costos (solo números, máx. 100 000; antes el costo de entrada aceptaba letras); correo (sin espacios, máx. 254); contraseña (máx. 72); teléfono (10 números, ya estaba); código del QR escrito a mano (VG- + 32, se normalizan mayúsculas); buscador (máx. 80). 12 pruebas nuevas (**110 en total**) | Son restricciones de comodidad en la app; las reglas importantes también viven en la base de datos (precios, largos de vitrina, CHECK). La dirección es flexible porque también se llena sola desde el mapa |
| 49 | 2026-11-12 | Implementar el chat de VeraGo con la API de Gemini (prompt del equipo: contexto JSON de lugares, respuesta JSON con `respuesta` y `lugares_ids`, clave fuera de GitHub, tarjetas en el chat); "¿qué tengo que hacer?"; datos del proyecto de Google Cloud | Claude Code | `GuiaIaService` (REST con `http`: `systemInstruction` con la lista de lugares en JSON compacto — id, nombre, descripción recortada, categoría, tipo formal/no formal/punto/público, costo, abierto ahora, minutos desde el Zócalo, promoción, productos —, `responseMimeType: application/json` + `responseSchema`, clave en el encabezado `x-goog-api-key`, ids inventados se descartan, historial de los últimos 10 mensajes). `ChatGuiaScreen` (burbujas, sugerencias, tarjetas `TarjetaLugar`, aviso de IA y privacidad) y botón flotante en Explorar. Config acepta `GEMINI_API_KEY` o `GEMINI_KEY`. **Probado en vivo:** la clave del equipo es válida; `gemini-2.5-flash` y `gemini-1.5-flash` ya no se dan a usuarios nuevos (404) y el flash normal estaba saturado (503); `gemini-flash-lite-latest` respondió en ~1.5 s con lugares correctos ("con sombra para ir con niños" → Zócalo y Portales de Lerdo). Aviso de privacidad y Términos v6. 7 pruebas nuevas (**117 en total**) | *Equipo* confirmó volver a usar IA solo para este chat, botón en Explorar, clave en env.json restringida en Google (sin Edge Functions) y memoria solo mientras el chat está abierto. La IA advirtió que la clave queda dentro de la app compilada (en web es visible): por eso hay que restringirla. El nombre y número del proyecto de Google Cloud no hacen falta en el código; sirven para restringir la clave |
| 50 | 2026-11-12 | "Cuando selecciono museos aparece Juan Carnitas": que la ruta solo traiga lo que selecciono | Claude Code | **Causa:** la regla del equipo (entrada 22) metía a fuerza 1 negocio formal y 1 Punto VeraGo en toda ruta, aunque no se eligieran. **Cambio:** se quitó esa regla de `RutasService` (ya no hay prioridad +1000): solo entran las categorías elegidas. Los **Puntos VeraGo** ahora aparecen como interés en "¿Qué te interesa?". La **sugerencia del final** de la ruta ("Te quedan X min…") también respeta los intereses. Textos de Rutas y de "¿Cómo funciona VeraGo?" actualizados. Pruebas de rutas ajustadas + 1 nueva (**118 en total**) | Decisión del *Equipo*: cambia la regla de la entrada 22. El apoyo a negocios ahora depende de que el turista elija cafeterías, restaurantes, tiendas o Puntos VeraGo |
| 51 | 2026-11-12 | ¿Ya puedo hacer commit? | Claude Code | Sin cambios de código. Revisión antes del commit: 12 archivos pendientes (chat con IA y rutas solo con intereses), `flutter analyze` sin problemas y 118 pruebas pasan; la clave de Gemini y `env.json` NO están en los archivos a subir (`env.json` y `build/` están en `.gitignore`); no hay claves secretas de Supabase. En Supabase ya existen el SQL 015 (vitrina) y 016 (estadísticas, protegido: un anónimo recibe "permission denied") | El commit lo hace el *Equipo* |
| 52 | 2026-11-12 | 1) Cambiar el ícono de "Pregúntale a VeraGo" (se veía muy Gemini); 2) fotos de los establecimientos: el admin a cualquiera, el comerciante solo a su negocio | Claude Code | **1:** ícono de destellos (`auto_awesome`) → guía con audífonos (`support_agent`). **2:** SQL 018 (bucket público `fotos-lugares` en Supabase Storage, máx. 2 MB, JPG/PNG/WEBP; reglas RLS en `storage.objects` con `puede_editar_foto()`: admin cualquier carpeta, comerciante solo la de su negocio; `guardar_mi_foto()` solo acepta URLs de su carpeta). Paquete nuevo `image_picker` (galería o cámara; foto achicada a 1280 px, calidad 75). `FotosService`, `FotoLugar` (muestra la foto o, sin foto o sin internet, el color e ícono de siempre) y `EditorFoto` (elegir, tomar, quitar; borra el archivo viejo). Foto en ficha y tarjeta; editor en "Editar mis datos", en Solicitudes de negocios y en el formulario de Lugares. Permiso de galería en iPhone; motivo de reporte "La foto no corresponde"; Términos v7. 6 pruebas nuevas (**124 en total**) | *Equipo* eligió: guía con audífonos, 1 foto principal, publicación directa (el admin la puede quitar) y fotos también en lugares públicos (deben ser propias o con permiso). Cambia la decisión inicial de "sin fotos". La subida real no se probó contra Supabase (ya no hay cuentas de prueba). **Falta correr SQL 018** |
