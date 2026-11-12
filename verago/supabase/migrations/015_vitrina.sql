-- =====================================================================
-- VeraGo · 015 · Vitrina digital: productos, servicios y promoción
--
-- Decisión del equipo: cada negocio (formal o no formal) puede mostrar en
-- su ficha una lista de productos o servicios (nombre y precio aproximado)
-- y una promoción vigente. Solo texto: sin fotos (decisión de MVP).
--
-- Cómo se guarda:
--   vitrina_productos → lista JSON: [{"nombre":"Café lechero","precio":45}, …]
--                       (máximo 20; precio en pesos, puede ir vacío)
--   promocion         → texto corto (máximo 140 letras) o vacío.
--
-- Qué es jsonb: un tipo de PostgreSQL que guarda JSON (listas y objetos)
-- dentro de una columna. Aquí evita crear otra tabla solo para productos.
-- =====================================================================

alter table public.lugares
  add column vitrina_productos jsonb not null default '[]'::jsonb
    check (jsonb_typeof(vitrina_productos) = 'array' and jsonb_array_length(vitrina_productos) <= 20),
  add column promocion text
    check (promocion is null or char_length(promocion) between 3 and 140);

-- ---------------------------------------------------------------------
-- guardar_mi_vitrina: la llama el COMERCIANTE para su propio negocio.
-- Revisa cada producto y guarda una lista "limpia".
-- ---------------------------------------------------------------------
create function public.guardar_mi_vitrina(p_productos jsonb, p_promocion text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_lista  jsonb := '[]'::jsonb;
  v_item   jsonb;
  v_nombre text;
  v_precio int;
  v_promo  text := nullif(trim(coalesce(p_promocion, '')), '');
begin
  if auth.uid() is null then
    return jsonb_build_object('estado', 'NECESITA_SESION');
  end if;
  if p_productos is null or jsonb_typeof(p_productos) <> 'array'
     or jsonb_array_length(p_productos) > 20 then
    return jsonb_build_object('estado', 'DATOS_INVALIDOS');
  end if;
  if v_promo is not null and char_length(v_promo) not between 3 and 140 then
    return jsonb_build_object('estado', 'DATOS_INVALIDOS');
  end if;

  for v_item in select * from jsonb_array_elements(p_productos) loop
    v_nombre := trim(coalesce(v_item ->> 'nombre', ''));
    if char_length(v_nombre) not between 2 and 60 then
      return jsonb_build_object('estado', 'DATOS_INVALIDOS');
    end if;
    begin
      v_precio := nullif(v_item ->> 'precio', '')::int;
    exception when others then
      return jsonb_build_object('estado', 'DATOS_INVALIDOS');
    end;
    if v_precio is not null and (v_precio < 0 or v_precio > 100000) then
      return jsonb_build_object('estado', 'DATOS_INVALIDOS');
    end if;
    v_lista := v_lista || jsonb_build_array(jsonb_build_object('nombre', v_nombre, 'precio', v_precio));
  end loop;

  update public.lugares
  set vitrina_productos = v_lista, promocion = v_promo
  where dueno_id = auth.uid() and es_comercio
    and estado_aprobacion in ('pendiente', 'aprobado');

  if not found then
    return jsonb_build_object('estado', 'SIN_NEGOCIO');
  end if;
  return jsonb_build_object('estado', 'OK');
end;
$$;

revoke execute on function public.guardar_mi_vitrina(jsonb, text) from public, anon;
grant execute on function public.guardar_mi_vitrina(jsonb, text) to authenticated;
