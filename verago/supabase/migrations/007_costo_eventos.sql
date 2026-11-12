-- =====================================================================
-- VeraGo · 007 · Costo aproximado de los eventos
--
-- Qué hace: agrega la columna costo_aprox_mxn (pesos mexicanos, número
-- entero) a eventos. La Agenda muestra "≈ $150 MXN" si el evento cuesta.
--   - es_gratuito = true            → "Gratuito" (el costo se ignora)
--   - es_gratuito = false + costo   → "≈ $costo MXN"
--   - es_gratuito = false sin costo → "Con costo"
-- La regla CHECK impide guardar precios negativos.
-- No hace falta GRANT nuevo: el permiso de lectura de eventos (005) ya
-- incluye las columnas nuevas.
-- =====================================================================

alter table public.eventos
  add column costo_aprox_mxn integer check (costo_aprox_mxn >= 0);

-- El evento ficticio de pago ("Taller de pintura de recuerdos") recibe un
-- costo FICTICIO de demostración.
update public.eventos
set costo_aprox_mxn = 150
where es_demo and not es_gratuito;
