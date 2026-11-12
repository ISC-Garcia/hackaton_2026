-- =====================================================================
-- VeraGo · 011 · Panel de administración en la app
--
-- Por qué: solo los desarrolladores entran a Supabase. El admin de VeraGo
-- aprueba negocios y administra lugares y Puntos VeraGo desde la app.
--
-- Cómo queda protegido (igual que la Agenda, archivo 010):
--   1. GRANT (este archivo): "authenticated" PUEDE intentar escribir.
--   2. RLS (archivo 002): reglas "admin administra lugares" y
--      "admin administra horarios" → solo el rol admin lo logra.
-- No se da permiso de BORRAR lugares: tienen sellos y eventos ligados.
-- Para quitar uno de la app se "oculta" (publicado = false).
-- =====================================================================

grant insert, update on public.lugares to authenticated;
grant insert, update, delete on public.horarios to authenticated;
