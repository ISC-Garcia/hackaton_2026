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
| `geolocator` | GPS, solo si el usuario elige "Mi ubicación" en Rutas |
| `mobile_scanner` / `qr_flutter` | Leer y dibujar códigos QR |
| `shared_preferences` | Guardar en el celular: bienvenida vista, intereses y tiempo de la ruta |

## Estado

| Fase | Contenido | Estado |
| --- | --- | --- |
| 1. Fundamentos | Paquetes, tema visual, navegación, SQL (tablas, RLS, funciones, datos demo, permisos) | Implementado; SQL corrido en Supabase |
| 2. Turista | Explorar (mapa/lista, búsqueda, filtros, leyenda, centrar), ficha del lugar con "Cerca de aquí", agenda | Implementado y probado en celular |
| 3. Rutas | Formulario (tiempo, intereses, ritmo, inicio), algoritmo voraz, ruta en mapa, "Quitar" parada, sugerencia cercana | Implementado, con pruebas automáticas del algoritmo |
| 4. Pasaporte | Login con correo y contraseña (con confirmar contraseña), QR del comerciante (cambia cada 60 s), escaneo con cámara o código escrito, animación del sello, colección e historial | Implementado |
| 5. Cierre | Estadísticas (DATOS SIMULADOS, solo admin), pruebas, compilación web | Implementado. Falta ensayo de la demo |
| Extra UI/UX | Pantalla de bienvenida (primera vez), botón de ojo en contraseñas, leyenda y centrar en el mapa | Implementado, con pruebas automáticas |
| Ajustes | Engrane en el Pasaporte: mi cuenta (correo, rol, cambiar nombre), mis intereses, ver bienvenida otra vez, privacidad y cerrar sesión | Implementado, con pruebas automáticas |
| Comerciantes | "Soy un negocio" (bienvenida y Ajustes): registro de negocio formal (local en mapa) o informal (giro en un **Punto VeraGo**), inicio de sesión, estado de la solicitud y panel (QR, ficha, editar datos). Rutas con al menos 1 comercio formal y 1 Punto VeraGo | Implementado, con pruebas automáticas. **Falta correr SQL 008 y 009** y probar con Supabase |

Verificado en esta computadora: `flutter analyze` sin problemas, **33 pruebas automáticas** pasan
y la app compila para web (`flutter build web`).

### Qué NO hace la app (a propósito, MVP)

- No hay premios ni canjes: el pasaporte **solo junta sellos**.
- Eventos, lugares y roles se administran desde el **panel de Supabase**, no desde la app.
  Los comerciantes **se registran** desde la app, pero el admin **aprueba** en Supabase.
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

Las solicitudes nuevas quedan con `estado_aprobacion = 'pendiente'` y **no** se ven en la app.
Para verlas: Table Editor → `lugares` → filtrar `estado_aprobacion` = `pendiente`.

```sql
-- APROBAR (después de que el comerciante pagó su espacio): aparece en la app y da sellos.
update public.lugares
set estado_aprobacion = 'aprobado', publicado = true, participa_pasaporte = true
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

### Crear un evento (quién agenda)

Solo el administrador agenda eventos, desde Supabase: Table Editor → `eventos` → **Insert row**.
Llenar `titulo`, `lugar_id` (id del lugar), `inicia`, `termina` y `estado`:

- `publicado` → se ve en la app.
- `pendiente` → oculto (borrador).
- `cancelado` → se ve tachado para avisar.

Marcar `es_demo = true` si el evento es ficticio.

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

## Estructura

```text
lib/
├─ main.dart       → arranque: conecta con Supabase y abre la app
├─ config.dart     → lee las claves de env.json
├─ theme/          → colores y letras de VeraGo
├─ screens/        → pantallas (bienvenida, principal, explorar, lugar, rutas, ruta,
│                    agenda, pasaporte, ajustes, login, escanear, qr_comercio, estadisticas,
│                    negocio, negocio_registrado, estado_negocio, panel_comerciante, editar_negocio)
├─ services/       → hablan con Supabase o hacen cálculos (rutas, distancias)
├─ models/         → clases de datos (Lugar, Evento, Sello, Perfil)
└─ widgets/        → piezas visuales reutilizables (mapa, tarjetas, etiquetas)
test/              → pruebas automáticas (33)
supabase/migrations/ → SQL de la base de datos (001 a 009)
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
