-- =====================================================================
-- VeraGo · 001 · Tablas
-- Qué hace: crea las tablas de la base de datos (sección 12 del documento).
-- Cómo se usa: Supabase → SQL Editor → pegar todo → Run. Solo una vez.
-- =====================================================================

-- ---------------------------------------------------------------------
-- perfiles: datos de cada usuario registrado.
-- El correo y la contraseña los guarda Supabase Auth en auth.users;
-- aquí guardamos el nombre y el rol.
-- ---------------------------------------------------------------------
create table public.perfiles (
  id        uuid primary key references auth.users (id) on delete cascade,
  nombre    text not null default 'Visitante',
  rol       text not null default 'usuario'
            check (rol in ('usuario', 'comerciante', 'admin')),
  creado_en timestamptz not null default now()
);

-- Cuando alguien se registra, se crea su perfil automáticamente.
-- "trigger" = acción que la base de datos ejecuta sola cuando pasa algo.
create function public.crear_perfil()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.perfiles (id, nombre)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'nombre',
                           split_part(new.email, '@', 1)));
  return new;
end;
$$;

create trigger al_registrarse
after insert on auth.users
for each row execute function public.crear_perfil();

-- ---------------------------------------------------------------------
-- categorias: tipos de lugar. "clave" es un nombre corto que la app
-- usa para elegir el ícono y el color de cada categoría.
-- ---------------------------------------------------------------------
create table public.categorias (
  id     smallint primary key,
  clave  text not null unique,
  nombre text not null unique
);

-- ---------------------------------------------------------------------
-- lugares: tabla central. Guarda lugares públicos y comercios.
-- es_demo = true  → dato ficticio para la demostración (se muestra etiqueta).
-- es_comercio     → si es un negocio (puede tener dueño y dar sellos).
-- ---------------------------------------------------------------------
create table public.lugares (
  id                  uuid primary key default gen_random_uuid(),
  nombre              text not null,
  descripcion         text,
  categoria_id        smallint not null references public.categorias (id),
  latitud             double precision not null,
  longitud            double precision not null,
  direccion           text,
  telefono            text,
  foto_url            text,
  interes             smallint not null default 3 check (interes between 1 and 5),
  duracion_visita_min smallint not null default 30 check (duracion_visita_min between 5 and 240),
  es_comercio         boolean not null default false,
  es_demo             boolean not null default false,
  dueno_id            uuid references public.perfiles (id) on delete set null,
  participa_pasaporte boolean not null default false,
  publicado           boolean not null default false,
  creado_en           timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- horarios: una fila por lugar y día. Si un lugar no tiene filas,
-- la app muestra "Horario no disponible" (no inventamos horarios reales).
-- dia_semana: 0 = domingo ... 6 = sábado.
-- ---------------------------------------------------------------------
create table public.horarios (
  lugar_id   uuid not null references public.lugares (id) on delete cascade,
  dia_semana smallint not null check (dia_semana between 0 and 6),
  abre       time not null,
  cierra     time not null check (cierra > abre),
  primary key (lugar_id, dia_semana)
);

-- ---------------------------------------------------------------------
-- eventos: agenda cultural.
-- ---------------------------------------------------------------------
create table public.eventos (
  id          uuid primary key default gen_random_uuid(),
  titulo      text not null,
  descripcion text,
  lugar_id    uuid references public.lugares (id) on delete set null,
  inicia      timestamptz not null,
  termina     timestamptz not null,
  estado      text not null default 'pendiente'
              check (estado in ('pendiente', 'publicado', 'cancelado')),
  es_gratuito boolean not null default true,
  es_demo     boolean not null default false,
  creado_por  uuid references public.perfiles (id) on delete set null,
  check (termina > inicia)
);

-- ---------------------------------------------------------------------
-- codigos_qr: el código que cambia cada minuto en el celular del comercio.
-- ---------------------------------------------------------------------
create table public.codigos_qr (
  codigo   text primary key,
  lugar_id uuid not null references public.lugares (id) on delete cascade,
  vence_en timestamptz not null
);

-- ---------------------------------------------------------------------
-- visitas: cada fila es un SELLO del pasaporte.
-- La regla UNIQUE impide más de un sello por lugar por día.
-- ---------------------------------------------------------------------
create table public.visitas (
  id         uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references public.perfiles (id) on delete cascade,
  lugar_id   uuid not null references public.lugares (id) on delete cascade,
  fecha      date not null,
  creado_en  timestamptz not null default now(),
  unique (usuario_id, lugar_id, fecha)
);

-- Índices: aceleran las búsquedas más frecuentes.
create index visitas_usuario on public.visitas (usuario_id);
create index eventos_inicia on public.eventos (inicia);
create index lugares_categoria on public.lugares (categoria_id);
