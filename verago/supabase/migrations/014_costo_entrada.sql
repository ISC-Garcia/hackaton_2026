-- =====================================================================
-- VeraGo · 014 · Costo de entrada de un lugar
--
-- Decisión del equipo:
--   - El NEGOCIO FORMAL pone su propio costo de entrada (ej. una galería)
--     y se publica directo, sin aprobación (como la descripción).
--   - El ADMIN puede ponerlo o corregirlo en cualquier lugar, también en los
--     lugares públicos (solo si el precio está confirmado: no inventamos).
--   - Los negocios no formales y los Puntos VeraGo no cobran entrada.
--
-- Cómo se guarda (una sola columna, en pesos mexicanos):
--   null  → sin dato (público: "no disponible"; negocio: "no cobra entrada")
--   0     → entrada gratis
--   > 0   → entrada aproximada en pesos
-- =====================================================================

alter table public.lugares
  add column costo_entrada_mxn integer
    check (costo_entrada_mxn between 0 and 100000);

-- Regla: ni los no formales ni los Puntos VeraGo llevan costo de entrada.
alter table public.lugares
  add constraint costo_entrada_solo_lugares
  check (costo_entrada_mxn is null or (punto_id is null and not es_punto));

-- ---------------------------------------------------------------------
-- guardar_mi_costo_entrada: la llama el COMERCIANTE FORMAL.
-- p_costo null = no cobro entrada. (El admin escribe directo en la tabla,
-- con el permiso del archivo 011.)
-- ---------------------------------------------------------------------
create function public.guardar_mi_costo_entrada(p_costo integer)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    return jsonb_build_object('estado', 'NECESITA_SESION');
  end if;
  if p_costo is not null and (p_costo < 0 or p_costo > 100000) then
    return jsonb_build_object('estado', 'COSTO_INVALIDO');
  end if;

  update public.lugares
  set costo_entrada_mxn = p_costo
  where dueno_id = auth.uid() and es_comercio and punto_id is null
    and estado_aprobacion in ('pendiente', 'aprobado');

  if not found then
    return jsonb_build_object('estado', 'SIN_NEGOCIO_FORMAL');
  end if;
  return jsonb_build_object('estado', 'OK');
end;
$$;

revoke execute on function public.guardar_mi_costo_entrada(integer) from public, anon;
grant execute on function public.guardar_mi_costo_entrada(integer) to authenticated;
