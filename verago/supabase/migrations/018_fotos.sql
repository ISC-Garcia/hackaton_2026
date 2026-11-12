-- =====================================================================
-- VeraGo · 018 · Fotos de los lugares (Supabase Storage)
--
-- Decisión del equipo (cambia la decisión inicial de "sin fotos"):
--   - 1 foto principal por lugar, guardada en la columna lugares.foto_url
--     (ya existía desde el archivo 001).
--   - El ADMIN puede poner o quitar la foto de cualquier lugar.
--   - El COMERCIANTE solo la de su propio negocio. Se publica directo; si no
--     corresponde, se reporta y el admin la quita.
--
-- Qué es Supabase Storage: el "disco" de archivos de Supabase. Los archivos
-- viven en "buckets" (carpetas principales). Aquí: el bucket "fotos-lugares",
-- PÚBLICO para leer (cualquiera ve la foto con su URL), pero solo se puede
-- SUBIR o BORRAR según las reglas de abajo.
--
-- Cada foto se guarda como:  fotos-lugares/<id del lugar>/<nombre>.jpg
-- La primera carpeta (el id del lugar) es la que revisan las reglas.
-- =====================================================================

-- 1. El bucket: público, máximo 2 MB por foto, solo imágenes.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('fotos-lugares', 'fotos-lugares', true, 2097152, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

-- 2. ¿Esta persona puede cambiar las fotos de la carpeta <id del lugar>?
--    Admin: cualquier carpeta. Comerciante: solo la de su negocio.
create function public.puede_editar_foto(p_carpeta text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.es_admin()
      or exists (
        select 1 from public.lugares
        where id::text = p_carpeta and dueno_id = auth.uid() and es_comercio
      );
$$;

grant execute on function public.puede_editar_foto(text) to authenticated;

-- 3. Reglas RLS del bucket (storage.objects es la tabla de archivos).
--    storage.foldername(name) parte la ruta en carpetas; [1] = id del lugar.
create policy "fotos de lugares: ver"
on storage.objects for select
using (bucket_id = 'fotos-lugares');

create policy "fotos de lugares: subir"
on storage.objects for insert to authenticated
with check (bucket_id = 'fotos-lugares' and public.puede_editar_foto((storage.foldername(name))[1]));

create policy "fotos de lugares: cambiar"
on storage.objects for update to authenticated
using (bucket_id = 'fotos-lugares' and public.puede_editar_foto((storage.foldername(name))[1]))
with check (bucket_id = 'fotos-lugares' and public.puede_editar_foto((storage.foldername(name))[1]));

create policy "fotos de lugares: borrar"
on storage.objects for delete to authenticated
using (bucket_id = 'fotos-lugares' and public.puede_editar_foto((storage.foldername(name))[1]));

-- 4. guardar_mi_foto: el COMERCIANTE guarda (o quita, con null) la URL de la
--    foto de su negocio. Solo acepta fotos de SU carpeta del bucket.
--    (El admin escribe foto_url directo, con el permiso del archivo 011.)
create function public.guardar_mi_foto(p_url text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_url text := nullif(trim(coalesce(p_url, '')), '');
begin
  if auth.uid() is null then
    return jsonb_build_object('estado', 'NECESITA_SESION');
  end if;

  update public.lugares
  set foto_url = v_url
  where dueno_id = auth.uid() and es_comercio
    and estado_aprobacion in ('pendiente', 'aprobado')
    and (v_url is null or v_url like '%/storage/v1/object/public/fotos-lugares/' || id::text || '/%');

  if not found then
    return jsonb_build_object('estado', 'NO_PERMITIDO');
  end if;
  return jsonb_build_object('estado', 'OK');
end;
$$;

revoke execute on function public.guardar_mi_foto(text) from public, anon;
grant execute on function public.guardar_mi_foto(text) to authenticated;
