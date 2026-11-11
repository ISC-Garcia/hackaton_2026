-- =====================================================================
-- VeraGo · 004 · Datos de demostración
--
-- LUGARES PÚBLICOS: nombres reales del Centro Histórico, con una
--   descripción general. NO se cargan horarios, teléfonos ni precios.
--   Las coordenadas son APROXIMADAS: verifíquenlas en
--   https://www.openstreetmap.org antes de la demo.
-- COMERCIOS Y EVENTOS: 100 % ficticios (es_demo = true). La app los
--   marca como "Ficticio · demostración". No representan negocios reales.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Categorías
-- ---------------------------------------------------------------------
insert into public.categorias (id, clave, nombre) values
  (1, 'historia',    'Historia y monumentos'),
  (2, 'museo',       'Museos'),
  (3, 'cafeteria',   'Cafeterías'),
  (4, 'restaurante', 'Restaurantes'),
  (5, 'tienda',      'Tiendas y artesanías'),
  (6, 'plaza',       'Plazas y paseos'),
  (7, 'cultura',     'Cultura');

-- ---------------------------------------------------------------------
-- Lugares públicos reales (sin horarios inventados)
-- ---------------------------------------------------------------------
insert into public.lugares
  (nombre, descripcion, categoria_id, latitud, longitud, interes, duracion_visita_min, publicado)
values
  ('Zócalo de Veracruz',
   'Plaza central del Centro Histórico, punto de encuentro de visitantes y familias.',
   6, 19.1996, -96.1342, 5, 30, true),
  ('Portales de Lerdo',
   'Corredor de portales frente al Zócalo, conocido por su ambiente y su oferta de cafés y restaurantes.',
   6, 19.1993, -96.1336, 5, 30, true),
  ('Catedral de Veracruz',
   'Templo principal de la ciudad, frente al Zócalo.',
   1, 19.1989, -96.1346, 4, 20, true),
  ('Palacio Municipal de Veracruz',
   'Edificio histórico ubicado en el Zócalo.',
   1, 19.1999, -96.1340, 4, 15, true),
  ('Malecón de Veracruz',
   'Paseo junto al puerto para caminar y ver la actividad del mar.',
   6, 19.2003, -96.1322, 5, 40, true),
  ('Faro Venustiano Carranza',
   'Edificio histórico cercano al Malecón.',
   1, 19.2016, -96.1336, 4, 20, true),
  ('Museo Naval México',
   'Museo dedicado a la historia naval de México.',
   2, 19.1966, -96.1328, 4, 60, true),
  ('Museo de la Ciudad de Veracruz',
   'Museo sobre la historia de la ciudad y el puerto.',
   2, 19.1952, -96.1350, 4, 45, true),
  ('Baluarte de Santiago',
   'Fortificación colonial que formó parte de la antigua muralla de la ciudad.',
   1, 19.1956, -96.1316, 4, 30, true),
  ('San Juan de Ulúa',
   'Fortaleza en el puerto. Experiencia complementaria: está fuera del recorrido a pie del centro y requiere transporte.',
   1, 19.2097, -96.1330, 5, 90, true);

-- San Juan de Ulúa no se recorre a pie desde el centro.
update public.lugares set en_recorrido_a_pie = false where nombre = 'San Juan de Ulúa';

-- ---------------------------------------------------------------------
-- Comercios FICTICIOS (dan sellos en el pasaporte)
-- ---------------------------------------------------------------------
insert into public.lugares
  (nombre, descripcion, categoria_id, latitud, longitud, interes, duracion_visita_min,
   es_comercio, es_demo, participa_pasaporte, publicado)
values
  ('Café Brisa del Golfo',
   'Cafetería ficticia de demostración. Café de altura y pan dulce.',
   3, 19.1985, -96.1338, 4, 30, true, true, true, true),
  ('Cocina La Marea',
   'Restaurante ficticio de demostración. Cocina veracruzana y mariscos.',
   4, 19.1980, -96.1352, 4, 60, true, true, true, true),
  ('Taller de Artesanías Arrecife',
   'Tienda ficticia de demostración. Artesanías y recuerdos hechos a mano.',
   5, 19.2005, -96.1352, 3, 20, true, true, true, true),
  ('Nevería Ola Fresca',
   'Nevería ficticia de demostración. Nieves y paletas de frutas tropicales.',
   3, 19.2008, -96.1329, 3, 15, true, true, true, true),
  ('Librería-Café Papel y Puerto',
   'Librería-café ficticia de demostración. Libros sobre Veracruz y lecturas en voz alta.',
   7, 19.1975, -96.1340, 3, 30, true, true, true, true),
  ('Antojitos Doña Arena',
   'Fonda ficticia de demostración. Antojitos y desayunos jarochos.',
   4, 19.1990, -96.1360, 4, 45, true, true, true, true);

-- Horarios FICTICIOS solo para los comercios de demostración:
-- todos los días de 08:00 a 21:00.
insert into public.horarios (lugar_id, dia_semana, abre, cierra)
select l.id, d.dia, time '08:00', time '21:00'
from public.lugares l
cross join generate_series(0, 6) as d(dia)
where l.es_demo;

-- ---------------------------------------------------------------------
-- Eventos FICTICIOS. Las fechas se calculan desde el momento en que se
-- corre este archivo; si pasan, vuelvan a correr solo este bloque.
-- ---------------------------------------------------------------------
insert into public.eventos (titulo, descripcion, lugar_id, inicia, termina, estado, es_gratuito, es_demo)
select 'Noche de son jarocho',
       'Evento ficticio de demostración: música tradicional en la plaza.',
       id, now() + interval '4 hours', now() + interval '6 hours', 'publicado', true, true
from public.lugares where nombre = 'Zócalo de Veracruz'
union all
select 'Exposición de fotografía del puerto',
       'Evento ficticio de demostración: fotografías antiguas y actuales del puerto.',
       id, now() + interval '1 day', now() + interval '4 days', 'publicado', true, true
from public.lugares where nombre = 'Librería-Café Papel y Puerto'
union all
select 'Lectura de leyendas veracruzanas',
       'Evento ficticio de demostración: lectura en voz alta para toda la familia.',
       id, now() + interval '2 days', now() + interval '2 days 2 hours', 'publicado', true, true
from public.lugares where nombre = 'Librería-Café Papel y Puerto'
union all
select 'Taller de pintura de recuerdos',
       'Evento ficticio de demostración: pinta tu propio recuerdo de Veracruz.',
       id, now() + interval '3 days', now() + interval '3 days 3 hours', 'publicado', false, true
from public.lugares where nombre = 'Taller de Artesanías Arrecife';
