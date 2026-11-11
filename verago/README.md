# VeraGo

App de turismo inteligente para el Centro Histórico de Veracruz.
Hecha con **Flutter + Dart** y **Supabase (PostgreSQL)**.

La documentación completa del proyecto (qué es cada pieza, qué hace y por qué la usamos)
está en el documento compartido del equipo.

## Estado

| Fase | Contenido | Estado |
| --- | --- | --- |
| 1. Fundamentos | Paquetes, tema visual, navegación, SQL (tablas, RLS, funciones, datos demo) | Implementado; la navegación tiene prueba automática. El SQL falta correrlo en Supabase |
| 2. Turista | Explorar (mapa/lista, búsqueda, filtros), ficha del lugar con "Cerca de aquí", agenda | Implementado; lógica con pruebas automáticas. Falta probar con datos reales (correr el SQL) |
| 3. Rutas | Generador de rutas | Pendiente |
| 4. Pasaporte | Login, QR, sellos | Pendiente |
| 5. Cierre | Estadísticas simuladas, pruebas, ensayo | Pendiente |

## Cómo configurar Supabase (una sola vez)

1. Entrar al proyecto en [supabase.com](https://supabase.com) → **SQL Editor**.
2. Pegar y ejecutar (**Run**), **en este orden**, cada archivo de `supabase/migrations/`:
   1. `001_tablas.sql` — crea las tablas.
   2. `002_rls.sql` — activa las reglas de seguridad.
   3. `003_funciones.sql` — funciones para generar el QR y registrar sellos.
   4. `004_datos_demo.sql` — lugares públicos (coordenadas aproximadas) y comercios/eventos **ficticios**.
3. Revisar en **Table Editor** que existan las tablas y los datos.
4. En **Authentication → Sign In / Providers**, dejar activado **Email**.

### Crear un comerciante de prueba (para mostrar el QR en la demo)

1. Registrarse en la app con un correo (o crear el usuario en **Authentication → Users**).
2. En **Table Editor → perfiles**, cambiar su `rol` a `comerciante`.
3. En **Table Editor → lugares**, en un comercio ficticio (por ejemplo "Café Brisa del Golfo"),
   poner su id en `dueno_id`.

## Cómo ejecutar la app

1. Copiar `env.example.json` como `env.json` y llenar:
   - `SUPABASE_URL`: Supabase → Project Settings → API → Project URL.
   - `SUPABASE_KEY`: la **publishable key** (pública).
   - **Nunca** poner la clave secreta (`service_role` / `secret`).
2. Ejecutar:

```bash
flutter pub get
flutter run --dart-define-from-file=env.json
```

`env.json` está en `.gitignore`: no se sube a GitHub.

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
├─ screens/        → pantallas
├─ services/       → hablan con Supabase o hacen cálculos (Fase 2+)
├─ models/         → clases de datos (Fase 2+)
└─ widgets/        → piezas visuales reutilizables
supabase/migrations/ → SQL de la base de datos
```
