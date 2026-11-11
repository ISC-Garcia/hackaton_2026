-- =====================================================================
-- VeraGo · 006 · Crear perfiles faltantes
--
-- Qué hace: crea la fila en "perfiles" para las cuentas que se
-- registraron ANTES de que existiera el trigger crear_perfil (archivo 001).
-- "on conflict do nothing" = si ya tiene perfil, no lo toca.
-- Se puede correr las veces que sea sin riesgo.
-- =====================================================================

insert into public.perfiles (id, nombre)
select id, split_part(email, '@', 1)
from auth.users
on conflict (id) do nothing;
