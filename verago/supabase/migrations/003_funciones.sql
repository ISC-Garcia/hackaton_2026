-- =====================================================================
-- VeraGo · 003 · Funciones protegidas
-- Qué es: pequeños programas guardados dentro de la base de datos.
-- La app los llama por su nombre: supabase.rpc('registrar_visita', ...).
-- Por qué: la app podría ser modificada por alguien; la base de datos no.
-- Aquí se revisan todas las reglas antes de crear un QR o un sello.
--
-- "security definer": la función se ejecuta con permisos de la base de
-- datos (por eso puede escribir en visitas y codigos_qr, que la app no
-- puede tocar directo). "set search_path = ''" es una protección
-- recomendada por Supabase para este tipo de funciones.
-- =====================================================================

-- ---------------------------------------------------------------------
-- generar_codigo_qr: la llama el celular del COMERCIANTE cada minuto.
-- Devuelve un código nuevo que vence en 60 segundos.
-- ---------------------------------------------------------------------
create function public.generar_codigo_qr(p_lugar uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_codigo text;
  v_vence  timestamptz;
begin
  -- 1. Debe haber sesión iniciada.
  if auth.uid() is null then
    return jsonb_build_object('estado', 'NECESITA_SESION');
  end if;

  -- 2. Solo el dueño del comercio (o un admin) puede generar su QR,
  --    y el lugar debe participar en el pasaporte.
  if not exists (
    select 1 from public.lugares
    where id = p_lugar
      and participa_pasaporte
      and (dueno_id = auth.uid() or public.es_admin())
  ) then
    return jsonb_build_object('estado', 'NO_AUTORIZADO');
  end if;

  -- 3. Limpiar códigos viejos para que la tabla no crezca sin fin.
  delete from public.codigos_qr where vence_en < now();

  -- 4. Crear un código aleatorio imposible de adivinar.
  v_codigo := 'VG-' || replace(gen_random_uuid()::text, '-', '');
  v_vence  := now() + interval '60 seconds';

  insert into public.codigos_qr (codigo, lugar_id, vence_en)
  values (v_codigo, p_lugar, v_vence);

  return jsonb_build_object('estado', 'OK', 'codigo', v_codigo, 'vence_en', v_vence);
end;
$$;

-- ---------------------------------------------------------------------
-- registrar_visita: la llama el celular del VISITANTE al escanear el QR.
-- Si todo está bien, crea un sello en "visitas".
-- ---------------------------------------------------------------------
create function public.registrar_visita(p_codigo text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_lugar  uuid;
  v_nombre text;
  v_hoy    date := (now() at time zone 'America/Mexico_City')::date;
  v_total  int;
begin
  -- 1. ¿Hay sesión iniciada? Así nadie da sellos a nombre de otro.
  if auth.uid() is null then
    return jsonb_build_object('estado', 'NECESITA_SESION');
  end if;

  -- 2. ¿El código existe y no ha vencido?
  select q.lugar_id, l.nombre into v_lugar, v_nombre
  from public.codigos_qr q
  join public.lugares l on l.id = q.lugar_id
  where q.codigo = p_codigo and q.vence_en > now();

  if v_lugar is null then
    return jsonb_build_object('estado', 'CODIGO_INVALIDO');
  end if;

  -- 3. Registrar el sello. Si ya tiene uno de este lugar hoy,
  --    la regla UNIQUE de la tabla lo impide y no se inserta nada.
  insert into public.visitas (usuario_id, lugar_id, fecha)
  values (auth.uid(), v_lugar, v_hoy)
  on conflict (usuario_id, lugar_id, fecha) do nothing;

  if not found then
    return jsonb_build_object('estado', 'YA_TIENE_SELLO_HOY',
                              'lugar_id', v_lugar, 'lugar_nombre', v_nombre);
  end if;

  -- 4. Contar cuántos lugares distintos lleva en su pasaporte.
  select count(distinct lugar_id) into v_total
  from public.visitas where usuario_id = auth.uid();

  return jsonb_build_object('estado', 'OK', 'lugar_id', v_lugar,
                            'lugar_nombre', v_nombre, 'total_sellos', v_total);
end;
$$;

-- Solo usuarios con sesión pueden llamar estas funciones.
revoke execute on function public.generar_codigo_qr(uuid) from public, anon;
revoke execute on function public.registrar_visita(text) from public, anon;
grant execute on function public.generar_codigo_qr(uuid) to authenticated;
grant execute on function public.registrar_visita(text) to authenticated;
