# VeraGo

App de turismo inteligente para el Centro Histórico de Veracruz.
Hecha con **Flutter + Dart** y **Supabase (PostgreSQL)**.

La documentación completa del proyecto (qué es cada pieza, qué hace y por qué la usamos)
está en el documento compartido del equipo.

## Estado

| Fase | Contenido | Estado |
| --- | --- | --- |
| 1. Fundamentos | Paquetes, tema visual, navegación, SQL (tablas, RLS, funciones, datos demo) | Implementado. **El SQL falta correrlo en Supabase** |
| 2. Turista | Explorar (mapa/lista, búsqueda, filtros), ficha del lugar con "Cerca de aquí", agenda | Implementado. Lógica con pruebas automáticas; falta probar con datos reales |
| 3. Rutas | Formulario (tiempo, intereses, ritmo, inicio), algoritmo voraz, ruta en mapa, "Quitar" parada, sugerencia cercana | Implementado y con pruebas automáticas del algoritmo |
| 4. Pasaporte | Login con correo y contraseña, QR del comerciante (cambia cada 60 s), escaneo con cámara o código escrito, sellos, colección e historial | Implementado. Falta probar con Supabase real |
| 5. Cierre | Estadísticas (DATOS SIMULADOS, solo admin), pruebas, compilación web | Implementado. Falta ensayo de la demo |

Verificado en esta computadora: `flutter analyze` sin problemas, 16 pruebas automáticas pasan
y la app compila para web (`flutter build web`).

## Cómo configurar Supabase (una sola vez)

1. Entrar al proyecto en [supabase.com](https://supabase.com) → **SQL Editor**.
2. Pegar y ejecutar (**Run**), **en este orden**, cada archivo de `supabase/migrations/`:
   1. `001_tablas.sql` — crea las tablas.
   2. `002_rls.sql` — activa las reglas de seguridad.
   3. `003_funciones.sql` — funciones para generar el QR y registrar sellos.
   4. `004_datos_demo.sql` — lugares públicos (coordenadas aproximadas) y comercios/eventos **ficticios**.
   5. `005_permisos.sql` — permisos (GRANT) para que la app pueda leer las tablas. Sin este archivo la app no muestra nada.
   6. `006_perfiles_faltantes.sql` — crea el perfil de cuentas registradas antes del trigger. Se puede correr cuando sea.
3. Revisar en **Table Editor** que existan las tablas y los datos.
4. En **Authentication → Sign In / Providers → Email**:
   - Dejar activado **Email**.
   - Para la demo, desactivar **Confirm email** (así la cuenta funciona al instante).
     Si se deja activado, cada usuario debe abrir el enlace del correo antes de entrar.

### Crear un comerciante de prueba (para mostrar el QR en la demo)

1. Crear una cuenta desde la app (pestaña Pasaporte → Iniciar sesión → crear una).
2. En **Table Editor → perfiles**, cambiar su `rol` a `comerciante`.
3. En **Table Editor → lugares**, en un comercio ficticio (por ejemplo "Café Brisa del Golfo"),
   poner el `id` de ese perfil en `dueno_id`.
4. Para ver las estadísticas simuladas, poner `rol` = `admin` a otra cuenta.

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
├─ screens/        → pantallas (lo que el usuario ve)
├─ services/       → hablan con Supabase o hacen cálculos (rutas, distancias)
├─ models/         → clases de datos (Lugar, Evento, Sello, Perfil)
└─ widgets/        → piezas visuales reutilizables (mapa, tarjetas, etiquetas)
test/              → pruebas automáticas
supabase/migrations/ → SQL de la base de datos
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
