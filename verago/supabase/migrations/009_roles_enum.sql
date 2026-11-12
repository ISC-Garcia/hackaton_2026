-- =====================================================================
-- VeraGo · 009 · Roles como lista cerrada (ENUM)
--
-- Qué es un ENUM: un tipo de dato de PostgreSQL con una lista FIJA de
-- valores. La columna solo acepta esos valores.
-- Por qué: antes "rol" era texto con una regla CHECK (ya rechazaba
-- valores inválidos), pero en el Table Editor de Supabase se escribía a
-- mano. Con ENUM, Supabase muestra un MENÚ DESPLEGABLE con los roles que
-- existen: usuario, comerciante y admin. Imposible escribir otro.
--
-- Si algún día se necesita un rol nuevo:
--   alter type public.rol_usuario add value 'nuevo_rol';
-- =====================================================================

create type public.rol_usuario as enum ('usuario', 'comerciante', 'admin');

-- La regla CHECK anterior ya no hace falta (el ENUM hace lo mismo).
alter table public.perfiles drop constraint if exists perfiles_rol_check;

-- Cambiar el tipo de la columna: primero se quita el valor por defecto
-- (era texto), se convierte cada valor y se vuelve a poner el defecto.
alter table public.perfiles alter column rol drop default;
alter table public.perfiles
  alter column rol type public.rol_usuario using rol::public.rol_usuario;
alter table public.perfiles alter column rol set default 'usuario';
