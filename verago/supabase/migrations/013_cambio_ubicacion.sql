-- =====================================================================
-- VeraGo · 013 · Cambio de ubicación con aprobación + arreglos de sellos
--
-- 1. CAMBIO DE UBICACIÓN (decisión del equipo):
--    - El comerciante PIDE el cambio desde su panel:
--        · formal: nuevo punto en el mapa + dirección;
--        · no formal: otro Punto VeraGo donde su giro esté libre.
--    - Mientras el admin no lo acepta, el negocio SIGUE en su ubicación
--      actual. El cambio pendiente se guarda en columnas "cambio_*".
--    - El admin lo ACEPTA (se mueve) o lo RECHAZA (se descarta).
-- 2. La dirección escrita ya no se cambia libremente: va junto con el
--    punto del mapa, así que también pasa por la aprobación.
-- 3. SELLOS: un comerciante ya no puede darse sellos de su propio negocio,
--    y un QR deja de servir en cuanto el negocio deja de dar sellos.
--
-- Todo con funciones protegidas (security definer): la app no puede
-- escribir esas columnas directo (el comerciante no tiene UPDATE en lugares).
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Columnas del cambio pendiente (null = no hay cambio pendiente).
-- ---------------------------------------------------------------------
alter table public.lugares
  add column cambio_latitud       double precision,
  add column cambio_longitud      double precision,
  add column cambio_direccion     text,
  add column cambio_punto_id      uuid references public.lugares (id) on delete set null,
  add column cambio_solicitado_en timestamptz;

-- ---------------------------------------------------------------------
-- 2. solicitar_cambio_ubicacion: la llama el COMERCIANTE.
--    Formal: p_latitud, p_longitud, p_direccion. No formal: p_punto_id.
--    Si ya había un cambio pendiente, lo reemplaza.
-- ---------------------------------------------------------------------
create function public.solicitar_cambio_ubicacion(
  p_latitud   double precision,
  p_longitud  double precision,
  p_direccion text,
  p_punto_id  uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_neg   public.lugares;
  v_punto public.lugares;
begin
  if auth.uid() is null then
    return jsonb_build_object('estado', 'NECESITA_SESION');
  end if;

  select * into v_neg from public.lugares
  where dueno_id = auth.uid() and es_comercio
    and estado_aprobacion in ('pendiente', 'aprobado')
  limit 1;
  if v_neg.id is null then
    return jsonb_build_object('estado', 'SIN_NEGOCIO');
  end if;

  if v_neg.punto_id is null then
    -- FORMAL: nuevo punto del mapa + dirección.
    if p_latitud is null or p_longitud is null or length(trim(coalesce(p_direccion, ''))) < 5 then
      return jsonb_build_object('estado', 'DATOS_INVALIDOS');
    end if;
    update public.lugares
    set cambio_latitud = p_latitud, cambio_longitud = p_longitud,
        cambio_direccion = trim(p_direccion), cambio_punto_id = null,
        cambio_solicitado_en = now()
    where id = v_neg.id;
  else
    -- NO FORMAL: otro Punto VeraGo, con su giro libre ahí.
    select * into v_punto from public.lugares
    where id = p_punto_id and es_punto and publicado;
    if v_punto.id is null then
      return jsonb_build_object('estado', 'PUNTO_INVALIDO');
    end if;
    if v_punto.id = v_neg.punto_id then
      return jsonb_build_object('estado', 'MISMO_PUNTO');
    end if;
    if exists (
      select 1 from public.lugares
      where punto_id = v_punto.id and giro_id = v_neg.giro_id
        and estado_aprobacion in ('pendiente', 'aprobado')
    ) then
      return jsonb_build_object('estado', 'GIRO_OCUPADO');
    end if;
    update public.lugares
    set cambio_latitud = v_punto.latitud, cambio_longitud = v_punto.longitud,
        cambio_direccion = v_punto.nombre, cambio_punto_id = v_punto.id,
        cambio_solicitado_en = now()
    where id = v_neg.id;
  end if;

  return jsonb_build_object('estado', 'OK');
end;
$$;

-- ---------------------------------------------------------------------
-- 3. cancelar_cambio_ubicacion: el COMERCIANTE retira su solicitud.
-- ---------------------------------------------------------------------
create function public.cancelar_cambio_ubicacion()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    return jsonb_build_object('estado', 'NECESITA_SESION');
  end if;
  update public.lugares
  set cambio_latitud = null, cambio_longitud = null, cambio_direccion = null,
      cambio_punto_id = null, cambio_solicitado_en = null
  where dueno_id = auth.uid() and es_comercio;
  return jsonb_build_object('estado', 'OK');
end;
$$;

-- ---------------------------------------------------------------------
-- 4. resolver_cambio_ubicacion: el ADMIN acepta (true) o rechaza (false).
--    Al aceptar un cambio de Punto VeraGo, el negocio toma el horario del
--    punto nuevo (el admin lo puede ajustar después).
-- ---------------------------------------------------------------------
create function public.resolver_cambio_ubicacion(p_lugar uuid, p_aceptar boolean)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_neg public.lugares;
begin
  if not public.es_admin() then
    return jsonb_build_object('estado', 'NO_AUTORIZADO');
  end if;

  select * into v_neg from public.lugares where id = p_lugar;
  if v_neg.id is null or v_neg.cambio_solicitado_en is null then
    return jsonb_build_object('estado', 'SIN_CAMBIO');
  end if;

  if p_aceptar then
    begin
      update public.lugares
      set latitud   = v_neg.cambio_latitud,
          longitud  = v_neg.cambio_longitud,
          direccion = v_neg.cambio_direccion,
          punto_id  = coalesce(v_neg.cambio_punto_id, v_neg.punto_id)
      where id = v_neg.id;
    exception when unique_violation then
      -- Otro negocio tomó ese giro en el punto mientras tanto.
      return jsonb_build_object('estado', 'GIRO_OCUPADO');
    end;

    if v_neg.cambio_punto_id is not null then
      delete from public.horarios where lugar_id = v_neg.id;
      insert into public.horarios (lugar_id, dia_semana, abre, cierra)
      select v_neg.id, dia_semana, abre, cierra
      from public.horarios where lugar_id = v_neg.cambio_punto_id;
    end if;
  end if;

  update public.lugares
  set cambio_latitud = null, cambio_longitud = null, cambio_direccion = null,
      cambio_punto_id = null, cambio_solicitado_en = null
  where id = v_neg.id;

  return jsonb_build_object('estado', 'OK');
end;
$$;

-- ---------------------------------------------------------------------
-- 5. actualizar_mi_negocio: ya NO cambia la dirección (ahora va con la
--    solicitud de cambio de ubicación). Se deja el parámetro p_direccion
--    para no romper versiones viejas de la app, pero se ignora.
-- ---------------------------------------------------------------------
create or replace function public.actualizar_mi_negocio(
  p_descripcion text,
  p_telefono    text,
  p_direccion   text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    return jsonb_build_object('estado', 'NECESITA_SESION');
  end if;

  update public.lugares
  set descripcion = nullif(trim(p_descripcion), ''),
      telefono    = nullif(trim(p_telefono), '')
  where dueno_id = auth.uid() and es_comercio
    and estado_aprobacion in ('pendiente', 'aprobado');

  if not found then
    return jsonb_build_object('estado', 'SIN_NEGOCIO');
  end if;
  return jsonb_build_object('estado', 'OK');
end;
$$;

-- ---------------------------------------------------------------------
-- 6. registrar_visita (versión nueva):
--    - El código solo sirve si el negocio SIGUE dando sellos.
--    - El dueño no puede darse un sello de su propio negocio.
-- ---------------------------------------------------------------------
create or replace function public.registrar_visita(p_codigo text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_lugar  uuid;
  v_nombre text;
  v_dueno  uuid;
  v_hoy    date := (now() at time zone 'America/Mexico_City')::date;
  v_total  int;
begin
  if auth.uid() is null then
    return jsonb_build_object('estado', 'NECESITA_SESION');
  end if;

  select q.lugar_id, l.nombre, l.dueno_id into v_lugar, v_nombre, v_dueno
  from public.codigos_qr q
  join public.lugares l on l.id = q.lugar_id
  where q.codigo = p_codigo and q.vence_en > now()
    and l.participa_pasaporte;

  if v_lugar is null then
    return jsonb_build_object('estado', 'CODIGO_INVALIDO');
  end if;

  if v_dueno = auth.uid() then
    return jsonb_build_object('estado', 'ES_TU_NEGOCIO', 'lugar_nombre', v_nombre);
  end if;

  insert into public.visitas (usuario_id, lugar_id, fecha)
  values (auth.uid(), v_lugar, v_hoy)
  on conflict (usuario_id, lugar_id, fecha) do nothing;

  if not found then
    return jsonb_build_object('estado', 'YA_TIENE_SELLO_HOY',
                              'lugar_id', v_lugar, 'lugar_nombre', v_nombre);
  end if;

  select count(distinct lugar_id) into v_total
  from public.visitas where usuario_id = auth.uid();

  return jsonb_build_object('estado', 'OK', 'lugar_id', v_lugar,
                            'lugar_nombre', v_nombre, 'total_sellos', v_total);
end;
$$;

-- Solo usuarios con sesión pueden llamar las funciones nuevas.
revoke execute on function public.solicitar_cambio_ubicacion(double precision, double precision, text, uuid) from public, anon;
revoke execute on function public.cancelar_cambio_ubicacion() from public, anon;
revoke execute on function public.resolver_cambio_ubicacion(uuid, boolean) from public, anon;
grant execute on function public.solicitar_cambio_ubicacion(double precision, double precision, text, uuid) to authenticated;
grant execute on function public.cancelar_cambio_ubicacion() to authenticated;
grant execute on function public.resolver_cambio_ubicacion(uuid, boolean) to authenticated;
