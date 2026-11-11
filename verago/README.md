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
