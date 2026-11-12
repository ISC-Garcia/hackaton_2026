-- =====================================================================
-- VeraGo · 010 · El admin administra la Agenda desde la app
--
-- Por qué: solo los desarrolladores entran a Supabase. El administrador
-- de VeraGo (rol "admin") crea, edita, cancela y borra eventos desde la app.
--
-- Cómo queda protegido:
--   1. GRANT (este archivo): el rol "authenticated" PUEDE intentar escribir
--      en eventos.
--   2. RLS (archivo 002, regla "admin administra eventos"): la base de
--      datos solo lo PERMITE si quien escribe tiene rol admin
--      (función es_admin()). Un usuario normal recibe un error aunque
--      modifique la app.
-- =====================================================================

grant insert, update, delete on public.eventos to authenticated;

-- Quién creó el evento se llena solo con el id del usuario con sesión.
alter table public.eventos alter column creado_por set default auth.uid();
