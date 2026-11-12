-- =====================================================================
-- VeraGo · 012 · Solo los negocios FORMALES dan sellos
--
-- Regla del equipo: el pasaporte solo junta sellos de comercios formales
-- (local propio). Los negocios no formales de un Punto VeraGo, los
-- Puntos y los lugares públicos NO dan sello.
--
-- Qué hace:
--   1. Les quita el sello a los negocios no formales que ya existen.
--   2. Agrega una regla (CHECK) para que la base de datos NUNCA acepte
--      un lugar no formal que dé sello, aunque la app se equivoque.
--
-- Qué es un CHECK: una condición que cada fila de la tabla debe cumplir;
-- si un cambio la rompe, PostgreSQL lo rechaza.
-- Formal = es_comercio y sin punto_id (no está dentro de un Punto VeraGo).
--
-- Las funciones del QR (archivo 003) ya revisan participa_pasaporte, así
-- que con esto un negocio no formal ya no puede generar QR ni dar sellos.
-- Los sellos que ya se habían dado se quedan en el historial.
-- =====================================================================

update public.lugares
set participa_pasaporte = false
where participa_pasaporte
  and not (es_comercio and punto_id is null);

alter table public.lugares
  add constraint sello_solo_formales
  check (not participa_pasaporte or (es_comercio and punto_id is null));
