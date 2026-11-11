-- =====================================================================
-- VeraGo · 005 · Permisos de tabla (GRANT)
--
-- Qué es GRANT: el permiso para que un ROL pueda usar una tabla.
-- Hay dos "puertas" en PostgreSQL:
--   1. GRANT → ¿este rol puede tocar la tabla?        (este archivo)
--   2. RLS   → ¿qué filas de la tabla puede ver?      (archivo 002)
-- Se necesitan las dos. Los proyectos nuevos de Supabase ya no dan GRANT
-- automático a las tablas creadas por SQL, por eso la app no veía nada.
--
-- Roles de Supabase:
--   anon          → visitante sin sesión (invitado)
--   authenticated → usuario con sesión iniciada
-- =====================================================================

grant usage on schema public to anon, authenticated;

-- Lectura pública (RLS sigue filtrando: solo lugares publicados, etc.)
grant select on public.categorias to anon, authenticated;
grant select on public.lugares    to anon, authenticated;
grant select on public.horarios   to anon, authenticated;
grant select on public.eventos    to anon, authenticated;

-- Solo con sesión (RLS: cada quien ve solo lo suyo)
grant select on public.perfiles to authenticated;
grant select on public.visitas  to authenticated;
grant update (nombre) on public.perfiles to authenticated;

-- codigos_qr: SIN permisos. Solo la usan las funciones del archivo 003.

-- La función es_admin() la usan las reglas RLS, también para invitados.
grant execute on function public.es_admin() to anon, authenticated;
