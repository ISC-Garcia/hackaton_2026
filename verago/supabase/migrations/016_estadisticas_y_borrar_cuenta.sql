-- =====================================================================
-- VeraGo · 016 · Estadísticas reales + "Borrar mi cuenta"
--
-- 1. ESTADÍSTICAS: antes la pantalla usaba números inventados. Ahora dos
--    funciones cuentan los datos reales y devuelven SOLO TOTALES (nunca
--    nombres ni correos de turistas):
--      - estadisticas_admin()       → toda la app (solo admin).
--      - estadisticas_mi_negocio()  → los sellos que dio MI negocio.
-- 2. BORRAR MI CUENTA (derecho ARCO de cancelación): la persona borra su
--    cuenta desde Ajustes. Se borran su perfil y sus sellos (en cascada).
--    Si tenía negocio: pendiente o rechazado → se borra; aprobado o
--    suspendido → se oculta (suspendido), para no borrar los sellos que ya
--    ganaron los turistas. Un admin no se borra desde la app.
--
-- "security definer": se ejecutan con permisos de la base de datos, por
-- eso pueden contar todas las visitas o borrar en auth.users; pero cada una
-- revisa primero quién la llama (auth.uid(), es_admin()).
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1a. Estadísticas de toda la app (solo admin).
-- ---------------------------------------------------------------------
create function public.estadisticas_admin()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_hoy date := (now() at time zone 'America/Mexico_City')::date;
begin
  if not public.es_admin() then
    return jsonb_build_object('estado', 'NO_AUTORIZADO');
  end if;

  return jsonb_build_object(
    'estado', 'OK',
    'usuarios', (select count(*) from public.perfiles),
    'turistas_con_sellos', (select count(distinct usuario_id) from public.visitas),
    'sellos_total', (select count(*) from public.visitas),
    'sellos_7_dias', (select count(*) from public.visitas where fecha > v_hoy - 7),
    'negocios_aprobados', (select count(*) from public.lugares where es_comercio and estado_aprobacion = 'aprobado'),
    'negocios_pendientes', (select count(*) from public.lugares where es_comercio and estado_aprobacion = 'pendiente'),
    'eventos_proximos', (select count(*) from public.eventos where termina >= now() and estado = 'publicado'),
    -- Sellos de cada uno de los últimos 14 días (los días sin sellos, en 0).
    'por_dia', (
      select coalesce(jsonb_agg(jsonb_build_object('fecha', g.dia::date, 'total', coalesce(v.n, 0)) order by g.dia), '[]'::jsonb)
      from generate_series((v_hoy - 13)::timestamp, v_hoy::timestamp, interval '1 day') as g(dia)
      left join (select fecha, count(*) as n from public.visitas group by fecha) v on v.fecha = g.dia::date
    ),
    -- Los 5 negocios con más sellos.
    'top_negocios', (
      select coalesce(jsonb_agg(jsonb_build_object('nombre', t.nombre, 'total', t.n) order by t.n desc), '[]'::jsonb)
      from (
        select l.nombre, count(*) as n
        from public.visitas v join public.lugares l on l.id = v.lugar_id
        group by l.nombre
        order by n desc
        limit 5
      ) t
    )
  );
end;
$$;

-- ---------------------------------------------------------------------
-- 1b. Estadísticas de MI negocio (el comerciante dueño).
-- ---------------------------------------------------------------------
create function public.estadisticas_mi_negocio()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_hoy    date := (now() at time zone 'America/Mexico_City')::date;
  v_lugar  uuid;
  v_nombre text;
  v_sellos boolean;
begin
  if auth.uid() is null then
    return jsonb_build_object('estado', 'NECESITA_SESION');
  end if;

  select id, nombre, participa_pasaporte into v_lugar, v_nombre, v_sellos
  from public.lugares
  where dueno_id = auth.uid() and es_comercio
  order by creado_en desc
  limit 1;
  if v_lugar is null then
    return jsonb_build_object('estado', 'SIN_NEGOCIO');
  end if;

  return jsonb_build_object(
    'estado', 'OK',
    'nombre', v_nombre,
    'da_sellos', v_sellos,
    'sellos_total', (select count(*) from public.visitas where lugar_id = v_lugar),
    'sellos_7_dias', (select count(*) from public.visitas where lugar_id = v_lugar and fecha > v_hoy - 7),
    'sellos_hoy', (select count(*) from public.visitas where lugar_id = v_lugar and fecha = v_hoy),
    'visitantes', (select count(distinct usuario_id) from public.visitas where lugar_id = v_lugar),
    'por_dia', (
      select coalesce(jsonb_agg(jsonb_build_object('fecha', g.dia::date, 'total', coalesce(v.n, 0)) order by g.dia), '[]'::jsonb)
      from generate_series((v_hoy - 13)::timestamp, v_hoy::timestamp, interval '1 day') as g(dia)
      left join (
        select fecha, count(*) as n from public.visitas where lugar_id = v_lugar group by fecha
      ) v on v.fecha = g.dia::date
    )
  );
end;
$$;

-- ---------------------------------------------------------------------
-- 2. Borrar mi cuenta.
-- ---------------------------------------------------------------------
create function public.borrar_mi_cuenta()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    return jsonb_build_object('estado', 'NECESITA_SESION');
  end if;
  -- Para no quedarse sin administradores por accidente.
  if public.es_admin() then
    return jsonb_build_object('estado', 'ES_ADMIN');
  end if;

  -- Negocio que nunca se publicó: se borra.
  delete from public.lugares
  where dueno_id = v_uid and es_comercio and estado_aprobacion in ('pendiente', 'rechazado');

  -- Negocio publicado alguna vez: se oculta (los turistas conservan sus sellos).
  update public.lugares
  set estado_aprobacion = 'suspendido', publicado = false, participa_pasaporte = false
  where dueno_id = v_uid and es_comercio;

  -- La cuenta. En cascada se borran su perfil y sus sellos (archivo 001).
  delete from auth.users where id = v_uid;

  return jsonb_build_object('estado', 'OK');
end;
$$;

revoke execute on function public.estadisticas_admin() from public, anon;
revoke execute on function public.estadisticas_mi_negocio() from public, anon;
revoke execute on function public.borrar_mi_cuenta() from public, anon;
grant execute on function public.estadisticas_admin() to authenticated;
grant execute on function public.estadisticas_mi_negocio() to authenticated;
grant execute on function public.borrar_mi_cuenta() to authenticated;
