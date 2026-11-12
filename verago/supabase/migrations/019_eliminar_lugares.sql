-- =====================================================================
-- VeraGo · 019 · Eliminar lugares, Puntos VeraGo y negocios desde la app
--
-- Decisión del equipo:
--   - El ADMIN puede eliminar cualquier lugar, Punto VeraGo o negocio.
--   - El COMERCIANTE puede eliminar SU negocio (su cuenta sigue).
--   - Reglas para no romper nada:
--       · Si el lugar YA TIENE SELLOS de turistas, NO se elimina (se
--         borrarían sus sellos y bajarían de insignia): la app ofrece
--         ocultarlo.
--       · Un Punto VeraGo con negocios dentro NO se elimina hasta vaciarlo
--         (si no, esos negocios quedarían "sin punto").
--   - Al eliminar se borran en cascada su horario y sus códigos QR
--     (archivo 001). Los eventos de ese lugar se quedan, sin lugar.
--
-- Dos pasos (por eso p_confirmar):
--   1. p_confirmar = false → solo REVISA y dice si se puede (y cuántos
--      eventos quedarían sin lugar). La app borra la foto en este momento,
--      mientras todavía tiene permiso sobre la carpeta.
--   2. p_confirmar = true  → elimina.
-- =====================================================================

create function public.eliminar_lugar(p_lugar uuid, p_confirmar boolean)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_lugar    public.lugares;
  v_admin    boolean := public.es_admin();
  v_sellos   int;
  v_negocios int;
  v_eventos  int;
begin
  if auth.uid() is null then
    return jsonb_build_object('estado', 'NECESITA_SESION');
  end if;

  select * into v_lugar from public.lugares where id = p_lugar;
  if v_lugar.id is null then
    return jsonb_build_object('estado', 'NO_EXISTE');
  end if;

  -- Admin: cualquiera. Comerciante: solo su propio negocio.
  if not (v_admin or (v_lugar.es_comercio and v_lugar.dueno_id = auth.uid())) then
    return jsonb_build_object('estado', 'NO_AUTORIZADO');
  end if;

  select count(*) into v_negocios from public.lugares where punto_id = v_lugar.id;
  if v_negocios > 0 then
    return jsonb_build_object('estado', 'TIENE_NEGOCIOS', 'negocios', v_negocios);
  end if;

  select count(*) into v_sellos from public.visitas where lugar_id = v_lugar.id;
  if v_sellos > 0 then
    return jsonb_build_object('estado', 'TIENE_SELLOS', 'sellos', v_sellos);
  end if;

  select count(*) into v_eventos from public.eventos where lugar_id = v_lugar.id;

  if not p_confirmar then
    return jsonb_build_object('estado', 'SE_PUEDE', 'eventos', v_eventos);
  end if;

  delete from public.lugares where id = v_lugar.id;

  -- Si un comerciante borró su único negocio, vuelve a ser "usuario" (así en
  -- el Pasaporte le aparece otra vez "Soy un negocio"). El admin no cambia.
  if not v_admin and not exists (
    select 1 from public.lugares where dueno_id = auth.uid() and es_comercio
  ) then
    update public.perfiles set rol = 'usuario' where id = auth.uid() and rol = 'comerciante';
  end if;

  return jsonb_build_object('estado', 'OK', 'eventos', v_eventos);
end;
$$;

-- ---------------------------------------------------------------------
-- ocultar_mi_negocio: si el negocio YA tiene sellos, el comerciante no lo
-- puede eliminar, pero sí ocultarlo (queda suspendido; solo el admin lo
-- reactiva). Los turistas conservan sus sellos.
-- ---------------------------------------------------------------------
create function public.ocultar_mi_negocio()
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
  set estado_aprobacion = 'suspendido', publicado = false, participa_pasaporte = false
  where dueno_id = auth.uid() and es_comercio and estado_aprobacion in ('pendiente', 'aprobado');
  if not found then
    return jsonb_build_object('estado', 'SIN_NEGOCIO');
  end if;
  return jsonb_build_object('estado', 'OK');
end;
$$;

revoke execute on function public.eliminar_lugar(uuid, boolean) from public, anon;
revoke execute on function public.ocultar_mi_negocio() from public, anon;
grant execute on function public.eliminar_lugar(uuid, boolean) to authenticated;
grant execute on function public.ocultar_mi_negocio() to authenticated;
