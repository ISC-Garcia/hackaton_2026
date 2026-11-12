-- =====================================================================
-- VeraGo · 017 · Limpieza de las cuentas de prueba
--
-- Borra SOLO las 4 cuentas que la IA creó para probar la app contra
-- Supabase (dominio inventado verago-demo.mx) y el negocio ficticio
-- "Negocio de Prueba VeraGo". No toca ninguna cuenta ni negocio del equipo.
--
-- En cascada (archivo 001) se borran también sus perfiles y sus sellos.
-- Se puede correr más de una vez: si ya no existen, no hace nada.
-- =====================================================================

-- El negocio de prueba (primero, porque al borrar la cuenta quedaría sin dueño).
delete from public.lugares
where nombre = 'Negocio de Prueba VeraGo'
  and dueno_id in (select id from auth.users where email = 'comercio.prueba@verago-demo.mx');

-- Las 4 cuentas de prueba.
delete from auth.users
where email in (
  'prueba.verago@verago-demo.mx',
  'turista.prueba@verago-demo.mx',
  'comercio.prueba@verago-demo.mx',
  'admin.prueba@verago-demo.mx'
);
