-- =====================================================================
-- VeraGo · 002 · Reglas de seguridad (RLS)
-- Qué es RLS: reglas dentro de PostgreSQL que deciden qué filas puede
-- ver o cambiar cada usuario. Es el "guardia" de cada tabla.
-- Regla de oro: TODA tabla lleva "enable row level security".
-- Sin una regla (policy) que lo permita, la operación se rechaza.
-- =====================================================================

-- ¿El usuario que hace la consulta es administrador?
-- "security definer" permite leer perfiles sin chocar con las reglas de perfiles.
create function public.es_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.perfiles
    where id = auth.uid() and rol = 'admin'
  );
$$;

-- ---------------------------------------------------------------------
-- perfiles: cada quien ve el suyo; el admin ve todos.
-- Solo se puede cambiar el "nombre"; el "rol" lo cambia un admin
-- desde el panel de Supabase (no desde la app).
-- ---------------------------------------------------------------------
alter table public.perfiles enable row level security;

create policy "ver mi perfil"
on public.perfiles for select
using (id = auth.uid() or public.es_admin());

create policy "editar mi perfil"
on public.perfiles for update
using (id = auth.uid())
with check (id = auth.uid());

-- RLS controla FILAS, no columnas. Para que nadie se cambie el rol,
-- quitamos el permiso de editar y solo damos permiso sobre "nombre".
revoke update on public.perfiles from authenticated, anon;
grant update (nombre) on public.perfiles to authenticated;

-- ---------------------------------------------------------------------
-- categorias: todos las leen; solo el admin las cambia (desde Supabase).
-- ---------------------------------------------------------------------
alter table public.categorias enable row level security;

create policy "todos ven categorias"
on public.categorias for select
using (true);

-- ---------------------------------------------------------------------
-- lugares: todos ven los publicados; el dueño ve el suyo aunque no esté
-- publicado; el admin ve y edita todo.
-- ---------------------------------------------------------------------
alter table public.lugares enable row level security;

create policy "todos ven lugares publicados"
on public.lugares for select
using (publicado or dueno_id = auth.uid() or public.es_admin());

create policy "admin administra lugares"
on public.lugares for all
using (public.es_admin())
with check (public.es_admin());

-- ---------------------------------------------------------------------
-- horarios: todos los leen; solo el admin los cambia.
-- ---------------------------------------------------------------------
alter table public.horarios enable row level security;

create policy "todos ven horarios"
on public.horarios for select
using (true);

create policy "admin administra horarios"
on public.horarios for all
using (public.es_admin())
with check (public.es_admin());

-- ---------------------------------------------------------------------
-- eventos: todos ven los publicados y los cancelados (para avisar);
-- los pendientes solo los ve el admin. Solo el admin los administra.
-- ---------------------------------------------------------------------
alter table public.eventos enable row level security;

create policy "todos ven eventos publicados"
on public.eventos for select
using (estado in ('publicado', 'cancelado') or public.es_admin());

create policy "admin administra eventos"
on public.eventos for all
using (public.es_admin())
with check (public.es_admin());

-- ---------------------------------------------------------------------
-- codigos_qr: RLS activado y SIN reglas → nadie la lee ni escribe
-- directo. Solo la usan las funciones del archivo 003.
-- ---------------------------------------------------------------------
alter table public.codigos_qr enable row level security;

-- ---------------------------------------------------------------------
-- visitas (sellos): cada usuario ve solo los suyos.
-- NO hay regla de insert: la única forma de crear un sello es la
-- función registrar_visita (archivo 003), que valida el QR.
-- ---------------------------------------------------------------------
alter table public.visitas enable row level security;

create policy "ver mis sellos"
on public.visitas for select
using (usuario_id = auth.uid() or public.es_admin());
