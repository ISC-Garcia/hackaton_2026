-- =====================================================================
-- VeraGo · 020 · La Agenda no acepta eventos duplicados
--
-- Decisión del equipo: no puede haber dos eventos con el MISMO NOMBRE, a la
-- MISMA HORA de inicio y en el MISMO LUGAR (información duplicada).
--
-- Cómo: un ÍNDICE ÚNICO. Es una regla de PostgreSQL que rechaza guardar una
-- fila si ya existe otra con los mismos valores en esas columnas, aunque la
-- app se equivoque o dos admins guarden al mismo tiempo.
--
-- Detalles:
--   - El nombre se compara sin importar mayúsculas ni espacios de más
--     ("Danzón  en el Zócalo" = "danzón en el zócalo").
--   - Los CANCELADOS no cuentan: se puede volver a crear un evento que se
--     canceló.
--   - Un evento sin lugar se compara con otros sin lugar.
-- =====================================================================

-- 1. Antes de crear la regla, quitar los duplicados que YA existen (si no,
--    PostgreSQL no deja crearla). De cada grupo repetido se queda UNO
--    (de preferencia el publicado) y se borran las copias.
with repetidos as (
  select id,
         row_number() over (
           partition by lower(trim(regexp_replace(titulo, '\s+', ' ', 'g'))),
                        coalesce(lugar_id, '00000000-0000-0000-0000-000000000000'::uuid),
                        inicia
           order by (estado = 'publicado') desc, id
         ) as n
  from public.eventos
  where estado <> 'cancelado'
)
delete from public.eventos where id in (select id from repetidos where n > 1);

-- 2. La regla.
create unique index evento_sin_duplicados
  on public.eventos (
    lower(trim(regexp_replace(titulo, '\s+', ' ', 'g'))),
    coalesce(lugar_id, '00000000-0000-0000-0000-000000000000'::uuid),
    inicia
  )
  where estado <> 'cancelado';
