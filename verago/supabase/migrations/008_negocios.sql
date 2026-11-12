-- =====================================================================
-- VeraGo · 008 · Negocios: registro de comerciantes y Puntos VeraGo
--
-- Modelo (decidido por el equipo):
-- - Comercio FORMAL: tiene local propio; marca su ubicación en un mapa.
-- - Comercio INFORMAL: renta un espacio en un PUNTO VERAGO (lugar bonito,
--   ej. Parque Zamora). Solo puede haber UN negocio por GIRO en cada punto.
-- - Todo negocio nuevo queda "pendiente" hasta que el admin lo aprueba.
-- - Los pagos se acuerdan fuera de la app.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Categoría nueva para los puntos
-- ---------------------------------------------------------------------
insert into public.categorias (id, clave, nombre)
values (8, 'punto', 'Puntos VeraGo')
on conflict (id) do nothing;

-- ---------------------------------------------------------------------
-- 2. Giros: lista fija de tipos de negocio informal.
--    categoria_id = en qué categoría aparece el negocio en el mapa.
-- ---------------------------------------------------------------------
create table public.giros (
  id           smallint primary key,
  clave        text not null unique,
  nombre       text not null unique,
  categoria_id smallint not null references public.categorias (id)
);

insert into public.giros (id, clave, nombre, categoria_id) values
  (1, 'guayaberas',     'Guayaberas',             5),
  (2, 'picadas',        'Picadas y antojitos',    4),
  (3, 'artesanias',     'Artesanías',             5),
  (4, 'cafe',           'Café',                   3),
  (5, 'dulces',         'Dulces típicos',         3),
  (6, 'mariscos',       'Cócteles y mariscos',    4),
  (7, 'recuerdos',      'Recuerdos de Veracruz',  5),
  (8, 'nieves',         'Nieves y paletas',       3);

-- ---------------------------------------------------------------------
-- 3. Columnas nuevas en lugares
-- ---------------------------------------------------------------------
alter table public.lugares
  -- Estado de la solicitud del negocio. Los lugares que ya existían quedan
  -- como "aprobado".
  add column estado_aprobacion text not null default 'aprobado'
    check (estado_aprobacion in ('pendiente', 'aprobado', 'rechazado', 'suspendido')),
  -- true = este lugar es un Punto VeraGo (espacio rentado a informales).
  add column es_punto boolean not null default false,
  -- Si el negocio es informal: en qué punto está y cuál es su giro.
  add column punto_id uuid references public.lugares (id) on delete set null,
  add column giro_id smallint references public.giros (id);

-- Un informal debe tener punto y giro juntos (o ninguno de los dos).
alter table public.lugares
  add constraint punto_y_giro_juntos check ((punto_id is null) = (giro_id is null));

-- UN NEGOCIO POR GIRO EN CADA PUNTO (solo cuentan pendientes y aprobados;
-- si uno es rechazado, el lugar se libera).
create unique index un_giro_por_punto
  on public.lugares (punto_id, giro_id)
  where punto_id is not null and estado_aprobacion in ('pendiente', 'aprobado');

-- Un mismo nombre comercial no se puede registrar dos veces.
create unique index nombre_comercial_unico
  on public.lugares (lower(nombre))
  where es_comercio and estado_aprobacion in ('pendiente', 'aprobado');

-- ---------------------------------------------------------------------
-- 4. Seguridad de giros
-- ---------------------------------------------------------------------
alter table public.giros enable row level security;
create policy "todos ven giros" on public.giros for select using (true);
grant select on public.giros to anon, authenticated;

-- ---------------------------------------------------------------------
-- 5. giros_ocupados: qué giros ya están tomados en un punto.
--    La usa el formulario de registro para desactivarlos.
--    security definer: puede ver solicitudes pendientes (que RLS oculta)
--    pero SOLO devuelve números de giro, ningún dato personal.
-- ---------------------------------------------------------------------
create function public.giros_ocupados(p_punto uuid)
returns setof smallint
language sql
stable
security definer
set search_path = ''
as $$
  select giro_id from public.lugares
  where punto_id = p_punto
    and estado_aprobacion in ('pendiente', 'aprobado');
$$;

grant execute on function public.giros_ocupados(uuid) to anon, authenticated;

-- ---------------------------------------------------------------------
-- 6. registrar_negocio: crea el negocio PENDIENTE del usuario con sesión,
--    lo liga a su dueño y le da el rol "comerciante".
--    Lo hace la base de datos porque nadie puede darse un rol a sí mismo
--    desde la app.
-- ---------------------------------------------------------------------
create function public.registrar_negocio(
  p_formal       boolean,
  p_nombre       text,
  p_descripcion  text,
  p_telefono     text,
  p_categoria_id smallint,  -- formal
  p_direccion    text,      -- formal
  p_latitud      double precision,  -- formal
  p_longitud     double precision,  -- formal
  p_punto_id     uuid,      -- informal
  p_giro_id      smallint   -- informal
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id        uuid;
  v_categoria smallint;
  v_lat       double precision;
  v_lng       double precision;
  v_dir       text;
  v_punto     public.lugares;
begin
  if auth.uid() is null then
    return jsonb_build_object('estado', 'NECESITA_SESION');
  end if;

  -- Una cuenta = un negocio.
  if exists (select 1 from public.lugares
             where dueno_id = auth.uid() and es_comercio
               and estado_aprobacion in ('pendiente', 'aprobado')) then
    return jsonb_build_object('estado', 'YA_TIENE_NEGOCIO');
  end if;

  if coalesce(length(trim(p_nombre)), 0) < 2 then
    return jsonb_build_object('estado', 'DATOS_INVALIDOS');
  end if;

  -- Nombre comercial repetido.
  if exists (select 1 from public.lugares
             where es_comercio and lower(nombre) = lower(trim(p_nombre))
               and estado_aprobacion in ('pendiente', 'aprobado')) then
    return jsonb_build_object('estado', 'NOMBRE_DUPLICADO');
  end if;

  if p_formal then
    -- Formal: categoría de comercio y ubicación dentro del centro de Veracruz
    -- (un rectángulo amplio alrededor del Centro Histórico).
    if p_categoria_id not in (3, 4, 5, 7)
       or p_latitud is null or p_longitud is null
       or p_latitud not between 19.15 and 19.25
       or p_longitud not between -96.20 and -96.10 then
      return jsonb_build_object('estado', 'DATOS_INVALIDOS');
    end if;
    v_categoria := p_categoria_id;
    v_lat := p_latitud;
    v_lng := p_longitud;
    v_dir := p_direccion;
  else
    -- Informal: el punto debe existir y el giro estar libre en ese punto.
    select * into v_punto from public.lugares
    where id = p_punto_id and es_punto and publicado;
    if v_punto.id is null or p_giro_id is null then
      return jsonb_build_object('estado', 'DATOS_INVALIDOS');
    end if;
    if exists (select 1 from public.lugares
               where punto_id = p_punto_id and giro_id = p_giro_id
                 and estado_aprobacion in ('pendiente', 'aprobado')) then
      return jsonb_build_object('estado', 'GIRO_OCUPADO');
    end if;
    select categoria_id into v_categoria from public.giros where id = p_giro_id;
    v_lat := v_punto.latitud;   -- el negocio está en el punto
    v_lng := v_punto.longitud;
    v_dir := 'Punto VeraGo ' || v_punto.nombre;
  end if;

  insert into public.lugares (
    nombre, descripcion, telefono, direccion, categoria_id,
    latitud, longitud, es_comercio, es_demo, dueno_id,
    participa_pasaporte, publicado, estado_aprobacion,
    punto_id, giro_id, duracion_visita_min
  ) values (
    trim(p_nombre), nullif(trim(p_descripcion), ''), nullif(trim(p_telefono), ''),
    v_dir, v_categoria, v_lat, v_lng, true, false, auth.uid(),
    false, false, 'pendiente',
    case when p_formal then null else p_punto_id end,
    case when p_formal then null else p_giro_id end,
    case when p_formal then 30 else 15 end
  )
  returning id into v_id;

  -- Informal: hereda el horario del punto (el admin lo puede cambiar).
  if not p_formal then
    insert into public.horarios (lugar_id, dia_semana, abre, cierra)
    select v_id, dia_semana, abre, cierra
    from public.horarios where lugar_id = p_punto_id;
  end if;

  -- Rol comerciante (el admin conserva su rol).
  update public.perfiles set rol = 'comerciante'
  where id = auth.uid() and rol = 'usuario';

  return jsonb_build_object('estado', 'OK', 'lugar_id', v_id);
exception
  -- Si dos personas registran lo mismo al mismo tiempo, la regla UNIQUE
  -- detiene a la segunda. Revisamos qué regla fue.
  when unique_violation then
    get stacked diagnostics v_dir = constraint_name;
    return jsonb_build_object(
      'estado', case when v_dir = 'un_giro_por_punto' then 'GIRO_OCUPADO' else 'NOMBRE_DUPLICADO' end);
end;
$$;

-- ---------------------------------------------------------------------
-- 7. actualizar_mi_negocio: el comerciante edita descripción, teléfono y
--    dirección de SU negocio (no el nombre, ni el estado, ni el rol).
-- ---------------------------------------------------------------------
create function public.actualizar_mi_negocio(
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
      telefono    = nullif(trim(p_telefono), ''),
      -- La dirección de un informal es la de su punto: no se cambia.
      direccion   = case when punto_id is null then nullif(trim(p_direccion), '') else direccion end
  where dueno_id = auth.uid() and es_comercio
    and estado_aprobacion in ('pendiente', 'aprobado');

  if not found then
    return jsonb_build_object('estado', 'SIN_NEGOCIO');
  end if;
  return jsonb_build_object('estado', 'OK');
end;
$$;

-- ---------------------------------------------------------------------
-- 8. guardar_mi_horario: el comerciante FORMAL reemplaza su horario.
--    p_horario = [{"dia":1,"abre":"09:00","cierra":"18:00"}, ...]
--    Los informales siguen el horario que asigna el admin.
-- ---------------------------------------------------------------------
create function public.guardar_mi_horario(p_horario jsonb)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_lugar uuid;
begin
  if auth.uid() is null then
    return jsonb_build_object('estado', 'NECESITA_SESION');
  end if;

  select id into v_lugar from public.lugares
  where dueno_id = auth.uid() and es_comercio and punto_id is null
    and estado_aprobacion in ('pendiente', 'aprobado');
  if v_lugar is null then
    return jsonb_build_object('estado', 'SIN_NEGOCIO_FORMAL');
  end if;

  delete from public.horarios where lugar_id = v_lugar;
  insert into public.horarios (lugar_id, dia_semana, abre, cierra)
  select v_lugar, (h ->> 'dia')::smallint, (h ->> 'abre')::time, (h ->> 'cierra')::time
  from jsonb_array_elements(p_horario) as h;

  return jsonb_build_object('estado', 'OK');
exception
  -- Hora de cierre antes de apertura, día repetido, formato inválido…
  when others then
    return jsonb_build_object('estado', 'HORARIO_INVALIDO');
end;
$$;

-- Solo usuarios con sesión pueden registrar o editar negocios.
revoke execute on function public.registrar_negocio(boolean, text, text, text, smallint, text, double precision, double precision, uuid, smallint) from public, anon;
revoke execute on function public.actualizar_mi_negocio(text, text, text) from public, anon;
revoke execute on function public.guardar_mi_horario(jsonb) from public, anon;
grant execute on function public.registrar_negocio(boolean, text, text, text, smallint, text, double precision, double precision, uuid, smallint) to authenticated;
grant execute on function public.actualizar_mi_negocio(text, text, text) to authenticated;
grant execute on function public.guardar_mi_horario(jsonb) to authenticated;

-- ---------------------------------------------------------------------
-- 9. Datos de demostración: un Punto VeraGo y dos comerciantes informales
--    FICTICIOS. Parque Zamora es un lugar real; sus coordenadas son
--    APROXIMADAS (verificar en OpenStreetMap). El horario es FICTICIO.
-- ---------------------------------------------------------------------
insert into public.lugares
  (nombre, descripcion, categoria_id, latitud, longitud, interes, duracion_visita_min,
   es_punto, es_demo, publicado)
values
  ('Punto VeraGo Parque Zamora',
   'Espacio de demostración con mesas de emprendedores locales en el Parque Zamora.',
   8, 19.1928, -96.1378, 4, 30, true, true, true);

insert into public.horarios (lugar_id, dia_semana, abre, cierra)
select l.id, d.dia, time '16:00', time '21:00'
from public.lugares l cross join generate_series(0, 6) as d(dia)
where l.es_punto and l.es_demo;

insert into public.lugares
  (nombre, descripcion, categoria_id, latitud, longitud, interes, duracion_visita_min,
   es_comercio, es_demo, participa_pasaporte, publicado, punto_id, giro_id, direccion)
select x.nombre, x.descripcion, g.categoria_id, p.latitud, p.longitud, 4, 15,
       true, true, true, true, p.id, g.id, 'Punto VeraGo Parque Zamora'
from (values
  ('Guayaberas Brisa Jarocha', 'Negocio ficticio de demostración. Guayaberas bordadas.', 'guayaberas'),
  ('Picadas Don Malecón', 'Negocio ficticio de demostración. Picadas y gordas.', 'picadas')
) as x(nombre, descripcion, giro)
join public.giros g on g.clave = x.giro
cross join (select * from public.lugares where es_punto and es_demo limit 1) p;

insert into public.horarios (lugar_id, dia_semana, abre, cierra)
select c.id, h.dia_semana, h.abre, h.cierra
from public.lugares c
join public.horarios h on h.lugar_id = c.punto_id
where c.punto_id is not null and c.es_demo;
